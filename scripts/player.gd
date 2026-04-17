extends CharacterBody2D

signal died
signal hp_changed(current: int, maximum: int)
signal metal_changed(amount: int)
signal crystals_changed(amount: int)

const BULLET_SCENE = preload("res://scenes/bullet_player.tscn")

# ── Runtime stats (set from GameData in _ready) ─────────────────
var _stats: Dictionary = {}
var _speed: float        = 0.0
var _max_hp: int         = 100
var _pickup_range: float = 0.0
var _has_cargo: bool     = false
var _has_engine: bool    = false
var _metal_mult: float   = 1.0

# Per-weapon fire timers (one entry per equipped weapon)
var _weapon_timers: Array[float] = []

# Ship ability (Space)
var _ability_timer: float    = 0.0
var _ability_cooldown: float = 2.5

# Runtime state
var hp: int            = 100
var is_alive: bool     = true
var invincible: bool   = false
var metal_collected: int   = 0
var crystals_collected: int = 0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 1   # layer: player
	collision_mask  = 0   # player CharacterBody2D doesn't need to push anything
	var shape := CircleShape2D.new()
	shape.radius = 20.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	_apply_modules()


func _apply_modules() -> void:
	_stats = GameData.get_player_stats()
	_max_hp       = _stats["max_hp"]
	_pickup_range = _stats["pickup_range"]
	_has_cargo    = _stats["has_cargo"]
	_has_engine   = _stats.get("has_engine", false)
	_metal_mult   = _stats["metal_mult"]
	# Without an engine the ship cannot move
	_speed        = _stats["speed"] if _has_engine else 0.0

	hp = _max_hp

	# Initialize per-weapon timers (staggered so they don't all fire at once)
	_weapon_timers.resize(_stats["weapons"].size())
	for i in _weapon_timers.size():
		_weapon_timers[i] = float(i) * 0.08

	# Ship ability cooldown
	var ship: Dictionary = GameData.SHIP_DATA[GameData.current_ship]
	_ability_cooldown = ship.get("active_cooldown", 2.5)

	hp_changed.emit(hp, _max_hp)

func _draw() -> void:
	ShipDraw.draw_ship(self, GameData.current_ship, GameData.installed_modules, _aim_dir())
	# Ability cooldown arc (outside hull)
	if _ability_timer > 0.0:
		var frac: float = _ability_timer / _ability_cooldown
		draw_arc(Vector2.ZERO, 46.0, -PI / 2.0,
			-PI / 2.0 + TAU * (1.0 - frac), 40,
			Color(0.3, 0.8, 1.0, 0.65), 2.5)

func _physics_process(delta: float) -> void:
	if not is_alive:
		return
	_move(delta)
	_auto_shoot(delta)
	_handle_ability(delta)
	if _has_cargo and _pickup_range > 0:
		_attract_pickups()

# ── Movement ─────────────────────────────────────────────────────
func _move(delta: float) -> void:
	var dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):  dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT): dir.x += 1
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):    dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):  dir.y += 1
	velocity = dir.normalized() * _speed
	move_and_slide()
	var sz := get_viewport_rect().size
	global_position.x = clamp(global_position.x, 28.0, sz.x - 28.0)
	global_position.y = clamp(global_position.y, 28.0, sz.y - 28.0)

# ── Weapons ───────────────────────────────────────────────────────
func _auto_shoot(delta: float) -> void:
	var weapons: Array = _stats["weapons"]
	for i in weapons.size():
		_weapon_timers[i] -= delta
		if _weapon_timers[i] <= 0.0:
			_weapon_timers[i] = weapons[i]["rate"]
			_fire_weapon(weapons[i])

func _aim_dir() -> Vector2:
	var mouse: Vector2 = get_global_mouse_position()
	var d: Vector2 = (mouse - global_position).normalized()
	if d == Vector2.ZERO:
		return Vector2.UP
	return d

func _weapon_muzzle(w: Dictionary, aim: Vector2) -> Vector2:
	var slot: int = w.get("slot", 4)
	var g: Vector2i = GameData.SHIP_DATA.get(GameData.current_ship, {}).get("grid", Vector2i(3, 3))
	var origin: Vector2 = ShipDraw.get_grid_origin(g.x, g.y)
	var slot_pos: Vector2 = origin + Vector2(float(slot % g.x) * ShipDraw.CELL,
											 float(slot / g.x) * ShipDraw.CELL)
	var barrel: float
	match w["pattern"]:
		"ion":    barrel = 9.5
		"rocket": barrel = 8.0
		_:        barrel = 7.5
	return slot_pos + aim * barrel

func _fire_weapon(w: Dictionary) -> void:
	var aim: Vector2  = _aim_dir()
	var perp: Vector2 = Vector2(-aim.y, aim.x)
	var muz: Vector2  = _weapon_muzzle(w, aim)
	match w["pattern"]:
		"single":
			_spawn_bullet(muz, w["damage"], Color(0.30, 0.80, 1.00), aim)
		"double":
			_spawn_bullet(muz + perp *  3.2, w["damage"], Color(0.30, 0.80, 1.00), aim)
			_spawn_bullet(muz - perp *  3.2, w["damage"], Color(0.30, 0.80, 1.00), aim)
		"plasma":
			_spawn_bullet(muz, w["damage"], Color(0.80, 0.30, 1.00), aim, 2.8, 380.0)
		"ion":
			_spawn_bullet(muz, w["damage"], Color(0.20, 1.00, 0.60), aim, 4.0, 300.0)
		"spread":
			_spawn_bullet(muz + perp * -4.5, w["damage"], Color(1.00, 0.60, 0.20), aim.rotated(-0.28))
			_spawn_bullet(muz,               w["damage"], Color(1.00, 0.60, 0.20), aim)
			_spawn_bullet(muz + perp *  4.5, w["damage"], Color(1.00, 0.60, 0.20), aim.rotated(0.28))
		"minigun":
			_spawn_bullet(muz + perp * randf_range(-3.0, 3.0), w["damage"],
				Color(1.00, 0.90, 0.30), aim)
		"rocket":
			_spawn_bullet(muz + perp *  3.8, w["damage"], Color(1.00, 0.30, 0.30), aim, 1.8, 420.0, true)
			_spawn_bullet(muz - perp *  3.8, w["damage"], Color(1.00, 0.30, 0.30), aim, 1.8, 420.0, true)

func _spawn_bullet(offset: Vector2, dmg: int, clr: Color,
		dir: Vector2 = Vector2.UP, sz: float = 1.0, spd: float = 620.0,
		homing: bool = false) -> void:
	var b: Area2D = BULLET_SCENE.instantiate()
	b.global_position = global_position + offset
	b.damage       = dmg
	b.bullet_color = clr
	b.dir          = dir
	b.size_mult    = sz
	b.speed        = spd
	b.homing       = homing
	get_parent().add_child(b)

# ── Ship ability (Space) ──────────────────────────────────────────
func _handle_ability(delta: float) -> void:
	_ability_timer = max(0.0, _ability_timer - delta)
	queue_redraw()  # redraw cooldown arc

	if Input.is_key_pressed(KEY_SPACE) and _ability_timer <= 0.0:
		_ability_timer = _ability_cooldown
		_activate_ship_ability()

func _activate_ship_ability() -> void:
	match GameData.SHIP_DATA[GameData.current_ship].get("active_key", ""):
		"dash": _do_dash()
		"salvo": _do_salvo()

func _do_dash() -> void:
	var dir := velocity.normalized() if velocity.length() > 10 else Vector2(0, -1)
	invincible = true
	modulate = Color(0.5, 0.8, 1.0, 0.55)
	global_position += dir * 160.0
	var sz := get_viewport_rect().size
	global_position.x = clamp(global_position.x, 28.0, sz.x - 28.0)
	global_position.y = clamp(global_position.y, 28.0, sz.y - 28.0)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.30)
	tw.tween_callback(func() -> void: invincible = false)

func _do_salvo() -> void:
	# Fire all weapons simultaneously (Destroyer active)
	for w: Dictionary in _stats["weapons"]:
		_fire_weapon(w)

# ── Pickups ───────────────────────────────────────────────────────
func _attract_pickups() -> void:
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if is_instance_valid(pickup) and \
				global_position.distance_to(pickup.global_position) < _pickup_range:
			pickup.attract_to(self)

# ── Damage & death ────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if invincible or not is_alive:
		return
	hp = max(0, hp - amount)
	hp_changed.emit(hp, _max_hp)
	invincible = true
	modulate = Color(1.0, 0.25, 0.25)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.18)
	tw.tween_callback(func() -> void: invincible = false)
	if hp <= 0:
		_die()

## Returns true if collected, false if missing cargo or collector module.
func collect(metal: int, crystals: int) -> bool:
	if not _has_cargo or _pickup_range <= 0.0:
		return false
	metal_collected    += int(metal * _metal_mult)
	crystals_collected += crystals
	metal_changed.emit(metal_collected)
	crystals_changed.emit(crystals_collected)
	return true

func _die() -> void:
	is_alive = false
	set_physics_process(false)
	died.emit()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.55)
	tw.tween_callback(queue_free)

# ── Ability info for HUD ──────────────────────────────────────────
func get_ability_timer() -> float:
	return _ability_timer

func get_ability_cooldown() -> float:
	return _ability_cooldown
