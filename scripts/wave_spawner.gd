extends Node

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal all_waves_completed

const ENEMY_SCENE = preload("res://scenes/enemy_basic.tscn")
const HARVESTER_SCENE = preload("res://scenes/enemy_harvester.tscn")
const PICKUP_SCENE = preload("res://scenes/pickup.tscn")

const HARVESTER_SWARM_MIN: int = 3
const HARVESTER_SWARM_MAX: int = 5
const HARVESTER_SWARM_DELAY: float = 0.72
const HARVESTER_EDGE_OFFSET: float = 78.0
const HARVESTER_EDGE_MARGIN: float = 108.0
const BASIC_ENEMY_SPAWN_DELAY: float = 0.38

@export var total_waves: int = 5

var current_wave: int = 0
var enemies_alive: int = 0
var _active: bool = true
var _spawning_wave: bool = false
var _wave_finishing: bool = false

func start_waves() -> void:
	current_wave = 0
	_next_wave()

func stop() -> void:
	_active = false

func _next_wave() -> void:
	if not _active:
		return
	_wave_finishing = false
	current_wave += 1
	if current_wave > total_waves:
		all_waves_completed.emit()
		return

	wave_started.emit(current_wave)
	await get_tree().create_timer(1.8).timeout
	if _active:
		_spawn_wave(current_wave)

func _spawn_wave(wave_num: int) -> void:
	var count: int = 6 + wave_num * 3          # 9, 12, 15, 18, 21
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	enemies_alive = 0
	_spawning_wave = true

	if GameData.current_planet == "glacius":
		await _spawn_harvester_wave(wave_num, count, viewport_size)
	else:
		await _spawn_basic_wave(wave_num, count, viewport_size.x)

	_spawning_wave = false
	if enemies_alive == 0:
		_finish_current_wave()


func _spawn_basic_wave(wave_num: int, count: int, screen_w: float) -> void:
	var rare_count: int = 1 if wave_num >= 2 else 0

	for i in range(count):
		if not _active:
			return
		await get_tree().create_timer(BASIC_ENEMY_SPAWN_DELAY).timeout

		var enemy: CharacterBody2D = ENEMY_SCENE.instantiate()
		enemy.global_position = Vector2(randf_range(40.0, screen_w - 40.0), -45.0)
		enemy.move_speed = 70.0 + wave_num * 10.0

		if i < rare_count:
			enemy.is_rare = true

		enemy.died.connect(_on_enemy_died)
		get_parent().add_child(enemy)
		enemies_alive += 1


func _spawn_harvester_wave(wave_num: int, count: int, viewport_size: Vector2) -> void:
	var remaining: int = count
	var swarm_index: int = 0
	var crystal_carrier_spawned: bool = false
	while remaining > 0:
		if not _active:
			_spawning_wave = false
			return
		var swarm_count: int = _next_swarm_size(remaining)
		var spawn_crystal_carrier: bool = wave_num >= 2 and not crystal_carrier_spawned
		_spawn_harvester_swarm(
			wave_num,
			swarm_index,
			swarm_count,
			viewport_size,
			spawn_crystal_carrier
		)
		crystal_carrier_spawned = crystal_carrier_spawned or spawn_crystal_carrier
		remaining -= swarm_count
		swarm_index += 1
		if remaining > 0:
			await get_tree().create_timer(HARVESTER_SWARM_DELAY).timeout


func _next_swarm_size(remaining: int) -> int:
	if remaining <= HARVESTER_SWARM_MAX:
		return remaining

	var max_size: int = min(HARVESTER_SWARM_MAX, remaining)
	var options: Array[int] = []
	for size in range(HARVESTER_SWARM_MIN, max_size + 1):
		var after: int = remaining - size
		if after == 0 or after >= HARVESTER_SWARM_MIN:
			options.append(size)
	if options.is_empty():
		return min(HARVESTER_SWARM_MIN, remaining)
	return options[randi() % options.size()]


func _spawn_harvester_swarm(
	wave_num: int,
	swarm_index: int,
	count: int,
	viewport_size: Vector2,
	spawn_crystal_carrier: bool
) -> void:
	var entry_center: Vector2 = _harvester_entry_center(viewport_size)
	var spawn_center: Vector2 = _harvester_spawn_center(entry_center, viewport_size)
	var swarm_id: String = "harvester_%d_%d_%d" % [wave_num, swarm_index, randi()]

	for i in range(count):
		var offset: Vector2 = _harvester_swarm_offset(i, count)
		var entry_offset: Vector2 = _harvester_entry_offset(offset, entry_center, viewport_size)
		var enemy: CharacterBody2D = HARVESTER_SCENE.instantiate()
		enemy.global_position = spawn_center + offset
		enemy.move_speed = 74.0 + wave_num * 6.0
		enemy.max_hp = 18 + wave_num * 2
		enemy.shoot_interval = max(1.45, 2.45 - float(wave_num) * 0.12)
		enemy.projectile_damage = 5 + min(wave_num, 3)
		enemy.projectile_speed = 218.0 + wave_num * 7.0
		enemy.metal_drop = 5 + wave_num
		if spawn_crystal_carrier and i == 0:
			enemy.max_hp = int(enemy.max_hp * 1.8)
			enemy.metal_drop *= 2
			enemy.crystal_drop = randi_range(2, 4)
			enemy.sprite_modulate = Color(0.72, 0.95, 1.0)
		enemy.call("configure_swarm", swarm_id, offset, entry_center, entry_center + entry_offset)
		enemy.died.connect(_on_enemy_died)
		get_parent().add_child(enemy)
		enemies_alive += 1


func _harvester_entry_center(viewport_size: Vector2) -> Vector2:
	var min_x: float = min(HARVESTER_EDGE_MARGIN, viewport_size.x * 0.5)
	var max_x: float = max(min_x, viewport_size.x - HARVESTER_EDGE_MARGIN)
	var min_y: float = min(HARVESTER_EDGE_MARGIN, viewport_size.y * 0.5)
	var max_y: float = max(min_y, viewport_size.y - HARVESTER_EDGE_MARGIN)
	var side: int = randi() % 4
	match side:
		0:
			return Vector2(randf_range(min_x, max_x), 0.0)
		1:
			return Vector2(viewport_size.x, randf_range(min_y, max_y))
		2:
			return Vector2(randf_range(min_x, max_x), viewport_size.y)
		_:
			return Vector2(0.0, randf_range(min_y, max_y))


func _harvester_spawn_center(entry_center: Vector2, viewport_size: Vector2) -> Vector2:
	if is_zero_approx(entry_center.y):
		return entry_center + Vector2(0.0, -HARVESTER_EDGE_OFFSET)
	if is_equal_approx(entry_center.x, viewport_size.x):
		return entry_center + Vector2(HARVESTER_EDGE_OFFSET, 0.0)
	if is_equal_approx(entry_center.y, viewport_size.y):
		return entry_center + Vector2(0.0, HARVESTER_EDGE_OFFSET)
	return entry_center + Vector2(-HARVESTER_EDGE_OFFSET, 0.0)


func _harvester_entry_offset(offset: Vector2, entry_center: Vector2, viewport_size: Vector2) -> Vector2:
	if is_zero_approx(entry_center.y) or is_equal_approx(entry_center.y, viewport_size.y):
		return Vector2(offset.x, 0.0)
	return Vector2(0.0, offset.y)


func _harvester_swarm_offset(index: int, count: int) -> Vector2:
	var angle: float = TAU * (float(index) / float(max(1, count))) + randf_range(-0.18, 0.18)
	var radius: float = 38.0 + float(index % 2) * 18.0
	return Vector2(cos(angle) * radius, sin(angle) * radius * 0.62)


func _on_enemy_died(pos: Vector2, metal: int, crystals: int) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	_spawn_pickups(pos, metal, crystals)

	if enemies_alive == 0:
		_finish_current_wave()


func _finish_current_wave() -> void:
	if _spawning_wave or _wave_finishing or not _active:
		return
	_wave_finishing = true
	wave_completed.emit(current_wave)
	await get_tree().create_timer(2.2).timeout
	_next_wave()

func _spawn_pickups(pos: Vector2, metal: int, crystals: int) -> void:
	if metal > 0:
		var p: Area2D = PICKUP_SCENE.instantiate()
		p.global_position = pos
		p.metal = metal
		get_parent().call_deferred("add_child", p)

	if crystals > 0:
		var p: Area2D = PICKUP_SCENE.instantiate()
		p.global_position = pos + Vector2(16.0, 0.0)
		p.crystals = crystals
		get_parent().call_deferred("add_child", p)
