extends Node2D

const STRIKE_COUNT: int = 12
const STRIKE_INTERVAL: float = 0.26
const WARNING_TIME: float = 0.34
const EXPLOSION_TIME: float = 0.32
const RADIUS: float = 96.0
const DAMAGE: int = 75
const MISS_OFFSET_MIN: float = 150.0
const MISS_OFFSET_MAX: float = 260.0

var _time_until_next: float = 0.0
var _strikes_spawned: int = 0
var _strikes: Array[Dictionary] = []

func _ready() -> void:
	z_index = 8
	set_process(true)

func _process(delta: float) -> void:
	_time_until_next -= delta
	if _strikes_spawned < STRIKE_COUNT and _time_until_next <= 0.0:
		_spawn_strike()
		_time_until_next = STRIKE_INTERVAL

	for i: int in range(_strikes.size() - 1, -1, -1):
		var strike: Dictionary = _strikes[i]
		strike["timer"] = float(strike["timer"]) - delta
		if not bool(strike["detonated"]) and float(strike["timer"]) <= 0.0:
			strike["detonated"] = true
			strike["timer"] = EXPLOSION_TIME
			var strike_position_value: Variant = strike.get("position", Vector2.ZERO)
			if strike_position_value is Vector2:
				var strike_position: Vector2 = strike_position_value
				_damage_enemies(strike_position)
		elif bool(strike["detonated"]) and float(strike["timer"]) <= 0.0:
			_strikes.remove_at(i)
			continue
		_strikes[i] = strike

	queue_redraw()
	if _strikes_spawned >= STRIKE_COUNT and _strikes.is_empty():
		queue_free()

func _draw() -> void:
	for strike: Dictionary in _strikes:
		var pos_value: Variant = strike.get("position", Vector2.ZERO)
		if not (pos_value is Vector2):
			continue
		var pos: Vector2 = pos_value
		var timer: float = float(strike["timer"])
		if bool(strike["detonated"]):
			var progress: float = clamp(1.0 - timer / EXPLOSION_TIME, 0.0, 1.0)
			var shock_radius: float = lerp(RADIUS * 0.25, RADIUS, progress)
			var alpha: float = 1.0 - progress
			draw_circle(pos, shock_radius, Color(1.0, 0.38, 0.08, 0.18 * alpha))
			draw_arc(pos, shock_radius, 0.0, TAU, 48, Color(1.0, 0.86, 0.28, 0.95 * alpha), 4.0)
			draw_circle(pos, RADIUS * 0.24 * (1.0 - progress * 0.35), Color(1.0, 0.92, 0.50, 0.85 * alpha))
			draw_line(pos + Vector2(-RADIUS * 0.42, 0.0), pos + Vector2(RADIUS * 0.42, 0.0),
				Color(1.0, 0.74, 0.20, 0.70 * alpha), 3.0)
			draw_line(pos + Vector2(0.0, -RADIUS * 0.42), pos + Vector2(0.0, RADIUS * 0.42),
				Color(1.0, 0.74, 0.20, 0.70 * alpha), 3.0)
		else:
			var warning_progress: float = clamp(1.0 - timer / WARNING_TIME, 0.0, 1.0)
			var pulse: float = 0.58 + 0.22 * sin(warning_progress * TAU * 3.0)
			draw_arc(pos, RADIUS, 0.0, TAU, 48, Color(0.25, 0.88, 1.0, pulse), 2.5)
			draw_arc(pos, RADIUS * (0.45 + warning_progress * 0.45), 0.0, TAU, 40,
				Color(1.0, 0.72, 0.22, 0.72), 2.0)
			draw_line(pos + Vector2(-RADIUS, 0.0), pos + Vector2(-RADIUS * 0.35, 0.0),
				Color(0.35, 0.92, 1.0, 0.75), 2.0)
			draw_line(pos + Vector2(RADIUS * 0.35, 0.0), pos + Vector2(RADIUS, 0.0),
				Color(0.35, 0.92, 1.0, 0.75), 2.0)
			draw_line(pos + Vector2(0.0, -RADIUS), pos + Vector2(0.0, -RADIUS * 0.35),
				Color(0.35, 0.92, 1.0, 0.75), 2.0)
			draw_line(pos + Vector2(0.0, RADIUS * 0.35), pos + Vector2(0.0, RADIUS),
				Color(0.35, 0.92, 1.0, 0.75), 2.0)

func _spawn_strike() -> void:
	var pos: Vector2 = _choose_strike_position()
	_strikes.append({
		"position": pos,
		"timer": WARNING_TIME,
		"detonated": false,
	})
	_strikes_spawned += 1

func _choose_strike_position() -> Vector2:
	var enemies: Array[Node2D] = _get_valid_enemies()
	var should_miss: bool = (_strikes_spawned + 1) % 4 == 0
	if not enemies.is_empty():
		var target: Node2D = enemies[randi() % enemies.size()]
		if should_miss:
			return _choose_miss_position(target.global_position)
		return _clamp_to_battlefield(target.global_position + Vector2(
			randf_range(-RADIUS * 0.18, RADIUS * 0.18),
			randf_range(-RADIUS * 0.18, RADIUS * 0.18)
		))
	return _random_battlefield_position()

func _get_valid_enemies() -> Array[Node2D]:
	var enemies: Array[Node2D] = []
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var enemy_2d: Node2D = enemy as Node2D
		if enemy_2d != null:
			enemies.append(enemy_2d)
	return enemies

func _choose_miss_position(target_position: Vector2) -> Vector2:
	for _attempt: int in 8:
		var miss_position: Vector2 = _clamp_to_battlefield(target_position + _random_miss_offset())
		if miss_position.distance_to(target_position) > RADIUS * 1.15:
			return miss_position
	return _random_battlefield_position()

func _random_miss_offset() -> Vector2:
	var angle: float = randf_range(0.0, TAU)
	var distance: float = randf_range(MISS_OFFSET_MIN, MISS_OFFSET_MAX)
	return Vector2.from_angle(angle) * distance

func _random_battlefield_position() -> Vector2:
	var rect: Rect2 = get_viewport_rect()
	var margin: float = RADIUS + 24.0
	return Vector2(
		randf_range(margin, rect.size.x - margin),
		randf_range(92.0 + margin, rect.size.y - margin)
	)

func _clamp_to_battlefield(position: Vector2) -> Vector2:
	var rect: Rect2 = get_viewport_rect()
	var margin: float = RADIUS + 24.0
	return Vector2(
		clamp(position.x, margin, rect.size.x - margin),
		clamp(position.y, 92.0 + margin, rect.size.y - margin)
	)

func _damage_enemies(position: Vector2) -> void:
	for enemy: Node in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if not enemy.has_method("take_damage"):
			continue
		var enemy_2d: Node2D = enemy as Node2D
		if enemy_2d == null:
			continue
		if enemy_2d.global_position.distance_to(position) <= RADIUS:
			enemy.call("take_damage", DAMAGE)
