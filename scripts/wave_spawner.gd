extends Node

signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal all_waves_completed

const ENEMY_SCENE  = preload("res://scenes/enemy_basic.tscn")
const PICKUP_SCENE = preload("res://scenes/pickup.tscn")

@export var total_waves: int = 5

var current_wave: int = 0
var enemies_alive: int = 0
var _active: bool = true

func start_waves() -> void:
	current_wave = 0
	_next_wave()

func stop() -> void:
	_active = false

func _next_wave() -> void:
	if not _active:
		return
	current_wave += 1
	if current_wave > total_waves:
		all_waves_completed.emit()
		return

	wave_started.emit(current_wave)
	await get_tree().create_timer(1.8).timeout
	if _active:
		_spawn_wave(current_wave)

func _spawn_wave(wave_num: int) -> void:
	var count: int    = 4 + wave_num * 2          # 6, 8, 10, 12, 14
	var rare_count: int = 1 if wave_num >= 2 else 0
	var screen_w: float = get_viewport().get_visible_rect().size.x
	enemies_alive = 0

	for i in range(count):
		if not _active:
			return
		await get_tree().create_timer(0.38).timeout

		var enemy: CharacterBody2D = ENEMY_SCENE.instantiate()
		enemy.global_position = Vector2(randf_range(40.0, screen_w - 40.0), -45.0)
		enemy.move_speed = 70.0 + wave_num * 10.0

		if i < rare_count:
			enemy.is_rare = true

		enemy.died.connect(_on_enemy_died)
		get_parent().add_child(enemy)
		enemies_alive += 1

func _on_enemy_died(pos: Vector2, metal: int, crystals: int) -> void:
	enemies_alive = max(0, enemies_alive - 1)
	_spawn_pickups(pos, metal, crystals)

	if enemies_alive == 0:
		wave_completed.emit(current_wave)
		await get_tree().create_timer(2.2).timeout
		_next_wave()

func _spawn_pickups(pos: Vector2, metal: int, crystals: int) -> void:
	if metal > 0:
		var p: Area2D = PICKUP_SCENE.instantiate()
		p.global_position = pos
		p.metal = metal
		get_parent().add_child(p)

	if crystals > 0:
		var p: Area2D = PICKUP_SCENE.instantiate()
		p.global_position = pos + Vector2(16.0, 0.0)
		p.crystals = crystals
		get_parent().add_child(p)
