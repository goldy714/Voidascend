class_name ShrapnelBurst
extends Node2D

var radius: float = 240.0
var ray_count: int = 16
var max_delay: float = 0.18

var _age: float = 0.0
var _life: float = 0.52
var _rays: Array[Dictionary] = []


func setup(origin: Vector2, burst_radius: float, rays: int, delay_max: float) -> void:
	global_position = origin
	radius = burst_radius
	ray_count = rays
	max_delay = delay_max
	_life = max_delay + 0.34
	_build_rays()


func _ready() -> void:
	z_as_relative = false
	z_index = 100
	set_process(true)


func _process(delta: float) -> void:
	_age += delta
	if _age >= _life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var flash_alpha: float = clamp(1.0 - (_age / 0.12), 0.0, 1.0)
	if flash_alpha > 0.0:
		draw_circle(Vector2.ZERO, 18.0 * (1.0 - flash_alpha) + 8.0,
			Color(1.0, 0.36, 0.07, 0.60 * flash_alpha))
		draw_circle(Vector2.ZERO, 5.0, Color(1.0, 0.86, 0.34, 0.78 * flash_alpha))

	for ray: Dictionary in _rays:
		var delay: float = float(ray["delay"])
		if _age < delay:
			continue
		var t: float = clamp((_age - delay) / float(ray["life"]), 0.0, 1.0)
		var alpha: float = sin(t * PI) * float(ray["alpha"])
		var dir: Vector2 = ray.get("dir", Vector2.RIGHT)
		var length: float = float(ray["length"])
		var start: Vector2 = dir * length * 0.10 * t
		var end: Vector2 = dir * length * (0.30 + 0.70 * t)
		draw_line(start, end, Color(1.0, float(ray["green"]), float(ray["blue"]), alpha), float(ray["width"]))


func _build_rays() -> void:
	_rays.clear()
	for i: int in ray_count:
		var angle: float = TAU * (float(i) + randf_range(-0.38, 0.38)) / float(ray_count)
		_rays.append({
			"dir": Vector2.RIGHT.rotated(angle),
			"length": radius * randf_range(0.35, 1.0),
			"width": randf_range(1.2, 2.8),
			"delay": randf_range(0.0, max_delay),
			"life": randf_range(0.16, 0.28),
			"alpha": randf_range(0.62, 0.92),
			"green": randf_range(0.52, 0.82),
			"blue": randf_range(0.08, 0.24),
		})
