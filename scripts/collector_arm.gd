class_name CollectorArm extends Node2D

enum State { IDLE, REACHING, GRABBING, RETRACTING }

# Configured from player at spawn
var arm_type: String = "telescope"  # "telescope", "ik", or "shuttle"
var reach: float = 90.0
var attract_radius: float = 0.0  # magnet-tip passive attraction (0 = off)
var player: Node2D = null

# Runtime state
var state: int = State.IDLE
var tip_local: Vector2 = Vector2(0.0, -6.0)  # relative to arm base
var target: Node2D = null
var _elbow_sign: float = 1.0  # IK elbow side
var _rest_tip: Vector2 = Vector2(0.0, -6.0)
var _shuttle_route_start: Vector2 = Vector2.ZERO
var _shuttle_route_control: Vector2 = Vector2.ZERO
var _shuttle_route_end: Vector2 = Vector2.ZERO
var _shuttle_route_progress: float = 0.0
var _shuttle_route_distance: float = 1.0
var _shuttle_route_active: bool = false

const EXTEND_SPEED:  float = 520.0
const RETRACT_SPEED: float = 720.0
const MOVEMENT_SPEED_MULT: float = 0.5
const GRAB_DIST:     float = 10.0
const RETRACT_DONE:  float = 3.5


func _ready() -> void:
	z_index = 8  # above ship hull
	set_physics_process(true)
	_elbow_sign = 1.0 if randf() < 0.5 else -1.0
	# IK rest pose is moderately extended so the elbow doesn't splay sideways.
	if arm_type == "ik":
		_rest_tip = Vector2(0.0, -reach * 0.18)
	elif arm_type == "shuttle":
		_rest_tip = Vector2(0.0, -10.0)
	else:
		_rest_tip = Vector2(0.0, -8.0)
	tip_local = _rest_tip
	if arm_type == "shuttle":
		_shuttle_route_start = _rest_tip
		_shuttle_route_control = _rest_tip + Vector2(0.0, -8.0)
		_shuttle_route_end = _rest_tip
		_shuttle_route_active = false


func _physics_process(delta: float) -> void:
	match state:
		State.IDLE:       _tick_idle(delta)
		State.REACHING:   _tick_reaching(delta)
		State.GRABBING:   _tick_grabbing(delta)
		State.RETRACTING: _tick_retracting(delta)
	queue_redraw()


# ── State handlers ───────────────────────────────────────────────

func _tick_idle(delta: float) -> void:
	tip_local = tip_local.lerp(_rest_tip, 0.22)
	if arm_type == "shuttle":
		_shuttle_route_active = false
	if attract_radius > 0.0:
		_magnet_pulse()
	var p := _find_pickup()
	if p != null and p.has_method("claim") and p.claim(self):
		target = p
		if arm_type == "shuttle":
			_begin_shuttle_route(tip_local, target.global_position - global_position)
		state = State.REACHING


func _tick_reaching(delta: float) -> void:
	if not _target_valid():
		target = null
		if arm_type == "shuttle":
			_begin_shuttle_route(tip_local, _rest_tip)
		state = State.RETRACTING
		return
	var goal: Vector2 = target.global_position - global_position
	if goal.length() > reach * 1.05:
		# Pickup drifted out of reach — let it go.
		if target.has_method("unclaim"):
			target.unclaim()
		target = null
		if arm_type == "shuttle":
			_begin_shuttle_route(tip_local, _rest_tip)
		state = State.RETRACTING
		return
	if arm_type == "shuttle":
		_tick_shuttle_route(delta, goal, EXTEND_SPEED)
		if attract_radius > 0.0:
			_magnet_pulse()
		var tip_world_shuttle: Vector2 = global_position + tip_local
		if tip_world_shuttle.distance_to(target.global_position) <= GRAB_DIST:
			state = State.GRABBING
		return
	var speed: float = _travel_speed(EXTEND_SPEED)
	tip_local = tip_local.move_toward(goal, speed * delta)
	if attract_radius > 0.0:
		_magnet_pulse()
	var tip_world: Vector2 = global_position + tip_local
	if tip_world.distance_to(target.global_position) <= GRAB_DIST:
		state = State.GRABBING


func _tick_grabbing(_delta: float) -> void:
	if not _target_valid():
		target = null
		state = State.RETRACTING
		return
	target.global_position = global_position + tip_local
	if arm_type == "shuttle":
		_begin_shuttle_route(tip_local, _rest_tip)
	# Instant transition — "grabbed" is just a one-frame latch moment.
	state = State.RETRACTING


func _tick_retracting(delta: float) -> void:
	if arm_type == "shuttle":
		_tick_shuttle_route(delta, _rest_tip, RETRACT_SPEED)
		if _target_valid():
			target.global_position = global_position + tip_local
		if tip_local.distance_to(_rest_tip) <= RETRACT_DONE:
			_shuttle_route_active = false
			_deliver_target()
			state = State.IDLE
		return
	var speed: float = _travel_speed(RETRACT_SPEED)
	tip_local = tip_local.move_toward(_rest_tip, speed * delta)
	if _target_valid():
		target.global_position = global_position + tip_local
	if tip_local.distance_to(_rest_tip) <= RETRACT_DONE:
		_deliver_target()
		state = State.IDLE


# ── Helpers ──────────────────────────────────────────────────────

func _target_valid() -> bool:
	return target != null and is_instance_valid(target)


func _find_pickup() -> Node2D:
	var best: Node2D = null
	var best_d: float = reach + 1.0
	var scan_origin: Vector2 = _pickup_scan_origin()
	for n in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(n):
			continue
		if n.has_method("is_claimed") and n.is_claimed():
			continue
		var d: float = scan_origin.distance_to(n.global_position)
		if d <= reach and d < best_d:
			best = n
			best_d = d
	return best


func _pickup_scan_origin() -> Vector2:
	if arm_type == "shuttle" and player != null and is_instance_valid(player):
		return player.global_position
	return global_position


func _deliver_target() -> void:
	if not _target_valid():
		return
	var m: int = int(target.get("metal"))
	var c: int = int(target.get("crystals"))
	var collected := false
	if player != null and is_instance_valid(player) and player.has_method("collect"):
		collected = player.collect(m, c)
	if collected:
		target.queue_free()
	else:
		if target.has_method("unclaim"):
			target.unclaim()
	target = null


func _magnet_pulse() -> void:
	# Pulls nearby unclaimed pickups toward the arm tip.
	var tip_world: Vector2 = global_position + tip_local
	for n in get_tree().get_nodes_in_group("pickups"):
		if not is_instance_valid(n):
			continue
		if n.has_method("is_claimed") and n.is_claimed():
			continue
		var d: float = tip_world.distance_to(n.global_position)
		if d < attract_radius and n.has_method("attract_to_point"):
			n.attract_to_point(tip_world, 0.08)


func _travel_speed(default_speed: float) -> float:
	var speed: float = default_speed * MOVEMENT_SPEED_MULT
	if arm_type == "shuttle":
		return speed * 0.82
	return speed


func _begin_shuttle_route(from: Vector2, to: Vector2) -> void:
	_shuttle_route_start = from
	_shuttle_route_end = to
	_shuttle_route_distance = max(1.0, from.distance_to(to))
	_shuttle_route_progress = 0.0
	_shuttle_route_active = true

	var chord: Vector2 = to - from
	var dir: Vector2 = chord.normalized() if chord.length() > 0.1 else Vector2(0.0, -1.0)
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var side: float = 1.0 if randf() < 0.5 else -1.0
	var arc: float = clamp(_shuttle_route_distance * randf_range(0.18, 0.32), 14.0, 54.0)
	var forward_bias: float = randf_range(-0.08, 0.12)
	_shuttle_route_control = from.lerp(to, 0.50 + forward_bias) + perp * arc * side


func _tick_shuttle_route(delta: float, current_end: Vector2, default_speed: float) -> void:
	if not _shuttle_route_active:
		_begin_shuttle_route(tip_local, current_end)
	_shuttle_route_end = current_end
	_shuttle_route_distance = max(1.0, _shuttle_route_start.distance_to(_shuttle_route_end))
	var speed: float = _travel_speed(default_speed)
	_shuttle_route_progress = min(1.0, _shuttle_route_progress + (speed * delta / _shuttle_route_distance))
	var t: float = _ease_shuttle(_shuttle_route_progress)
	tip_local = _quadratic_bezier(_shuttle_route_start, _shuttle_route_control, _shuttle_route_end, t)


func _ease_shuttle(t: float) -> float:
	t = clamp(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _quadratic_bezier(a: Vector2, b: Vector2, c: Vector2, t: float) -> Vector2:
	var ab: Vector2 = a.lerp(b, t)
	var bc: Vector2 = b.lerp(c, t)
	return ab.lerp(bc, t)


# ── Drawing ──────────────────────────────────────────────────────

func _draw() -> void:
	match arm_type:
		"ik":
			_draw_ik()
		"shuttle":
			_draw_shuttle()
		_:
			_draw_telescope()


func _draw_telescope() -> void:
	var col := Color(0.92, 0.72, 0.18)
	var col_dark := Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 0.88)
	var base := Vector2.ZERO
	var tip: Vector2 = tip_local
	var diff: Vector2 = tip - base
	var length: float = diff.length()
	var norm: Vector2 = diff / length if length > 0.5 else Vector2(0.0, -1.0)
	var perp: Vector2 = Vector2(-norm.y, norm.x)

	# Mount base (socket)
	draw_circle(base, 3.8, Color(0.30, 0.24, 0.08, 0.95))
	draw_arc(base, 3.8, 0.0, TAU, 14, col, 1.4)

	# Tube: wide at base, narrower at tip
	var w_base: float = 4.2
	var w_tip:  float = 2.6
	var pts := PackedVector2Array([
		base + perp * w_base,
		tip  + perp * w_tip,
		tip  - perp * w_tip,
		base - perp * w_base,
	])
	draw_polygon(pts, PackedColorArray([col_dark]))
	var outline := PackedVector2Array(pts)
	outline.append(pts[0])
	draw_polyline(outline, col, 1.2)

	# Telescope ring marks along the tube
	var segs: int = max(1, int(length / 7.0))
	for i in range(1, segs):
		var t: float = float(i) / float(segs)
		var p: Vector2 = base.lerp(tip, t)
		var w: float = lerp(w_base, w_tip, t) * 0.85
		draw_line(p + perp * w, p - perp * w,
			Color(col.r, col.g, col.b, 0.30), 0.6)

	# Claw at tip: opens while reaching, closes when carrying
	var open: float = 0.2
	if state == State.REACHING:
		open = 1.0
	elif state == State.GRABBING:
		open = 0.4
	elif state == State.RETRACTING:
		open = 0.15
	var claw_len: float = 4.2
	var ang: float = lerp(0.20, 1.15, open)
	draw_line(tip, tip + norm.rotated(ang) * claw_len, col, 1.8)
	draw_line(tip, tip + norm.rotated(-ang) * claw_len, col, 1.8)


func _draw_ik() -> void:
	var col_arm   := Color(0.85, 0.72, 0.22)
	var col_shade := Color(col_arm.r * 0.42, col_arm.g * 0.42, col_arm.b * 0.42, 0.88)
	var col_joint := Color(0.95, 0.85, 0.35)
	var base := Vector2.ZERO
	var tgt: Vector2 = tip_local

	var L1: float = reach * 0.55
	var L2: float = reach * 0.55
	var d: float = tgt.length()
	d = clamp(d, 0.8, (L1 + L2) - 0.5)
	var cos_a: float = clamp((L1 * L1 + d * d - L2 * L2) / (2.0 * L1 * d), -1.0, 1.0)
	var a: float = acos(cos_a)
	var target_angle: float = atan2(tgt.y, tgt.x) if tgt.length() > 0.05 else -PI * 0.5
	var shoulder_angle: float = target_angle - a * _elbow_sign
	var elbow: Vector2 = base + Vector2(cos(shoulder_angle), sin(shoulder_angle)) * L1
	var tip: Vector2 = tgt

	# Upper arm (thicker with shaded inside)
	draw_line(base, elbow, col_shade, 4.2)
	draw_line(base, elbow, col_arm, 2.4)
	# Forearm
	draw_line(elbow, tip, col_shade, 3.6)
	draw_line(elbow, tip, col_arm, 2.0)

	# Shoulder + elbow joints
	draw_circle(base, 3.4, col_joint)
	draw_circle(base, 1.4, Color(0.10, 0.08, 0.02))
	draw_circle(elbow, 2.9, col_joint)
	draw_circle(elbow, 1.2, Color(0.10, 0.08, 0.02))

	# Magnetic tip: red/blue horseshoe pointing along forearm direction
	var fore: Vector2 = tip - elbow
	var fore_len: float = fore.length()
	var norm: Vector2 = fore / fore_len if fore_len > 0.1 else Vector2(0.0, -1.0)
	var perp: Vector2 = Vector2(-norm.y, norm.x)
	var c_red  := Color(0.95, 0.22, 0.22)
	var c_blue := Color(0.22, 0.32, 1.00)
	# Two prongs extending forward from tip
	draw_line(tip + perp * 3.0, tip + perp * 3.0 + norm * 4.0, c_red,  2.4)
	draw_line(tip - perp * 3.0, tip - perp * 3.0 + norm * 4.0, c_blue, 2.4)
	# Horseshoe body (arc behind prongs)
	var back_angle: float = atan2(-norm.y, -norm.x)
	draw_arc(tip, 3.0, back_angle - PI * 0.5, back_angle + PI * 0.5, 14,
		Color(0.82, 0.82, 0.92), 2.2)
	# Tip glow when reaching/grabbing
	if state == State.REACHING or state == State.GRABBING:
		draw_circle(tip + norm * 2.5, 2.4,
			Color(1.00, 0.95, 0.50, 0.40))


func _draw_shuttle() -> void:
	var base := Vector2.ZERO
	var tip: Vector2 = tip_local
	var diff: Vector2 = tip - base
	var dir: Vector2 = _shuttle_facing_dir(diff)
	var perp: Vector2 = Vector2(-dir.y, dir.x)
	var body := Color(0.34, 0.82, 1.00)
	var trim := Color(0.95, 0.82, 0.28)
	var dark := Color(0.04, 0.08, 0.15, 0.92)

	draw_circle(base, 4.0, Color(0.08, 0.10, 0.16, 0.90))
	draw_arc(base, 4.2, 0.0, TAU, 16, Color(0.46, 0.72, 0.92, 0.76), 1.1)
	if state != State.IDLE:
		draw_line(base, tip, Color(0.28, 0.72, 1.00, 0.18), 1.2)

	var nose: Vector2 = tip + dir * 7.0
	var tail: Vector2 = tip - dir * 6.0
	var left: Vector2 = tip + perp * 4.8 - dir * 1.0
	var right: Vector2 = tip - perp * 4.8 - dir * 1.0
	var hull := PackedVector2Array([nose, left, tail, right])
	_draw_shuttle_polygon(hull, dark, body)

	var wing_l := PackedVector2Array([
		tip + perp * 4.0 - dir * 0.5,
		tip + perp * 8.0 - dir * 4.6,
		tip + perp * 2.5 - dir * 4.0,
	])
	var wing_r := PackedVector2Array([
		tip - perp * 4.0 - dir * 0.5,
		tip - perp * 2.5 - dir * 4.0,
		tip - perp * 8.0 - dir * 4.6,
	])
	_draw_shuttle_polygon(wing_l, Color(0.05, 0.12, 0.20, 0.88), body)
	_draw_shuttle_polygon(wing_r, Color(0.05, 0.12, 0.20, 0.88), body)

	draw_circle(tip + dir * 1.7, 2.0, Color(0.86, 0.97, 1.00, 0.86))
	draw_line(tail + perp * 1.8, tail - dir * 5.0, Color(0.25, 0.85, 1.00, 0.62), 1.8)
	draw_line(tail - perp * 1.8, tail - dir * 5.0, Color(0.25, 0.85, 1.00, 0.62), 1.8)

	if _target_valid() and state == State.RETRACTING:
		draw_line(tip + perp * 2.8, tip + perp * 5.2 + dir * 3.0, trim, 1.4)
		draw_line(tip - perp * 2.8, tip - perp * 5.2 + dir * 3.0, trim, 1.4)
	elif state == State.REACHING:
		draw_arc(tip + dir * 4.0, 5.2, -PI * 0.2, PI * 1.2, 18,
			Color(0.95, 0.82, 0.28, 0.32), 1.0)


func _draw_shuttle_polygon(points: PackedVector2Array, fill: Color, outline: Color) -> void:
	draw_polygon(points, PackedColorArray([fill]))
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, outline, 1.1)


func _shuttle_facing_dir(fallback: Vector2) -> Vector2:
	if _shuttle_route_active:
		var t: float = _ease_shuttle(_shuttle_route_progress)
		var tangent: Vector2 = (_shuttle_route_control - _shuttle_route_start) * (2.0 * (1.0 - t))
		tangent += (_shuttle_route_end - _shuttle_route_control) * (2.0 * t)
		if tangent.length() > 0.1:
			return tangent.normalized()
	if fallback.length() > 0.5:
		return fallback.normalized()
	return Vector2(0.0, -1.0)
