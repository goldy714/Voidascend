extends CharacterBody2D

signal died(position: Vector2, metal: int, crystals: int)

@export var move_speed: float = 80.0
@export var max_hp: int = 30
@export var shoot_interval: float = 2.5
@export var metal_drop: int = 10
@export var crystal_drop: int = 0
@export var is_rare: bool = false

const BULLET_SCENE = preload("res://scenes/bullet_enemy.tscn")

const CONTACT_DAMAGE: int   = 20
const CONTACT_INTERVAL: float = 0.8
const ENTRY_Y_MIN: float = 160.0
const ENTRY_Y_MAX: float = 240.0
const EDGE_PADDING: float = 34.0
const BATTLEFIELD_TOP_PADDING: float = 90.0
const BATTLEFIELD_BOTTOM_PADDING: float = 86.0
const WANDER_TARGET_DISTANCE: float = 26.0
const WANDER_RETARGET_MIN: float = 1.0
const WANDER_RETARGET_MAX: float = 2.4
const WANDER_SPEED_MIN: float = 0.72
const WANDER_SPEED_MAX: float = 1.12

var _hp: int
var _shoot_timer: float
var _contact_timer: float = 0.0
var _player_touching: bool = false
var _target_marked: bool = false
var _target_damage_mult: float = 1.0
var _entered_screen: bool = false
var _entry_y: float = ENTRY_Y_MIN
var _wander_target: Vector2 = Vector2.ZERO
var _wander_timer: float = 0.0
var _wander_speed_mult: float = 1.0

func _ready() -> void:
	_hp = max_hp
	_shoot_timer = randf_range(0.6, shoot_interval)
	add_to_group("enemies")

	if is_rare:
		crystal_drop = randi_range(2, 4)
		metal_drop = int(metal_drop * 2.0)
		_hp = max_hp * 2

	# CharacterBody2D collision (enemy layer)
	collision_layer = 2
	collision_mask  = 0
	var body_shape := CircleShape2D.new()
	body_shape.radius = 22.0
	var body_cs := CollisionShape2D.new()
	body_cs.shape = body_shape
	add_child(body_cs)

	# Contact damage Area2D — detects player body
	var contact_area := Area2D.new()
	contact_area.collision_layer = 0
	contact_area.collision_mask  = 1   # player layer
	var area_shape := CircleShape2D.new()
	area_shape.radius = 22.0
	var area_cs := CollisionShape2D.new()
	area_cs.shape = area_shape
	contact_area.add_child(area_cs)
	contact_area.body_entered.connect(_on_contact_body_entered)
	contact_area.body_exited.connect(_on_contact_body_exited)
	add_child(contact_area)

	_entry_y = randf_range(ENTRY_Y_MIN, ENTRY_Y_MAX)
	_setup_sprite()

func _setup_sprite() -> void:
	var spr := Sprite2D.new()
	if is_rare:
		spr.texture = load("res://assets/enemies/enemy_rare.png")
	else:
		spr.texture = load("res://assets/enemies/enemy_basic.png")
	spr.scale = Vector2(0.38, 0.38)
	add_child(spr)

func _physics_process(delta: float) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size

	if not _entered_screen:
		velocity = Vector2(0.0, move_speed)
		move_and_slide()
		if global_position.y >= _entry_y:
			_entered_screen = true
			global_position = _clamp_to_battlefield(
				Vector2(global_position.x, _entry_y),
				viewport_size
			)
			_choose_wander_target(viewport_size)
	else:
		_wander_timer -= delta
		if _should_choose_new_wander_target():
			_choose_wander_target(viewport_size)

		var target_delta: Vector2 = _wander_target - global_position
		if target_delta.length() > 1.0:
			velocity = target_delta.normalized() * move_speed * _wander_speed_mult
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		global_position = _clamp_to_battlefield(global_position, viewport_size)

	if _target_marked:
		queue_redraw()

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = shoot_interval
		_fire()

	# Contact damage: hurt player every CONTACT_INTERVAL while overlapping
	if _player_touching:
		_contact_timer -= delta
		if _contact_timer <= 0.0:
			_contact_timer = CONTACT_INTERVAL
			var player := get_tree().get_first_node_in_group("player")
			if is_instance_valid(player):
				player.take_damage(CONTACT_DAMAGE)

func _should_choose_new_wander_target() -> bool:
	return _wander_timer <= 0.0 \
		or _wander_target == Vector2.ZERO \
		or global_position.distance_to(_wander_target) <= WANDER_TARGET_DISTANCE

func _choose_wander_target(viewport_size: Vector2) -> void:
	var bounds: Rect2 = _battlefield_bounds(viewport_size)
	_wander_target = Vector2(
		randf_range(bounds.position.x, bounds.end.x),
		randf_range(bounds.position.y, bounds.end.y)
	)
	_wander_timer = randf_range(WANDER_RETARGET_MIN, WANDER_RETARGET_MAX)
	_wander_speed_mult = randf_range(WANDER_SPEED_MIN, WANDER_SPEED_MAX)

func _battlefield_bounds(viewport_size: Vector2) -> Rect2:
	var left: float = EDGE_PADDING
	var right: float = max(left, viewport_size.x - EDGE_PADDING)
	var top: float = BATTLEFIELD_TOP_PADDING
	var bottom: float = max(top, viewport_size.y - BATTLEFIELD_BOTTOM_PADDING)
	return Rect2(
		Vector2(left, top),
		Vector2(max(1.0, right - left), max(1.0, bottom - top))
	)

func _clamp_to_battlefield(pos: Vector2, viewport_size: Vector2) -> Vector2:
	var bounds: Rect2 = _battlefield_bounds(viewport_size)
	return Vector2(
		clampf(pos.x, bounds.position.x, bounds.end.x),
		clampf(pos.y, bounds.position.y, bounds.end.y)
	)

func _fire() -> void:
	var target: Node2D = _choose_attack_target()
	if not is_instance_valid(target):
		return
	var bullet: Node2D = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = (target.global_position - global_position).normalized()
	get_parent().add_child(bullet)

func _choose_attack_target() -> Node2D:
	var decoys: Array = get_tree().get_nodes_in_group("enemy_decoys")
	if not decoys.is_empty():
		var decoy_value: Variant = decoys[randi() % decoys.size()]
		if decoy_value is Node2D and is_instance_valid(decoy_value):
			var decoy: Node2D = decoy_value
			return decoy
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D and is_instance_valid(player):
		var player_2d: Node2D = player
		return player_2d
	return null

func _on_contact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_touching = true
		_contact_timer = 0.0   # deal damage immediately on touch

func _on_contact_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_touching = false

func _draw() -> void:
	if not _target_marked:
		return
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008)
	var col := Color(1.0, 0.28, 0.18, 0.72 + 0.22 * pulse)
	draw_arc(Vector2.ZERO, 29.0 + 3.0 * pulse, 0.0, TAU, 40, col, 2.4)
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 32, Color(1.0, 0.78, 0.24, 0.50), 1.4)
	draw_line(Vector2(-36.0, 0.0), Vector2(-22.0, 0.0), col, 2.0)
	draw_line(Vector2(22.0, 0.0), Vector2(36.0, 0.0), col, 2.0)
	draw_line(Vector2(0.0, -36.0), Vector2(0.0, -22.0), col, 2.0)
	draw_line(Vector2(0.0, 22.0), Vector2(0.0, 36.0), col, 2.0)

func set_target_marker(damage_mult: float) -> void:
	_target_marked = true
	_target_damage_mult = max(1.0, damage_mult)
	queue_redraw()

func clear_target_marker() -> void:
	_target_marked = false
	_target_damage_mult = 1.0
	queue_redraw()

func take_damage(amount: int) -> void:
	_hp -= int(ceil(float(amount) * _target_damage_mult))
	modulate = Color(1.0, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	if _hp <= 0:
		_die()

func _die() -> void:
	remove_from_group("enemies")
	died.emit(global_position, metal_drop, crystal_drop)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)
