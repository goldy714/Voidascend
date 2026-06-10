extends Area2D

const ShrapnelBurstScript = preload("res://scripts/shrapnel_burst.gd")
const ProjectileExplosionScript = preload("res://scripts/projectile_explosion.gd")

var damage: int         = 20
var speed: float        = 620.0
var bullet_color: Color = Color(0.30, 0.80, 1.00)
var size_mult: float    = 1.0
var dir: Vector2        = Vector2.UP
var source_player: Node2D = null
var duplicated_slots: Array[int] = []

# Homing
var homing: bool             = false
var homing_strength: float   = 4.2   # max turn speed (rad/s)
var _arm_timer: float        = 0.14  # brief delay before steering kicks in

# Explosive rockets
var explosive: bool = false
const SHRAPNEL_RADIUS: float = 240.0
const SHRAPNEL_DAMAGE: int = 8
const SHRAPNEL_HIT_CHANCE: float = 0.35
const SHRAPNEL_RAYS: int = 16
const SHRAPNEL_MAX_DELAY: float = 0.18

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
	if not body_entered.is_connected(_on_body_entered):
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

	var previous_global_position: Vector2 = global_position
	position += dir * speed * delta
	_check_projectile_duplicators(previous_global_position, global_position)

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
		_spawn_impact_explosion()
		if explosive:
			_emit_shrapnel(body)
		queue_free()


func _spawn_impact_explosion() -> void:
	var parent: Node = get_parent()
	if parent == null:
		return
	var explosion: Node2D = ProjectileExplosionScript.new()
	explosion.call("setup", global_position, _impact_explosion_size())
	parent.add_child(explosion)


func _impact_explosion_size() -> String:
	if explosive or size_mult >= 2.6:
		return "large"
	if homing or size_mult >= 1.5:
		return "medium"
	return "small"


func _emit_shrapnel(primary_target: Node2D) -> void:
	var hit_origin: Vector2 = global_position
	_spawn_shrapnel_burst(hit_origin)
	for node: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(node) or node == primary_target:
			continue
		if not (node is Node2D):
			continue
		var enemy: Node2D = node as Node2D
		if enemy.global_position.distance_to(hit_origin) > SHRAPNEL_RADIUS:
			continue
		if randf() <= SHRAPNEL_HIT_CHANCE and enemy.has_method("take_damage"):
			enemy.call("take_damage", SHRAPNEL_DAMAGE)


func _spawn_shrapnel_burst(hit_origin: Vector2) -> void:
	var burst: Node2D = ShrapnelBurstScript.new()
	get_parent().add_child(burst)
	burst.call("setup", hit_origin, SHRAPNEL_RADIUS, SHRAPNEL_RAYS, SHRAPNEL_MAX_DELAY)


func _check_projectile_duplicators(from_pos: Vector2, to_pos: Vector2) -> void:
	if source_player == null or not is_instance_valid(source_player):
		return
	if not source_player.has_method("get_projectile_duplicators"):
		return
	var duplicators_value: Variant = source_player.call("get_projectile_duplicators")
	if not (duplicators_value is Array):
		return
	for duplicator_value: Variant in duplicators_value:
		if not (duplicator_value is Dictionary):
			continue
		var duplicator: Dictionary = duplicator_value
		var slot: int = int(duplicator.get("slot", -1))
		if slot < 0 or slot in duplicated_slots:
			continue
		var center_value: Variant = duplicator.get("global", Vector2.ZERO)
		var center: Vector2 = center_value if center_value is Vector2 else Vector2.ZERO
		var radius: float = float(duplicator.get("radius", 14.0))
		if _distance_to_segment(center, from_pos, to_pos) <= radius:
			duplicated_slots.append(slot)
			if source_player.has_method("duplicate_projectile_from"):
				source_player.call("duplicate_projectile_from", self, slot)


func _distance_to_segment(point: Vector2, segment_start: Vector2, segment_end: Vector2) -> float:
	var segment: Vector2 = segment_end - segment_start
	var length_sq: float = segment.length_squared()
	if length_sq <= 0.001:
		return point.distance_to(segment_start)
	var t: float = clamp((point - segment_start).dot(segment) / length_sq, 0.0, 1.0)
	return point.distance_to(segment_start + segment * t)
