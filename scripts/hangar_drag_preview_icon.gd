extends Control

const ShipDraw = preload("res://scripts/ship_draw.gd")

var module_id: String = ""
var icon_scale: float = 2.35

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if module_id.is_empty():
		return
	draw_set_transform(size * 0.5, 0.0, Vector2(icon_scale, icon_scale))
	ShipDraw.draw_module_icon(self, module_id)
	draw_set_transform(Vector2.ZERO)
