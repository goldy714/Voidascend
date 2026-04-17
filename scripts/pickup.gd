extends Area2D

@export var metal: int = 0
@export var crystals: int = 0

var _vel: Vector2
var _target: Node2D = null
var _attracted: bool = false

func _ready() -> void:
	add_to_group("pickups")
	_vel = Vector2(randf_range(-45.0, 45.0), randf_range(-80.0, -20.0))
	var spr := Sprite2D.new()
	if crystals > 0:
		spr.texture = load("res://assets/pickups/pickup_crystal.png")
	else:
		spr.texture = load("res://assets/pickups/pickup_metal.png")
	spr.scale = Vector2(0.5, 0.5)
	add_child(spr)
	# Collision shape so body_entered fires on contact with the player
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	var cshape := CollisionShape2D.new()
	cshape.shape = shape
	add_child(cshape)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if _attracted and is_instance_valid(_target):
		var dir := (_target.global_position - global_position).normalized()
		_vel = _vel.lerp(dir * 460.0, 0.20)
	else:
		_vel.y += 65.0 * delta  # soft gravity drift

	position += _vel * delta

	if position.y > get_viewport_rect().size.y + 90.0:
		queue_free()

func attract_to(target: Node2D) -> void:
	_attracted = true
	_target = target

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if body.collect(metal, crystals):
			queue_free()
		# If player lacks cargo/collector, pickup stays and can be collected later
