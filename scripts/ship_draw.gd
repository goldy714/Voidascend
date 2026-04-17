class_name ShipDraw

# Cell size for module grid and origin offset
const CELL: float    = 20.0
const SLOT_HALF: float = 8.5

# ── Public API ────────────────────────────────────────────────────────────────

static func get_grid_origin(cols: int, rows: int) -> Vector2:
	return Vector2(-(cols - 1) * CELL * 0.5, -(rows - 1) * CELL * 0.5 - 6.0)

## Draw just the module graphic centered at origin.
## Call from within _draw() after draw_set_transform to position/scale it.
static func draw_module_icon(canvas: CanvasItem, module_id: String,
		aim: Vector2 = Vector2.UP) -> void:
	_draw_module(canvas, Vector2.ZERO, module_id, aim)

## Draw the full ship (hull + module slots) onto `canvas`.
## Call this from _draw() of any CanvasItem.
static func draw_ship(canvas: CanvasItem, ship_id: String,
		installed_modules: Array, aim: Vector2 = Vector2.UP) -> void:
	var ship_data: Dictionary = GameData.SHIP_DATA.get(ship_id, {})
	var g: Vector2i = ship_data.get("grid", Vector2i(3, 2))
	var cols: int = g.x
	var rows: int = g.y
	var origin: Vector2 = get_grid_origin(cols, rows)

	_draw_hull(canvas, ship_id)

	for i: int in (cols * rows):
		var col: int = i % cols
		var row: int = i / cols
		var slot_pos: Vector2 = origin + Vector2(col * CELL, row * CELL)
		var mid: String = installed_modules[i] if i < installed_modules.size() else ""
		if not mid.is_empty():
			var cat: String = GameData.MODULE_DATA.get(mid, {}).get("category", "")
			_draw_slot_bg(canvas, slot_pos, true, cat)
			_draw_module(canvas, slot_pos, mid, aim)
		else:
			_draw_slot_bg(canvas, slot_pos, false, "")
			_draw_structural(canvas, slot_pos)

# ── Hull shapes ───────────────────────────────────────────────────────────────

static func _draw_hull(canvas: CanvasItem, ship_id: String) -> void:
	match ship_id:
		"scout":     _draw_hull_scout(canvas)
		"destroyer": _draw_hull_destroyer(canvas)
		_:           _draw_hull_scout(canvas)

static func _draw_hull_scout(canvas: CanvasItem) -> void:
	var fill   := Color(0.07, 0.09, 0.18, 0.93)
	var line   := Color(0.30, 0.55, 0.90, 0.95)
	var accent := Color(0.18, 0.38, 0.70, 0.60)

	# Wide-body interceptor — broad enough to contain the 3×3 module grid (±28.5 wide)
	var body := PackedVector2Array([
		Vector2(  0, -52),
		Vector2( 30, -40),
		Vector2( 36, -14),
		Vector2( 36,  14),
		Vector2( 26,  28),
		Vector2( 10,  36),
		Vector2(  0,  38),
		Vector2(-10,  36),
		Vector2(-26,  28),
		Vector2(-36,  14),
		Vector2(-36, -14),
		Vector2(-30, -40),
	])
	canvas.draw_polygon(body, PackedColorArray([fill]))
	var body_closed := PackedVector2Array(body)
	body_closed.append(body[0])
	canvas.draw_polyline(body_closed, line, 1.5)

	# Swept delta wings extending beyond the body
	var rwing := PackedVector2Array([
		Vector2(36, -10), Vector2(52, -2), Vector2(48, 16), Vector2(36, 14),
	])
	canvas.draw_polygon(rwing, PackedColorArray([Color(fill.r, fill.g, fill.b + 0.04, fill.a)]))
	var rwing_closed := PackedVector2Array(rwing)
	rwing_closed.append(rwing[0])
	canvas.draw_polyline(rwing_closed, line, 1.5)

	var lwing := PackedVector2Array([
		Vector2(-36, -10), Vector2(-36, 14), Vector2(-48, 16), Vector2(-52, -2),
	])
	canvas.draw_polygon(lwing, PackedColorArray([Color(fill.r, fill.g, fill.b + 0.04, fill.a)]))
	var lwing_closed := PackedVector2Array(lwing)
	lwing_closed.append(lwing[0])
	canvas.draw_polyline(lwing_closed, line, 1.5)

	# Panel accent lines
	canvas.draw_line(Vector2(28, -36), Vector2(34, -12), accent, 1.0)
	canvas.draw_line(Vector2(30,  -6), Vector2(32,  12), accent, 0.8)
	canvas.draw_line(Vector2(-28, -36), Vector2(-34, -12), accent, 1.0)
	canvas.draw_line(Vector2(-30,  -6), Vector2(-32,  12), accent, 0.8)


	# Three engine nozzles
	for ex: float in [-16.0, 0.0, 16.0]:
		canvas.draw_circle(Vector2(ex, 31), 5.0, Color(0.14, 0.44, 1.00, 0.52))
		canvas.draw_circle(Vector2(ex, 31), 2.5, Color(0.55, 0.82, 1.00, 0.85))
		canvas.draw_circle(Vector2(ex, 31), 1.0, Color(1.00, 1.00, 1.00, 0.92))

static func _draw_hull_destroyer(canvas: CanvasItem) -> void:
	var fill   := Color(0.10, 0.07, 0.16, 0.93)
	var line   := Color(0.68, 0.28, 0.90, 0.95)
	var accent := Color(0.45, 0.18, 0.68, 0.60)

	# Main body
	var body := PackedVector2Array([
		Vector2(  0, -58),
		Vector2( 12, -42),
		Vector2( 30, -26),
		Vector2( 38,  18),
		Vector2( 26,  28),
		Vector2( 18,  38),
		Vector2(  8,  44),
		Vector2(  0,  46),
		Vector2( -8,  44),
		Vector2(-18,  38),
		Vector2(-26,  28),
		Vector2(-38,  18),
		Vector2(-30, -26),
		Vector2(-12, -42),
	])
	canvas.draw_polygon(body, PackedColorArray([fill]))
	var body_closed := PackedVector2Array(body)
	body_closed.append(body[0])
	canvas.draw_polyline(body_closed, line, 1.5)

	# Wings
	var rwing := PackedVector2Array([
		Vector2(30, -26), Vector2(50, -2), Vector2(38, 18),
	])
	canvas.draw_polygon(rwing, PackedColorArray([Color(fill.r, fill.g, fill.b + 0.04, fill.a)]))
	var rwing_closed := PackedVector2Array(rwing)
	rwing_closed.append(rwing[0])
	canvas.draw_polyline(rwing_closed, line, 1.5)

	var lwing := PackedVector2Array([
		Vector2(-30, -26), Vector2(-38, 18), Vector2(-50, -2),
	])
	canvas.draw_polygon(lwing, PackedColorArray([Color(fill.r, fill.g, fill.b + 0.04, fill.a)]))
	var lwing_closed := PackedVector2Array(lwing)
	lwing_closed.append(lwing[0])
	canvas.draw_polyline(lwing_closed, line, 1.5)

	# Accents
	canvas.draw_line(Vector2(15, -32), Vector2(44, -7), accent, 1.0)
	canvas.draw_line(Vector2(-15, -32), Vector2(-44, -7), accent, 1.0)

	# Cockpit
	canvas.draw_circle(Vector2(0, -34), 6.5, Color(0.35, 0.08, 0.60, 0.78))
	canvas.draw_arc(  Vector2(0, -34), 6.5, 0.0, TAU, 20, Color(0.75, 0.35, 1.00), 1.3)
	canvas.draw_circle(Vector2(0, -34), 2.5, Color(0.90, 0.70, 1.00, 0.60))

	# Four engine glows
	for ex: float in [-22.0, -8.0, 8.0, 22.0]:
		canvas.draw_circle(Vector2(ex, 38), 4.5, Color(0.50, 0.10, 0.85, 0.52))
		canvas.draw_circle(Vector2(ex, 38), 2.2, Color(0.80, 0.45, 1.00, 0.85))
		canvas.draw_circle(Vector2(ex, 38), 1.0, Color(1.00, 1.00, 1.00, 0.92))

# ── Slot background ───────────────────────────────────────────────────────────

static func _draw_slot_bg(canvas: CanvasItem, pos: Vector2,
		occupied: bool, category: String) -> void:
	var h: float = SLOT_HALF
	var rect := Rect2(pos - Vector2(h, h), Vector2(h * 2.0, h * 2.0))
	if occupied:
		var cc: Color = GameData.CAT_COLORS.get(category, Color.GRAY)
		canvas.draw_rect(rect, Color(cc.r * 0.18, cc.g * 0.18, cc.b * 0.18, 0.82))
		canvas.draw_rect(rect, Color(cc.r, cc.g, cc.b, 0.88), false, 1.5)
	else:
		canvas.draw_rect(rect, Color(0.04, 0.06, 0.11, 0.58))
		canvas.draw_rect(rect, Color(0.18, 0.20, 0.28, 0.58), false, 1.0)

# ── Empty slot: structural scaffolding ───────────────────────────────────────

static func _draw_structural(canvas: CanvasItem, pos: Vector2) -> void:
	var h: float = SLOT_HALF - 1.5
	var arm: float = 4.0
	var col  := Color(0.22, 0.28, 0.38, 0.78)
	var dim  := Color(0.18, 0.22, 0.30, 0.40)
	var w: float = 1.2
	# Corner brackets
	for sx: float in [-1.0, 1.0]:
		for sy: float in [-1.0, 1.0]:
			var corner: Vector2 = pos + Vector2(sx * h, sy * h)
			canvas.draw_line(corner, corner + Vector2(-sx * arm, 0.0), col, w)
			canvas.draw_line(corner, corner + Vector2(0.0, -sy * arm), col, w)
	# Centre cross
	canvas.draw_line(pos + Vector2(-3.5, 0.0), pos + Vector2(3.5, 0.0), dim, 0.8)
	canvas.draw_line(pos + Vector2(0.0, -3.5), pos + Vector2(0.0, 3.5), dim, 0.8)

# ── Module dispatcher ─────────────────────────────────────────────────────────

static func _draw_module(canvas: CanvasItem, pos: Vector2,
		module_id: String, aim: Vector2) -> void:
	match module_id:
		"basic_laser":      _wep_basic_laser(canvas, pos, aim)
		"double_laser":     _wep_double_laser(canvas, pos, aim)
		"plasma_laser":     _wep_plasma(canvas, pos, aim)
		"ion_cannon":       _wep_ion(canvas, pos, aim)
		"rockets":          _wep_rockets(canvas, pos, aim)
		"shotgun":          _wep_shotgun(canvas, pos, aim)
		"minigun":          _wep_minigun(canvas, pos, aim)
		"energy_shield":    _shld_energy(canvas, pos)
		"reflect_shield":   _shld_reflect(canvas, pos, aim)
		"basic_engine":     _eng_basic(canvas, pos)
		"advanced_engine":  _eng_advanced(canvas, pos)
		"ion_engine":       _eng_ion(canvas, pos)
		"basic_collector":  _col_basic(canvas, pos)
		"magnet_collector": _col_magnet(canvas, pos)
		"small_cargo":      _cargo(canvas, pos, 3.5)
		"medium_cargo":     _cargo(canvas, pos, 5.0)
		"large_cargo":      _cargo(canvas, pos, 6.5)
		"time_slow":        _spc_clock(canvas, pos)
		"emp":              _spc_emp(canvas, pos)
		"repair_unit":      _spc_repair(canvas, pos)
		"fighter_drone":    _spc_drone(canvas, pos)

# ── Weapons ───────────────────────────────────────────────────────────────────

static func _wep_basic_laser(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col := Color(0.30, 0.80, 1.00)
	canvas.draw_circle(pos, 3.0, Color(col.r * 0.35, col.g * 0.35, col.b * 0.35, 0.72))
	canvas.draw_line(pos - aim * 2.5, pos + aim * 7.5, col, 2.8)
	canvas.draw_circle(pos + aim * 7.5, 1.6, Color(0.88, 0.98, 1.00, 0.88))

static func _wep_double_laser(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col  := Color(0.30, 0.80, 1.00)
	var perp := Vector2(-aim.y, aim.x) * 3.2
	canvas.draw_circle(pos, 2.5, Color(col.r * 0.3, col.g * 0.3, col.b * 0.3, 0.65))
	canvas.draw_line(pos + perp - aim * 2.0, pos + perp + aim * 7.5, col, 2.0)
	canvas.draw_line(pos - perp - aim * 2.0, pos - perp + aim * 7.5, col, 2.0)
	canvas.draw_circle(pos + perp + aim * 7.5, 1.2, Color(1.00, 1.00, 1.00, 0.82))
	canvas.draw_circle(pos - perp + aim * 7.5, 1.2, Color(1.00, 1.00, 1.00, 0.82))

static func _wep_plasma(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col := Color(0.80, 0.30, 1.00)
	canvas.draw_circle(pos, 3.5, Color(col.r * 0.32, 0.06, col.b * 0.32, 0.72))
	canvas.draw_line(pos - aim * 2.0, pos + aim * 6.5, col, 4.5)
	canvas.draw_circle(pos + aim * 6.5, 3.2, Color(col.r, col.g, col.b, 0.48))
	canvas.draw_circle(pos + aim * 6.5, 1.5, Color(1.00, 1.00, 1.00, 0.72))

static func _wep_ion(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col := Color(0.20, 1.00, 0.60)
	canvas.draw_circle(pos, 2.8, Color(col.r * 0.18, col.g * 0.28, col.b * 0.18, 0.65))
	canvas.draw_line(pos - aim * 1.5, pos + aim * 9.5, col, 1.8)
	canvas.draw_circle(pos + aim * 9.5, 2.0, Color(col.r, col.g, col.b, 0.90))

static func _wep_rockets(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col  := Color(1.00, 0.30, 0.30)
	var perp := Vector2(-aim.y, aim.x)
	# Rocket tube
	var pts := PackedVector2Array([
		pos + perp * 3.8 - aim * 3.0,
		pos + perp * 3.8 + aim * 5.5,
		pos              + aim * 8.0,
		pos - perp * 3.8 + aim * 5.5,
		pos - perp * 3.8 - aim * 3.0,
	])
	canvas.draw_polygon(pts, PackedColorArray([Color(col.r * 0.28, 0.06, 0.06, 0.72)]))
	var pts_closed := PackedVector2Array(pts)
	pts_closed.append(pts[0])
	canvas.draw_polyline(pts_closed, col, 1.6)
	# Exhaust nozzles
	canvas.draw_line(pos + perp * 2.2 - aim * 3.0, pos + perp * 2.2 - aim * 5.5,
		Color(col.r, col.g, col.b, 0.48), 2.0)
	canvas.draw_line(pos - perp * 2.2 - aim * 3.0, pos - perp * 2.2 - aim * 5.5,
		Color(col.r, col.g, col.b, 0.48), 2.0)

static func _wep_shotgun(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col  := Color(1.00, 0.60, 0.20)
	var perp := Vector2(-aim.y, aim.x)
	# Stock
	canvas.draw_line(pos - perp * 5.5 - aim * 1.0, pos + perp * 5.5 - aim * 1.0, col, 2.2)
	# Three barrels
	for offs: float in [-4.5, 0.0, 4.5]:
		canvas.draw_line(pos + perp * offs + aim * 0.5,
						 pos + perp * offs + aim * 6.5, col, 1.8)

static func _wep_minigun(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col  := Color(1.00, 0.88, 0.25)
	var t: float = float(Time.get_ticks_msec()) * 0.004
	var perp := Vector2(-aim.y, aim.x)
	canvas.draw_circle(pos, 4.0, Color(0.20, 0.17, 0.05, 0.62))
	# Three spinning barrels offset perpendicular to aim
	for i: int in 3:
		var spin: float = t + float(i) * (TAU / 3.0)
		var side: Vector2 = perp * cos(spin) * 3.0
		canvas.draw_line(pos + side - aim * 1.5, pos + side + aim * 8.0, col, 1.5)
	canvas.draw_circle(pos, 2.0, col * Color(1, 1, 1, 0.52))

# ── Shields ───────────────────────────────────────────────────────────────────

static func _shld_energy(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.15, 0.78, 1.00)
	var t: float = float(Time.get_ticks_msec()) * 0.0015
	canvas.draw_circle(pos, 6.5, Color(0.06, 0.18, 0.22, 0.50))
	canvas.draw_arc(pos, 6.5, t, t + TAU * 0.75, 24, col, 2.2)
	canvas.draw_circle(pos, 2.5, Color(col.r, col.g, col.b, 0.55))

static func _shld_reflect(canvas: CanvasItem, pos: Vector2, aim: Vector2) -> void:
	var col  := Color(0.92, 0.88, 0.20)
	var perp := Vector2(-aim.y, aim.x)
	canvas.draw_line(pos + perp * 7.0 - aim * 1.8,
					 pos - perp * 7.0 - aim * 1.8, col, 3.0)
	canvas.draw_circle(pos - aim * 1.8, 2.0, Color(col.r, col.g, col.b, 0.32))

# ── Engines ───────────────────────────────────────────────────────────────────

static func _eng_basic(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.22, 0.62, 1.00)
	var t: float = float(Time.get_ticks_msec()) * 0.002
	canvas.draw_circle(pos, 5.2, Color(0.10, 0.18, 0.32, 0.58))
	canvas.draw_arc(pos, 5.2, 0.0, TAU, 18, Color(col.r, col.g, col.b, 0.72), 1.5)
	canvas.draw_circle(pos, 2.8, Color(col.r, col.g, col.b, 0.58 + 0.30 * sin(t)))
	canvas.draw_circle(pos, 1.2, Color(0.80, 0.95, 1.00, 0.88))

static func _eng_advanced(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.28, 0.90, 1.00)
	var t: float = float(Time.get_ticks_msec()) * 0.002
	for offset: Vector2 in [Vector2(-3.5, 0.0), Vector2(3.5, 0.0)]:
		canvas.draw_circle(pos + offset, 3.2, Color(0.08, 0.24, 0.30, 0.56))
		canvas.draw_arc(pos + offset, 3.2, 0.0, TAU, 12,
			Color(col.r, col.g, col.b, 0.72), 1.2)
		canvas.draw_circle(pos + offset, 1.5,
			Color(col.r, col.g, col.b, 0.58 + 0.30 * sin(t + offset.x)))

static func _eng_ion(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.60, 0.20, 1.00)
	var t: float = float(Time.get_ticks_msec()) * 0.003
	canvas.draw_circle(pos, 6.2, Color(0.15, 0.05, 0.26, 0.55))
	canvas.draw_arc(pos, 6.2, t,       t + TAU * 0.60, 20, col, 2.2)
	canvas.draw_arc(pos, 6.2, t + PI,  t + PI + TAU * 0.30, 12,
		Color(col.r, col.g, col.b, 0.48), 1.5)
	canvas.draw_circle(pos, 3.0, Color(col.r, col.g, col.b, 0.72))
	canvas.draw_circle(pos, 1.5, Color(0.88, 0.70, 1.00, 0.92))

# ── Collectors ────────────────────────────────────────────────────────────────

static func _col_basic(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.92, 0.72, 0.18)
	canvas.draw_line(pos + Vector2(-5.5, -3.5), pos + Vector2(-1.5, 4.5), col, 1.6)
	canvas.draw_line(pos + Vector2( 5.5, -3.5), pos + Vector2( 1.5, 4.5), col, 1.6)
	canvas.draw_line(pos + Vector2(-5.5, -3.5), pos + Vector2( 5.5, -3.5), col, 1.6)
	canvas.draw_line(pos + Vector2(-1.5,  4.5), pos + Vector2( 1.5,  4.5), col, 2.0)

static func _col_magnet(canvas: CanvasItem, pos: Vector2) -> void:
	var c1 := Color(0.95, 0.22, 0.22)
	var c2 := Color(0.22, 0.32, 1.00)
	canvas.draw_line(pos + Vector2(-5, 5), pos + Vector2(-5, -1), c1, 2.2)
	canvas.draw_line(pos + Vector2( 5, 5), pos + Vector2( 5, -1), c2, 2.2)
	canvas.draw_arc(pos + Vector2(0, -1), 5.0, PI, TAU, 14, Color(0.82, 0.82, 0.92), 2.2)
	canvas.draw_line(pos + Vector2(-5, 5), pos + Vector2(-5, 7.5), c1, 3.2)
	canvas.draw_line(pos + Vector2( 5, 5), pos + Vector2( 5, 7.5), c2, 3.2)

# ── Cargo ─────────────────────────────────────────────────────────────────────

static func _cargo(canvas: CanvasItem, pos: Vector2, half: float) -> void:
	var col := Color(0.62, 0.50, 0.28)
	var rect := Rect2(pos - Vector2(half, half), Vector2(half * 2.0, half * 2.0))
	canvas.draw_rect(rect, Color(0.22, 0.17, 0.08, 0.65))
	canvas.draw_rect(rect, col, false, 1.6)
	canvas.draw_line(pos + Vector2(-half, 0), pos + Vector2(half, 0),
		Color(col.r, col.g, col.b, 0.35), 0.9)
	canvas.draw_line(pos + Vector2(0, -half), pos + Vector2(0, half),
		Color(col.r, col.g, col.b, 0.35), 0.9)

# ── Specials ──────────────────────────────────────────────────────────────────

static func _spc_clock(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.18, 0.82, 0.80)
	var t: float = float(Time.get_ticks_msec()) * 0.001
	canvas.draw_circle(pos, 6.5, Color(0.06, 0.18, 0.18, 0.55))
	canvas.draw_arc(pos, 6.5, 0.0, TAU, 20, col, 1.3)
	canvas.draw_line(pos, pos + Vector2(sin(t * 0.5), -cos(t * 0.5)) * 3.0,
		col, 1.8)
	canvas.draw_line(pos, pos + Vector2(sin(t * 6.0), -cos(t * 6.0)) * 5.0,
		Color(1.00, 1.00, 1.00, 0.90), 1.2)
	canvas.draw_circle(pos, 1.2, col)

static func _spc_emp(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(1.00, 0.90, 0.15)
	var pts := PackedVector2Array([
		pos + Vector2( 2.0, -7.5),
		pos + Vector2(-1.5, -0.5),
		pos + Vector2( 2.5, -0.5),
		pos + Vector2(-2.0,  7.5),
		pos + Vector2( 1.5,  0.5),
		pos + Vector2(-2.5,  0.5),
	])
	canvas.draw_polygon(pts, PackedColorArray([Color(col.r * 0.38, col.g * 0.38, 0.08, 0.65)]))
	var pts_closed := PackedVector2Array(pts)
	pts_closed.append(pts[0])
	canvas.draw_polyline(pts_closed, col, 1.3)

static func _spc_repair(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.18, 1.00, 0.38)
	canvas.draw_rect(Rect2(pos + Vector2(-2.2, -7.0), Vector2(4.4, 14.0)),
		Color(col.r, col.g, col.b, 0.88))
	canvas.draw_rect(Rect2(pos + Vector2(-7.0, -2.2), Vector2(14.0, 4.4)),
		Color(col.r, col.g, col.b, 0.88))

static func _spc_drone(canvas: CanvasItem, pos: Vector2) -> void:
	var col := Color(0.82, 0.82, 0.18)
	var t: float = float(Time.get_ticks_msec()) * 0.002
	canvas.draw_circle(pos, 3.8, Color(0.20, 0.20, 0.05, 0.70))
	canvas.draw_arc(pos, 3.8, 0.0, TAU, 12, col, 1.5)
	canvas.draw_circle(pos, 1.8, Color(col.r, col.g, col.b, 0.62))
	# Spinning rotors
	for i: int in 4:
		var ang: float = t + float(i) * (TAU / 4.0)
		var tip: Vector2 = pos + Vector2(cos(ang), sin(ang)) * 6.5
		canvas.draw_line(pos, tip, Color(col.r, col.g, col.b, 0.42), 1.0)
		canvas.draw_circle(tip, 1.8, Color(col.r, col.g, col.b, 0.36))
