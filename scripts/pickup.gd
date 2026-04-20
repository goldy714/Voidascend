extends Area2D

@export var metal: int = 0
@export var crystals: int = 0

var _vel: Vector2
var _claimed_by: Node2D = null
var _attract_point: Vector2 = Vector2.ZERO
var _attract_strength: float = 0.0

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
	# Collision shape (kept so legacy body-contact still works if needed)
	var shape := CircleShape2D.new()
	shape.radius = 18.0
	var cshape := CollisionShape2D.new()
	cshape.shape = shape
	add_child(cshape)

func _physics_process(delta: float) -> void:
	# When claimed by a collector arm, the arm drives position — do nothing here.
	if _claimed_by != null:
		if not is_instance_valid(_claimed_by):
			_claimed_by = null
		else:
			return

	# Passive magnetic attraction from a magnet-collector tip (one-shot point).
	if _attract_strength > 0.0:
		var dir := (_attract_point - global_position).normalized()
		_vel = _vel.lerp(dir * 220.0, _attract_strength)
		_attract_strength = 0.0  # must be re-applied each frame by the arm
	else:
		_vel.y += 65.0 * delta  # soft gravity drift

	position += _vel * delta

	if position.y > get_viewport_rect().size.y + 90.0:
		queue_free()

# ── Claim API (used by CollectorArm) ─────────────────────────────
func claim(by: Node2D) -> bool:
	if _claimed_by != null:
		return false
	_claimed_by = by
	return true

func unclaim() -> void:
	_claimed_by = null

func is_claimed() -> bool:
	return _claimed_by != null

func attract_to_point(p: Vector2, strength: float) -> void:
	_attract_point = p
	_attract_strength = strength

# Legacy: older code called attract_to(player) for magnet behavior.
func attract_to(target: Node2D) -> void:
	if is_instance_valid(target):
		attract_to_point(target.global_position, 0.20)
