extends Control
## Fills the left panel of the hangar.
## Draws the ship via ShipDraw and overlays transparent interactive slot buttons
## exactly on top of each drawn slot.

const ShipDraw = preload("res://scripts/ship_draw.gd")

const MAX_SCALE: float = 5.8
const MIN_SCALE: float = 2.8
const FIT_MARGIN: Vector2 = Vector2(84.0, 120.0)
const HULL_BOUNDS := {
	"scout": Rect2(Vector2(-58.0, -64.0), Vector2(116.0, 124.0)),
	"destroyer": Rect2(Vector2(-58.0, -66.0), Vector2(116.0, 130.0)),
}

var refresh_cb: Callable        # called after any slot change (hangar rebuilds right panel)
var _slot_btns: Array[Button]   = []
var _last_size:  Vector2        = Vector2.ZERO

# ── Drawing ───────────────────────────────────────────────────────

func _draw() -> void:
	var center: Vector2 = size / 2.0
	var bounds := _ship_bounds()
	var scale := _fit_scale(bounds)
	draw_set_transform(center - bounds.get_center() * scale, 0.0, Vector2(scale, scale))
	ShipDraw.draw_ship(self, GameData.current_ship, GameData.installed_modules)
	draw_set_transform(Vector2.ZERO)

func _process(_delta: float) -> void:
	queue_redraw()
	# Rebuild slot overlay whenever the control is resized
	if size != _last_size and size.x > 1.0:
		_last_size = size
		_rebuild_slots()

# ── Slot overlay ──────────────────────────────────────────────────

func rebuild(on_refresh: Callable) -> void:
	refresh_cb = on_refresh
	_rebuild_slots()

func _rebuild_slots() -> void:
	for btn: Button in _slot_btns:
		if is_instance_valid(btn):
			btn.queue_free()
	_slot_btns.clear()
	await get_tree().process_frame

	var ship_data: Dictionary = GameData.SHIP_DATA.get(GameData.current_ship, {})
	var g: Vector2i  = ship_data.get("grid", Vector2i(3, 3))
	var cols: int    = g.x
	var rows: int    = g.y
	var origin: Vector2 = ShipDraw.get_grid_origin(cols, rows)
	var center: Vector2 = size / 2.0
	var bounds := _ship_bounds()
	var bounds_center := bounds.get_center()
	var scale := _fit_scale(bounds)
	# Slot button size matches the drawn slot square at this scale
	var btn_px: float = ShipDraw.SLOT_HALF * 2.0 * scale

	for i: int in (cols * rows):
		var col: int = i % cols
		var row: int = i / cols
		var local_pos: Vector2  = origin + Vector2(col * ShipDraw.CELL, row * ShipDraw.CELL)
		var screen_pos: Vector2 = center + (local_pos - bounds_center) * scale

		var mid: String = ""
		if i < GameData.installed_modules.size():
			mid = GameData.installed_modules[i]

		var btn: Button = load("res://scripts/hangar_slot_btn.gd").new()
		btn.slot_index  = i
		btn.module_id   = mid
		btn.refresh_cb  = _on_slot_refreshed
		btn.position    = screen_pos - Vector2(btn_px, btn_px) * 0.5
		btn.size        = Vector2(btn_px, btn_px)
		btn.flat        = true
		btn.text        = ""    # visual comes from ShipDraw, not button text
		btn.focus_mode  = Control.FOCUS_NONE

		# Transparent normal, subtle hover glow
		var sty_normal  := StyleBoxEmpty.new()
		var sty_hover   := StyleBoxFlat.new()
		var sty_pressed := StyleBoxFlat.new()
		var sty_drop    := StyleBoxFlat.new()

		sty_hover.bg_color = Color(1, 1, 1, 0.14)
		sty_hover.set_corner_radius_all(4)
		sty_pressed.bg_color = Color(1, 1, 1, 0.28)
		sty_pressed.set_corner_radius_all(4)
		# Godot uses "focus" stylebox as the drag-over indicator
		sty_drop.bg_color = Color(0.30, 0.75, 1.00, 0.30)
		sty_drop.border_width_top    = 2
		sty_drop.border_width_bottom = 2
		sty_drop.border_width_left   = 2
		sty_drop.border_width_right  = 2
		sty_drop.border_color = Color(0.30, 0.75, 1.00, 0.90)
		sty_drop.set_corner_radius_all(4)

		btn.add_theme_stylebox_override("normal",  sty_normal)
		btn.add_theme_stylebox_override("hover",   sty_hover)
		btn.add_theme_stylebox_override("pressed", sty_pressed)
		btn.add_theme_stylebox_override("focus",   sty_drop)

		if not mid.is_empty():
			var mdata: Dictionary = GameData.MODULE_DATA.get(mid, {})
			btn.tooltip_text = "%s\n%s\n\n↔ Přetáhni pro přesun" % [
				mdata.get("name", mid), mdata.get("desc", "")
			]
		else:
			btn.tooltip_text = "Prázdný slot\n⬇ Přetáhni sem modul"

		add_child(btn)
		_slot_btns.append(btn)

func _on_slot_refreshed() -> void:
	_rebuild_slots()
	if refresh_cb.is_valid():
		refresh_cb.call()

func _ship_bounds() -> Rect2:
	var ship_data: Dictionary = GameData.SHIP_DATA.get(GameData.current_ship, {})
	var g: Vector2i = ship_data.get("grid", Vector2i(3, 3))
	var bounds: Rect2 = HULL_BOUNDS.get(GameData.current_ship,
		Rect2(Vector2(-60.0, -66.0), Vector2(120.0, 132.0)))

	var origin: Vector2 = ShipDraw.get_grid_origin(g.x, g.y)
	var slot_pad := Vector2(ShipDraw.SLOT_HALF + 5.0, ShipDraw.SLOT_HALF + 5.0)
	for i: int in (g.x * g.y):
		var col: int = i % g.x
		var row: int = i / g.x
		var slot_pos: Vector2 = origin + Vector2(col * ShipDraw.CELL, row * ShipDraw.CELL)
		bounds = bounds.expand(slot_pos - slot_pad)
		bounds = bounds.expand(slot_pos + slot_pad)
	return bounds

func _fit_scale(bounds: Rect2) -> float:
	if size.x <= 1.0 or size.y <= 1.0:
		return MIN_SCALE
	var available := Vector2(
		max(1.0, size.x - FIT_MARGIN.x),
		max(1.0, size.y - FIT_MARGIN.y)
	)
	var scale: float = min(available.x / bounds.size.x, available.y / bounds.size.y)
	return clampf(scale, MIN_SCALE, MAX_SCALE)
