extends Node2D

const PLANET_RADIUS: float = 56.0

# Screen positions for each planet on the map
const PLANET_POSITIONS: Dictionary = {
	"glacius":     Vector2(210, 730),
	"infernus":    Vector2(460, 510),
	"toxar":       Vector2(700, 720),
	"shadowveil":  Vector2(945, 500),
	"void_station":Vector2(1165, 710),
}

const MISSION_NAMES: Array[String] = ["Mise 1", "Mise 2", "Mise 3", "⚡ BOSS"]

var _selected: String = ""
var _panel_vbox: VBoxContainer

func _ready() -> void:
	_build_bg()
	var ui := CanvasLayer.new()
	add_child(ui)
	_build_top_bar(ui)
	_build_planet_nodes(ui)
	_build_mission_panel(ui)
	_select_planet("glacius")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		SettingsMenu.open()

func _draw() -> void:
	_draw_paths()
	for pid: String in GameData.PLANET_ORDER:
		_draw_planet(pid)

# ── Background ────────────────────────────────────────────────

func _build_bg() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.09)
	bg.size = get_viewport_rect().size
	add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 53
	var sz: Vector2 = get_viewport_rect().size
	for _i in 200:
		var star := ColorRect.new()
		var s: float = rng.randf_range(1.0, 2.8)
		star.size = Vector2(s, s)
		star.color = Color(1, 1, 1, rng.randf_range(0.08, 0.65))
		star.position = Vector2(rng.randf() * sz.x, rng.randf() * sz.y)
		add_child(star)

# ── Path lines ────────────────────────────────────────────────

func _draw_paths() -> void:
	for i: int in range(GameData.PLANET_ORDER.size() - 1):
		var pid_a: String = GameData.PLANET_ORDER[i]
		var pid_b: String = GameData.PLANET_ORDER[i + 1]
		var a: Vector2 = PLANET_POSITIONS[pid_a]
		var b: Vector2 = PLANET_POSITIONS[pid_b]
		var unlocked: bool = GameData.is_planet_unlocked(pid_b)
		var col: Color = Color(0.35, 0.55, 0.90, 0.55) if unlocked \
						else Color(0.18, 0.20, 0.30, 0.45)
		var total: float = a.distance_to(b)
		var dir: Vector2 = (b - a) / total
		var t: float = PLANET_RADIUS + 8.0
		var dash: float = 13.0
		var gap: float  = 7.0
		while t + dash < total - PLANET_RADIUS - 8.0:
			draw_line(a + dir * t, a + dir * (t + dash), col, 2.0)
			t += dash + gap
		# Arrow head near destination planet
		if unlocked:
			var tip: Vector2 = b - dir * (PLANET_RADIUS + 5.0)
			var perp: Vector2 = Vector2(-dir.y, dir.x)
			draw_line(tip - dir * 9.0 + perp * 5.5, tip, col, 2.0)
			draw_line(tip - dir * 9.0 - perp * 5.5, tip, col, 2.0)

# ── Planet circle drawing ─────────────────────────────────────

func _draw_planet(pid: String) -> void:
	var pos: Vector2   = PLANET_POSITIONS[pid]
	var pdata: Dictionary = GameData.PLANET_DATA[pid]
	var col: Color     = pdata["color"]
	var unlocked: bool = GameData.is_planet_unlocked(pid)
	var done: int      = GameData.missions_done.get(pid, 0)
	var is_sel: bool   = (_selected == pid)

	if not unlocked:
		col = Color(0.16, 0.16, 0.22)

	# Selection glow
	if is_sel:
		draw_circle(pos, PLANET_RADIUS + 14.0, Color(col.r, col.g, col.b, 0.10))
		draw_arc(pos, PLANET_RADIUS + 9.0, 0.0, TAU, 48,
			Color(col.r, col.g, col.b, 0.80), 2.5)

	# Drop shadow
	draw_circle(pos + Vector2(4.0, 5.0), PLANET_RADIUS, Color(0.0, 0.0, 0.0, 0.38))

	# Body fill
	draw_circle(pos, PLANET_RADIUS,
		Color(col.r * 0.16, col.g * 0.18, col.b * 0.20, 0.97))

	# Colored rim
	draw_arc(pos, PLANET_RADIUS, 0.0, TAU, 48,
		Color(col.r, col.g, col.b, 0.88 if unlocked else 0.22), 2.8)

	# Inner sheen
	draw_arc(pos, PLANET_RADIUS * 0.60, PI * 1.1, PI * 1.7, 12,
		Color(1.0, 1.0, 1.0, 0.09), PLANET_RADIUS * 0.40)

	# Padlock overlay on locked planets
	if not unlocked:
		draw_circle(pos, 17.0, Color(0.10, 0.10, 0.16, 0.90))
		draw_arc(pos, 16.0, 0.0, TAU, 24, Color(0.36, 0.38, 0.50, 0.70), 2.0)
		var arc_c: Vector2 = pos - Vector2(0.0, 5.0)
		draw_arc(arc_c, 7.0, PI, TAU, 12, Color(0.42, 0.44, 0.58, 0.85), 2.2)
		draw_line(arc_c - Vector2(7.0, 0.0), pos + Vector2(-7.0, 5.0),
			Color(0.42, 0.44, 0.58, 0.85), 2.2)
		draw_line(arc_c + Vector2(7.0, 0.0), pos + Vector2(7.0, 5.0),
			Color(0.42, 0.44, 0.58, 0.85), 2.2)
		draw_rect(Rect2(pos + Vector2(-9.0, 2.0), Vector2(18.0, 12.0)),
			Color(0.42, 0.44, 0.58, 0.85))

	# Progress dots below
	_draw_progress_dots(pos + Vector2(0.0, PLANET_RADIUS + 26.0), done, unlocked, col)

func _draw_progress_dots(base: Vector2, done: int, unlocked: bool, col: Color) -> void:
	var gap: float = 15.0
	var ox: float  = base.x - gap * 1.5
	for d: int in 4:
		var dp: Vector2 = Vector2(ox + d * gap, base.y)
		var is_boss: bool = (d == 3)
		var r: float = 6.5 if is_boss else 4.8
		if d < done:
			var dc: Color = Color(1.0, 0.72, 0.08, 0.95) if is_boss \
							else Color(col.r, col.g, col.b, 0.90)
			draw_circle(dp, r, dc)
			if is_boss:
				draw_arc(dp, r + 2.5, 0.0, TAU, 12, Color(1.0, 0.72, 0.08, 0.45), 1.5)
		else:
			draw_circle(dp, r, Color(0.12, 0.13, 0.20, 0.85))
			draw_arc(dp, r, 0.0, TAU, 12,
				Color(0.28, 0.30, 0.42, 0.60 if unlocked else 0.20), 1.2)

# ── Planet label + button nodes ───────────────────────────────

func _build_planet_nodes(ui: CanvasLayer) -> void:
	for pid: String in GameData.PLANET_ORDER:
		var pos: Vector2 = PLANET_POSITIONS[pid]
		var pdata: Dictionary = GameData.PLANET_DATA[pid]
		var col: Color = pdata["color"]
		var unlocked: bool = GameData.is_planet_unlocked(pid)

		# Emoji centered on circle
		var emo := Label.new()
		emo.text = pdata["emoji"]
		emo.add_theme_font_size_override("font_size", 28)
		emo.position = pos - Vector2(17.0, 19.0)
		emo.size = Vector2(34.0, 38.0)
		emo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emo.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		emo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			emo.modulate = Color(0.0, 0.0, 0.0, 0.0)
		ui.add_child(emo)

		# Name label below circle
		var nl := Label.new()
		nl.text = pdata["name"]
		nl.add_theme_font_size_override("font_size", 14)
		nl.add_theme_color_override("font_color",
			col if unlocked else Color(0.28, 0.28, 0.38))
		nl.position = Vector2(pos.x - 70.0, pos.y + PLANET_RADIUS + 4.0)
		nl.size = Vector2(140.0, 22.0)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(nl)

		# Invisible click button (only unlocked planets clickable)
		if unlocked:
			var btn := Button.new()
			var r: float = PLANET_RADIUS * 2.2
			btn.position = pos - Vector2(r * 0.5, r * 0.5)
			btn.size = Vector2(r, r)
			btn.flat = true
			for sname: String in ["normal", "hover", "pressed", "focus", "disabled"]:
				btn.add_theme_stylebox_override(sname, StyleBoxEmpty.new())
			btn.tooltip_text = pdata["name"]
			btn.pressed.connect(func() -> void: _select_planet(pid))
			ui.add_child(btn)

# ── Top bar ───────────────────────────────────────────────────

func _build_top_bar(ui: CanvasLayer) -> void:
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, 58)
	ui.add_child(top)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)
	top.add_child(hbox)

	var back := Button.new()
	back.text = "← ZPĚT"
	back.custom_minimum_size = Vector2(130, 42)
	back.add_theme_font_size_override("font_size", 16)
	back.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	hbox.add_child(back)

	var title := Label.new()
	title.text = "MAPA GALAXIE"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.70, 0.82, 1.00))
	hbox.add_child(title)

	var sp := Control.new()
	sp.custom_minimum_size = Vector2(130, 0)
	hbox.add_child(sp)

# ── Mission panel (right side) ────────────────────────────────

func _build_mission_panel(ui: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.anchor_left   = 1.0
	panel.anchor_right  = 1.0
	panel.anchor_top    = 0.0
	panel.anchor_bottom = 1.0
	panel.offset_left   = -555.0
	panel.offset_top    = 62.0
	panel.offset_right  = -12.0
	panel.offset_bottom = -12.0
	ui.add_child(panel)

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	panel.add_child(margin)

	_panel_vbox = VBoxContainer.new()
	_panel_vbox.add_theme_constant_override("separation", 10)
	margin.add_child(_panel_vbox)

# ── Planet selection ──────────────────────────────────────────

func _select_planet(planet_id: String) -> void:
	_selected = planet_id
	queue_redraw()
	_refresh_panel()

func _refresh_panel() -> void:
	for c: Node in _panel_vbox.get_children():
		c.queue_free()

	if _selected.is_empty():
		return

	var pdata: Dictionary = GameData.PLANET_DATA.get(_selected, {})
	var col: Color = pdata.get("color", Color.WHITE)
	var done: int  = GameData.missions_done.get(_selected, 0)

	# Planet title
	var title_lbl := Label.new()
	title_lbl.text = "%s  %s" % [pdata.get("emoji", ""), pdata.get("name", _selected)]
	title_lbl.add_theme_font_size_override("font_size", 30)
	title_lbl.add_theme_color_override("font_color", col)
	_panel_vbox.add_child(title_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = pdata.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.52, 0.55, 0.68))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_vbox.add_child(desc_lbl)

	_panel_vbox.add_child(_gap(8))

	var sec_lbl := Label.new()
	sec_lbl.text = "MISE"
	sec_lbl.add_theme_font_size_override("font_size", 15)
	sec_lbl.add_theme_color_override("font_color", Color(0.48, 0.52, 0.65))
	_panel_vbox.add_child(sec_lbl)

	for m: int in 4:
		_panel_vbox.add_child(_make_mission_row(m, done, col))

	_panel_vbox.add_child(_gap(14))

	# Summary
	var sum_lbl := Label.new()
	if done >= 4:
		sum_lbl.text = "✓  Planeta splněna"
		sum_lbl.add_theme_color_override("font_color", Color(0.28, 0.88, 0.40))
	else:
		sum_lbl.text = "Splněno: %d / 4 misí" % done
		sum_lbl.add_theme_color_override("font_color", Color(0.45, 0.50, 0.62))
	sum_lbl.add_theme_font_size_override("font_size", 14)
	_panel_vbox.add_child(sum_lbl)

	var runs: int = GameData.planet_runs.get(_selected, 0)
	if runs > 0:
		var runs_lbl := Label.new()
		runs_lbl.text = "Pokusy na planetě: %d" % runs
		runs_lbl.add_theme_font_size_override("font_size", 13)
		runs_lbl.add_theme_color_override("font_color", Color(0.35, 0.38, 0.50))
		_panel_vbox.add_child(runs_lbl)

func _make_mission_row(m: int, done: int, planet_col: Color) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.add_theme_constant_override("separation", 10)

	# Status badge
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(46, 46)
	row.add_child(badge)
	var badge_lbl := Label.new()
	badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(badge_lbl)

	# Name + difficulty
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 2)
	row.add_child(info)

	var name_lbl := Label.new()
	name_lbl.text = MISSION_NAMES[m]
	name_lbl.add_theme_font_size_override("font_size", 17)
	info.add_child(name_lbl)

	var diff_lbl := Label.new()
	diff_lbl.text = ["●○○○", "●●○○", "●●●○", "●●●●"][m]
	diff_lbl.add_theme_font_size_override("font_size", 11)
	info.add_child(diff_lbl)

	# Action button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(112, 44)
	btn.add_theme_font_size_override("font_size", 14)
	row.add_child(btn)

	var is_boss: bool = (m == 3)

	if m < done:
		# Completed
		badge_lbl.text = "✓"
		badge_lbl.add_theme_color_override("font_color", Color(0.20, 0.88, 0.38))
		name_lbl.add_theme_color_override("font_color", Color(0.55, 0.68, 0.55))
		diff_lbl.add_theme_color_override("font_color", Color(0.28, 0.48, 0.28))
		btn.text = "↩ Opakovat"
		btn.modulate = Color(0.50, 0.55, 0.50)
		btn.pressed.connect(func() -> void: _launch(m))
	elif m == done:
		# Next available mission
		var mc: Color = Color(1.0, 0.65, 0.05) if is_boss else planet_col
		badge_lbl.text = "⚡" if is_boss else "▶"
		badge_lbl.add_theme_color_override("font_color", mc)
		name_lbl.add_theme_color_override("font_color", Color(0.92, 0.94, 1.00))
		diff_lbl.add_theme_color_override("font_color", Color(0.52, 0.58, 0.72))
		btn.text = "🚀 ZAHÁJIT"
		btn.modulate = mc
		btn.pressed.connect(func() -> void: _launch(m))
	else:
		# Locked
		badge_lbl.text = "🔒"
		name_lbl.add_theme_color_override("font_color", Color(0.30, 0.32, 0.42))
		diff_lbl.add_theme_color_override("font_color", Color(0.22, 0.24, 0.32))
		btn.text = "Zamčeno"
		btn.disabled = true
		btn.modulate = Color(0.35, 0.35, 0.42)

	return row

func _launch(mission_idx: int) -> void:
	GameData.current_planet  = _selected
	GameData.current_mission = mission_idx
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _gap(h: int = 6) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s
