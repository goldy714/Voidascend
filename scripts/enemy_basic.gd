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

var _hp: int
var _shoot_timer: float
var _contact_timer: float = 0.0
var _player_touching: bool = false

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
	velocity = Vector2(0.0, move_speed)
	move_and_slide()

	if global_position.y > get_viewport_rect().size.y + 60.0:
		queue_free()
		return

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
	var player := get_tree().get_first_node_in_group("player")
	if not is_instance_valid(player):
		return
	var bullet: Node2D = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = (player.global_position - global_position).normalized()
	get_parent().add_child(bullet)

func _on_contact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_touching = true
		_contact_timer = 0.0   # deal damage immediately on touch

func _on_contact_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_touching = false

func take_damage(amount: int) -> void:
	_hp -= amount
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
