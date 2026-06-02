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

var _hp: int
var _shoot_timer: float
var _contact_timer: float = 0.0
var _player_touching: bool = false
var _target_marked: bool = false
var _target_damage_mult: float = 1.0
var _entered_screen: bool = false
var _entry_y: float = ENTRY_Y_MIN
var _horizontal_direction: float = 1.0

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

	_horizontal_direction = -1.0 if randf() < 0.5 else 1.0
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
			global_position.y = _entry_y
	else:
		velocity = Vector2(_horizontal_direction * move_speed, 0.0)
		move_and_slide()
		if global_position.x <= EDGE_PADDING:
			global_position.x = EDGE_PADDING
			_horizontal_direction = 1.0
		elif global_position.x >= viewport_size.x - EDGE_PADDING:
			global_position.x = viewport_size.x - EDGE_PADDING
			_horizontal_direction = -1.0

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
