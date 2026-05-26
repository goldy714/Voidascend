extends Node2D

const PLANET_RADIUS: float = 56.0
const PLANET_ART_DIR: String = "res://assets/fx"

# Normalized positions inside the available map area.
const PLANET_LAYOUT: Dictionary = {
	"glacius":      Vector2(0.08, 0.76),
	"infernus":     Vector2(0.30, 0.34),
	"toxar":        Vector2(0.52, 0.78),
	"shadowveil":   Vector2(0.74, 0.34),
	"void_station": Vector2(0.94, 0.74),
}

const TOP_BAR_HEIGHT: float = 58.0
const PANEL_MARGIN: float = 12.0
const PANEL_GAP: float = 34.0
const PANEL_MIN_WIDTH: float = 340.0
const PANEL_MAX_WIDTH: float = 555.0
const PANEL_WIDTH_RATIO: float = 0.42
const COMPACT_WIDTH: float = 900.0
const MAP_TOP_MARGIN: float = 42.0
const MAP_SIDE_MARGIN: float = 64.0
const MAP_BOTTOM_MARGIN: float = 92.0

const MISSION_NAMES: Array[String] = ["Mise 1", "Mise 2", "Mise 3", "⚡ BOSS"]

var _selected: String = ""
var _panel_vbox: VBoxContainer
var _mission_panel: PanelContainer
var _bg_rect: ColorRect
var _planet_art_rects: Dictionary = {}
var _planet_emoji_labels: Dictionary = {}
var _planet_name_labels: Dictionary = {}
var _planet_buttons: Dictionary = {}
var _planet_art_cache: Dictionary = {}
var _last_viewport_size: Vector2 = Vector2.ZERO

func _ready() -> void:
	_build_bg()
	var ui := CanvasLayer.new()
	add_child(ui)
	_build_top_bar(ui)
	_build_planet_nodes(ui)
	_build_mission_panel(ui)
	_update_layout(true)
	_select_planet("glacius")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		SettingsMenu.open()

func _process(_delta: float) -> void:
	_update_layout()

func _draw() -> void:
	_draw_paths()
	for pid: String in GameData.PLANET_ORDER:
		_draw_planet(pid)

# ── Background ────────────────────────────────────────────────

func _build_bg() -> void:
	_bg_rect = ColorRect.new()
	_bg_rect.color = Color(0.02, 0.02, 0.09)
	_bg_rect.size = get_viewport_rect().size
	add_child(_bg_rect)
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
		var a: Vector2 = _planet_position(pid_a)
		var b: Vector2 = _planet_position(pid_b)
		var unlocked: bool = GameData.is_planet_unlocked(pid_b)
		var col: Color = Color(0.35, 0.55, 0.90, 0.55) if unlocked \
						else Color(0.18, 0.20, 0.30, 0.45)
		var total: float = a.distance_to(b)
		if total <= 0.001:
			continue
		var dir: Vector2 = (b - a) / total
		var radius: float = _planet_radius()
		var t: float = radius + 8.0
		var dash: float = 13.0
		var gap: float  = 7.0
		while t + dash < total - radius - 8.0:
			draw_line(a + dir * t, a + dir * (t + dash), col, 2.0)
			t += dash + gap
		# Arrow head near destination planet
		if unlocked:
			var tip: Vector2 = b - dir * (radius + 5.0)
			var perp: Vector2 = Vector2(-dir.y, dir.x)
			draw_line(tip - dir * 9.0 + perp * 5.5, tip, col, 2.0)
			draw_line(tip - dir * 9.0 - perp * 5.5, tip, col, 2.0)

# ── Planet circle drawing ─────────────────────────────────────

func _draw_planet(pid: String) -> void:
	var pos: Vector2 = _planet_position(pid)
	var radius: float = _planet_radius()
	var pdata: Dictionary = GameData.PLANET_DATA[pid]
	var col: Color = pdata["color"]
	var unlocked: bool = GameData.is_planet_unlocked(pid)
	var done: int = GameData.missions_done.get(pid, 0)
	var is_sel: bool = (_selected == pid)

	if not unlocked:
		col = Color(0.16, 0.16, 0.22)

	# Selection glow
	if is_sel:
		draw_circle(pos, radius + 14.0, Color(col.r, col.g, col.b, 0.10))
		draw_arc(pos, radius + 9.0, 0.0, TAU, 48,
			Color(col.r, col.g, col.b, 0.80), 2.5)

	# Drop shadow
	draw_circle(pos + Vector2(4.0, 5.0), radius, Color(0.0, 0.0, 0.0, 0.38))

	var texture: Texture2D = _get_planet_art(pid)
	if texture != null:
		var rect := Rect2(
			pos - Vector2(radius, radius),
			Vector2(radius * 2.0, radius * 2.0)
		)
		var tint := Color(1.0, 1.0, 1.0, 1.0) if unlocked \
				else Color(0.30, 0.30, 0.38, 0.46)
		draw_texture_rect(texture, rect, false, tint)
	else:
		_draw_planet_body_fallback(pos, col, radius)

	# Colored rim keeps progression state readable over detailed art.
	draw_arc(pos, radius, 0.0, TAU, 48,
		Color(col.r, col.g, col.b, 0.88 if unlocked else 0.22), 2.8)

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
	_draw_progress_dots(pos + Vector2(0.0, radius + 26.0), done, unlocked, col)

func _draw_planet_body_fallback(pos: Vector2, col: Color, radius: float) -> void:
	# Fallback for missing PNG assets; detailed art should be used in normal builds.
	draw_circle(pos, radius,
		Color(col.r * 0.16, col.g * 0.18, col.b * 0.20, 0.97))
	draw_arc(pos, radius * 0.60, PI * 1.1, PI * 1.7, 12,
		Color(1.0, 1.0, 1.0, 0.09), radius * 0.40)

func _get_planet_art(pid: String) -> Texture2D:
	var path: String = "%s/planet_%s.png" % [PLANET_ART_DIR, pid]
	if _planet_art_cache.has(path):
		return _planet_art_cache[path] as Texture2D

	var texture: Texture2D = null
	if ResourceLoader.exists(path, "Texture2D"):
		texture = load(path) as Texture2D

	if texture == null and FileAccess.file_exists(path):
		var image: Image = Image.new()
		var err: int = image.load(path)
		if err == OK and not image.is_empty():
			texture = ImageTexture.create_from_image(image)

	if texture != null:
		_planet_art_cache[path] = texture
	return texture

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
		var pdata: Dictionary = GameData.PLANET_DATA[pid]
		var col: Color = pdata["color"]
		var unlocked: bool = GameData.is_planet_unlocked(pid)

		var planet_art := TextureRect.new()
		planet_art.texture = _get_planet_art(pid)
		planet_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		planet_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(planet_art)
		_planet_art_rects[pid] = planet_art

		# Emoji fallback for missing art. Hidden when PNG art is available.
		var emo := Label.new()
		emo.text = pdata["emoji"]
		emo.add_theme_font_size_override("font_size", 28)
		emo.size = Vector2(34.0, 38.0)
		emo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emo.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		if not unlocked:
			emo.modulate = Color(0.0, 0.0, 0.0, 0.0)
		ui.add_child(emo)
		_planet_emoji_labels[pid] = emo

		# Name label below circle
		var nl := Label.new()
		nl.text = pdata["name"]
		nl.add_theme_font_size_override("font_size", 14)
		nl.add_theme_color_override("font_color",
			col if unlocked else Color(0.28, 0.28, 0.38))
		nl.size = Vector2(140.0, 22.0)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(nl)
		_planet_name_labels[pid] = nl

		# Invisible click button (only unlocked planets clickable)
		if unlocked:
			var btn := Button.new()
			btn.flat = true
			for sname: String in ["normal", "hover", "pressed", "focus", "disabled"]:
				btn.add_theme_stylebox_override(sname, StyleBoxEmpty.new())
			btn.tooltip_text = pdata["name"]
			btn.pressed.connect(func() -> void: _select_planet(pid))
			ui.add_child(btn)
			_planet_buttons[pid] = btn

func _update_layout(force: bool = false) -> void:
	var viewport_size: Vector2 = get_viewport_rect().size
	if not force and viewport_size == _last_viewport_size:
		return

	_last_viewport_size = viewport_size
	if _bg_rect != null:
		_bg_rect.size = viewport_size
	_layout_mission_panel(viewport_size)
	_layout_planet_nodes()
	if not _selected.is_empty():
		_refresh_panel()
	queue_redraw()

func _layout_mission_panel(viewport_size: Vector2) -> void:
	if _mission_panel == null:
		return

	if _is_compact_layout(viewport_size):
		var panel_height: float = _compact_panel_height(viewport_size)
		_mission_panel.anchor_left = 0.0
		_mission_panel.anchor_right = 1.0
		_mission_panel.anchor_top = 1.0
		_mission_panel.anchor_bottom = 1.0
		_mission_panel.offset_left = PANEL_MARGIN
		_mission_panel.offset_right = -PANEL_MARGIN
		_mission_panel.offset_top = -panel_height - PANEL_MARGIN
		_mission_panel.offset_bottom = -PANEL_MARGIN
	else:
		var panel_width: float = _wide_panel_width(viewport_size)
		_mission_panel.anchor_left = 1.0
		_mission_panel.anchor_right = 1.0
		_mission_panel.anchor_top = 0.0
		_mission_panel.anchor_bottom = 1.0
		_mission_panel.offset_left = -panel_width - PANEL_MARGIN
		_mission_panel.offset_right = -PANEL_MARGIN
		_mission_panel.offset_top = TOP_BAR_HEIGHT + 4.0
		_mission_panel.offset_bottom = -PANEL_MARGIN

func _layout_planet_nodes() -> void:
	for pid: String in GameData.PLANET_ORDER:
		var pos: Vector2 = _planet_position(pid)
		var radius: float = _planet_radius()
		var unlocked: bool = GameData.is_planet_unlocked(pid)
		var texture: Texture2D = _get_planet_art(pid)

		if _planet_art_rects.has(pid):
			var art_rect: TextureRect = _planet_art_rects[pid] as TextureRect
			art_rect.texture = texture
			art_rect.visible = texture != null
			art_rect.position = pos - Vector2(radius, radius)
			art_rect.size = Vector2(radius * 2.0, radius * 2.0)
			art_rect.modulate = Color.WHITE if unlocked else Color(0.30, 0.30, 0.38, 0.46)

		if _planet_emoji_labels.has(pid):
			var emo: Label = _planet_emoji_labels[pid] as Label
			emo.position = pos - Vector2(17.0, 19.0)
			emo.visible = unlocked and texture == null

		if _planet_name_labels.has(pid):
			var nl: Label = _planet_name_labels[pid] as Label
			var pdata: Dictionary = GameData.PLANET_DATA[pid]
			var col: Color = pdata["color"]
			nl.position = Vector2(pos.x - 70.0, pos.y + radius + 4.0)
			nl.add_theme_color_override("font_color",
				col if unlocked else Color(0.28, 0.28, 0.38))

		if _planet_buttons.has(pid):
			var btn: Button = _planet_buttons[pid] as Button
			var r: float = _planet_radius() * 2.2
			btn.position = pos - Vector2(r * 0.5, r * 0.5)
			btn.size = Vector2(r, r)

func _planet_position(pid: String) -> Vector2:
	var map_rect: Rect2 = _map_rect()
	var radius: float = _planet_radius()
	var layout: Vector2 = PLANET_LAYOUT.get(pid, Vector2(0.5, 0.5))
	var pos: Vector2 = map_rect.position + Vector2(layout.x * map_rect.size.x, layout.y * map_rect.size.y)
	var map_end: Vector2 = map_rect.position + map_rect.size
	var min_x: float = map_rect.position.x + radius + 12.0
	var max_x: float = map_end.x - radius - 12.0
	var min_y: float = map_rect.position.y + radius + 10.0
	var max_y: float = map_end.y - radius - 52.0
	return Vector2(
		_clampf_safe(pos.x, min_x, max_x),
		_clampf_safe(pos.y, min_y, max_y)
	)

func _map_rect(viewport_size: Vector2 = Vector2.ZERO) -> Rect2:
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size

	var left: float = max(MAP_SIDE_MARGIN, viewport_size.x * 0.055)
	var top: float = TOP_BAR_HEIGHT + MAP_TOP_MARGIN
	var right: float
	var bottom: float

	if _is_compact_layout(viewport_size):
		bottom = viewport_size.y - _compact_panel_height(viewport_size) - PANEL_MARGIN - PANEL_GAP
		right = viewport_size.x - left
	else:
		right = viewport_size.x - _wide_panel_width(viewport_size) - PANEL_MARGIN - PANEL_GAP
		bottom = viewport_size.y - MAP_BOTTOM_MARGIN

	var radius: float = _planet_radius(viewport_size)
	var min_size := Vector2(radius * 3.0, radius * 2.7)
	return Rect2(
		Vector2(left, top),
		Vector2(max(min_size.x, right - left), max(min_size.y, bottom - top))
	)

func _planet_radius(viewport_size: Vector2 = Vector2.ZERO) -> float:
	if viewport_size == Vector2.ZERO:
		viewport_size = get_viewport_rect().size
	if _is_compact_layout(viewport_size):
		return clampf(viewport_size.x / 14.0, 30.0, 46.0)
	return PLANET_RADIUS

func _wide_panel_width(viewport_size: Vector2) -> float:
	return clampf(viewport_size.x * PANEL_WIDTH_RATIO, PANEL_MIN_WIDTH, PANEL_MAX_WIDTH)

func _compact_panel_height(viewport_size: Vector2) -> float:
	return clampf(viewport_size.y * 0.38, 230.0, 330.0)

func _is_compact_layout(viewport_size: Vector2) -> bool:
	return viewport_size.x < COMPACT_WIDTH

func _clampf_safe(value: float, min_value: float, max_value: float) -> float:
	if min_value > max_value:
		return (min_value + max_value) * 0.5
	return clampf(value, min_value, max_value)

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
	_mission_panel = PanelContainer.new()
	ui.add_child(_mission_panel)

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 22)
	_mission_panel.add_child(margin)

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

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	_panel_vbox.add_child(header)

	var preview_size: float = 82.0 if _is_compact_layout(get_viewport_rect().size) else 112.0
	var texture: Texture2D = _get_planet_art(_selected)
	if texture != null:
		var preview := TextureRect.new()
		preview.texture = texture
		preview.custom_minimum_size = Vector2(preview_size, preview_size)
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(preview)
	else:
		var fallback := Label.new()
		fallback.text = pdata.get("emoji", "")
		fallback.custom_minimum_size = Vector2(preview_size, preview_size)
		fallback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fallback.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		fallback.add_theme_font_size_override("font_size", int(preview_size * 0.42))
		fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
		header.add_child(fallback)

	var header_text := VBoxContainer.new()
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_text.add_theme_constant_override("separation", 6)
	header.add_child(header_text)

	# Planet title
	var title_lbl := Label.new()
	title_lbl.text = pdata.get("name", _selected)
	title_lbl.add_theme_font_size_override("font_size", 26 if _is_compact_layout(get_viewport_rect().size) else 30)
	title_lbl.add_theme_color_override("font_color", col)
	header_text.add_child(title_lbl)

	# Description
	var desc_lbl := Label.new()
	desc_lbl.text = pdata.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 13)
	desc_lbl.add_theme_color_override("font_color", Color(0.52, 0.55, 0.68))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_text.add_child(desc_lbl)

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
