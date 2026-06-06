extends Node2D

const ShipDraw = preload("res://scripts/ship_draw.gd")

var ship_id: String = "scout"
var installed_modules: Array[String] = []
var lifetime: float = 5.0

var _age: float = 0.0

func setup(source_ship_id: String, source_modules: Array[String], active_lifetime: float) -> void:
	ship_id = source_ship_id
	installed_modules = source_modules.duplicate()
	lifetime = active_lifetime

func _ready() -> void:
	add_to_group("enemy_decoys")
	z_index = 2
	modulate = Color(0.42, 0.82, 1.0, 0.66)
	set_process(true)

func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()

func _draw() -> void:
	var fade: float = clamp(1.0 - _age / lifetime, 0.0, 1.0)
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008)
	draw_circle(Vector2.ZERO, 62.0 + pulse * 5.0, Color(0.20, 0.72, 1.0, 0.10 * fade))
	draw_arc(Vector2.ZERO, 62.0, 0.0, TAU, 48, Color(0.42, 0.86, 1.0, 0.45 * fade), 2.0)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	ShipDraw.draw_ship(self, ship_id, installed_modules, Vector2.UP, true)
	draw_line(Vector2(-46.0, -52.0), Vector2(46.0, 52.0), Color(0.75, 0.95, 1.0, 0.20 * fade), 1.4)
	draw_line(Vector2(46.0, -52.0), Vector2(-46.0, 52.0), Color(0.75, 0.95, 1.0, 0.16 * fade), 1.2)
