extends Control
## Draws a live ship preview using ShipDraw.
## Place inside a Container; set custom_minimum_size to control area.
## The ship is automatically scaled to fill the control and animated.

@export var preview_scale: float = 2.5

func _draw() -> void:
	var center: Vector2 = size / 2.0
	draw_set_transform(center, 0.0, Vector2(preview_scale, preview_scale))
	ShipDraw.draw_ship(self, GameData.current_ship, GameData.installed_modules)
	draw_set_transform(Vector2.ZERO)

func _process(_delta: float) -> void:
	queue_redraw()
