extends Area2D

var damage: int         = 20
var speed: float        = 620.0
var bullet_color: Color = Color(0.30, 0.80, 1.00)
var size_mult: float    = 1.0
var dir: Vector2        = Vector2.UP

# Homing
var homing: bool             = false
var homing_strength: float   = 4.2   # max turn speed (rad/s)
var _arm_timer: float        = 0.14  # brief delay before steering kicks in

# Exhaust trail (homing only)
var _trail: Array[Vector2]   = []
const TRAIL_LEN: int         = 14


func _ready() -> void:
	collision_layer = 4
	collision_mask  = 2
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	rotation = dir.angle() + PI / 2.0

	var spr := Sprite2D.new()
	spr.texture = load("res://assets/bullets/bullet_player.png")
	spr.modulate = bullet_color
	spr.scale = Vector2(size_mult, size_mult)
	add_child(spr)


func _physics_process(delta: float) -> void:
	if homing:
		_arm_timer -= delta
		if _arm_timer <= 0.0:
			var target := _nearest_enemy()
			if is_instance_valid(target):
				var desired: Vector2 = (target.global_position - global_position).normalized()
				var turn: float = clamp(dir.angle_to(desired),
					-homing_strength * delta, homing_strength * delta)
				dir = dir.rotated(turn).normalized()
				rotation = dir.angle() + PI / 2.0

		# Record trail in global coords
		_trail.append(global_position)
		if _trail.size() > TRAIL_LEN:
			_trail.pop_front()
		queue_redraw()

	position += dir * speed * delta

	var sz := get_viewport_rect().size
	if position.y < -90.0 or position.y > sz.y + 90.0 \
			or position.x < -90.0 or position.x > sz.x + 90.0:
		queue_free()


func _draw() -> void:
	if not homing or _trail.size() < 2:
		return
	# Exhaust trail — convert global trail points to local space
	for i: int in _trail.size():
		var lp: Vector2 = to_local(_trail[i])
		var frac: float = float(i + 1) / float(_trail.size())  # 0→1, newest=1
		var alpha: float = frac * 0.60
		var radius: float = size_mult * lerp(0.6, 3.2, 1.0 - frac)
		# Orange-yellow core fading to red
		var col: Color = Color(1.0, lerp(0.20, 0.72, frac), 0.0, alpha)
		draw_circle(lp, radius, col)


func _nearest_enemy() -> Node2D:
	var best: Node2D  = null
	var best_d: float = INF
	for e: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(e):
			continue
		var d: float = global_position.distance_to((e as Node2D).global_position)
		if d < best_d:
			best_d = d
			best   = e as Node2D
	return best


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		body.take_damage(damage)
		queue_free()
