extends Control

## Animated module icon — draws the ShipDraw module graphic inside a coloured tile.
## Set module_id before adding to the scene tree.

var module_id: String  = ""
var icon_scale: float  = 3.2   # px per ShipDraw unit
var aim: Vector2       = Vector2.UP


func _ready() -> void:
	custom_minimum_size = Vector2(60, 60)
	mouse_filter = MOUSE_FILTER_IGNORE


func _draw() -> void:
	var sz := size
	if sz.x < 1.0:
		sz = custom_minimum_size

	# Background tile
	var cat: String = ""
	var cc: Color   = Color(0.18, 0.20, 0.28)
	if not module_id.is_empty():
		cat = GameData.MODULE_DATA.get(module_id, {}).get("category", "")
		cc  = GameData.CAT_COLORS.get(cat, Color.GRAY)

	draw_rect(Rect2(Vector2.ZERO, sz),
		Color(cc.r * 0.12, cc.g * 0.12, cc.b * 0.12, 0.88))
	draw_rect(Rect2(Vector2.ZERO, sz),
		Color(cc.r * 0.55, cc.g * 0.55, cc.b * 0.55, 0.55), false, 1.5)

	if module_id.is_empty():
		return

	# Draw the module graphic centred
	var center := sz / 2.0
	draw_set_transform(center, 0.0, Vector2(icon_scale, icon_scale))
	ShipDraw.draw_module_icon(self, module_id, aim)
	draw_set_transform(Vector2.ZERO)


func _process(_delta: float) -> void:
	queue_redraw()
