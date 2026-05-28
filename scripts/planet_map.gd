extends Node2D

const PLANET_RADIUS: float = 56.0
const PLANET_HOVER_SCALE: float = 1.18
const PLANET_HOVER_SPEED: float = 18.0
const PLANET_HOVER_EPSILON: float = 0.002
const PLANET_ART_DIR: String = "res://assets/fx"

# Normalized positions inside the available map area.
const PLANET_LAYOUT: Dictionary = {
	"glacius":      Vector2(0.08, 0.76),
	"infernus":     Vector2(0.30, 0.34),
	"toxar":        Vector2(0.52, 0.78),
	"shadowveil":   Vector2(0.74, 0.34),
	"void_station": Vector2(0.94, 0.74),
}

const PLANET_ART_REGIONS: Dictionary = {
	"glacius": Rect2(12.0, 12.0, 104.0, 104.0),
	"infernus": Rect2(17.0, 17.0, 93.0, 94.0),
	"toxar": Rect2(28.0, 28.0, 71.0, 72.0),
	"shadowveil": Rect2(19.0, 19.0, 91.0, 90.0),
	"void_station": Rect2(12.0, 23.0, 103.0, 100.0),
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
const MISSION_PANEL_CHANGE_DURATION: float = 0.24
const MISSION_PANEL_CHANGE_SCALE: float = 0.975

var _selected: String = ""
var _hovered_planet: String = ""
var _panel_vbox: VBoxContainer
var _mission_panel: PanelContainer
var _mission_panel_tween: Tween = null
var _bg_rect: ColorRect
var _planet_art_rects: Dictionary = {}
var _planet_emoji_labels: Dictionary = {}
var _planet_name_labels: Dictionary = {}
var _planet_buttons: Dictionary = {}
var _planet_art_cache: Dictionary = {}
var _planet_display_texture_cache: Dictionary = {}
var _planet_hover_scales: Dictionary = {}
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

func _process(delta: float) -> void:
	_update_layout()
	if _update_hover_zoom(delta):
		_layout_planet_nodes()
		queue_redraw()

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
	var visual_radius: float = _planet_visual_radius(pid)
	var pdata: Dictionary = GameData.PLANET_DATA[pid]
	var col: Color = pdata["color"]
	var unlocked: bool = GameData.is_planet_unlocked(pid)
	var done: int = GameData.missions_done.get(pid, 0)
	var is_sel: bool = (_selected == pid)

	if not unlocked:
		col = Color(0.16, 0.16, 0.22)

	# Selection glow
	if is_sel:
		draw_circle(pos, visual_radius + 14.0, Color(col.r, col.g, col.b, 0.10))
		draw_arc(pos, visual_radius + 9.0, 0.0, TAU, 48,
			Color(col.r, col.g, col.b, 0.80), 2.5)

	# Drop shadow
	draw_circle(pos + Vector2(4.0, 5.0), visual_radius, Color(0.0, 0.0, 0.0, 0.38))

	var texture: Texture2D = _get_planet_art(pid)
	if texture != null:
		var rect: Rect2 = _planet_art_rect(pid, pos, visual_radius)
		var region: Rect2 = _planet_art_region(pid)
		var tint := Color(1.0, 1.0, 1.0, 1.0) if unlocked \
				else Color(0.30, 0.30, 0.38, 0.46)
		draw_texture_rect_region(texture, rect, region, tint)
	else:
		_draw_planet_body_fallback(pos, col, visual_radius)

	# Colored rim keeps progression state readable over detailed art.
	draw_arc(pos, visual_radius, 0.0, TAU, 48,
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
	_draw_progress_dots(pos + Vector2(0.0, radius + 40.0), done, unlocked, col)

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

		_planet_hover_scales[pid] = 1.0

		var planet_art := TextureRect.new()
		planet_art.texture = _get_planet_display_texture(pid)
		planet_art.stretch_mode = TextureRect.STRETCH_SCALE
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
		nl.custom_minimum_size = Vector2(150.0, 22.0)
		nl.size = Vector2(150.0, 22.0)
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
			btn.mouse_entered.connect(func() -> void: _set_hovered_planet(pid))
			btn.mouse_exited.connect(func() -> void: _clear_hovered_planet(pid))
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

		var hover_scale: float = _planet_hover_scale(pid)

		if _planet_art_rects.has(pid):
			var art_rect: TextureRect = _planet_art_rects[pid] as TextureRect
			var art_size: Vector2 = _planet_art_display_size(pid, radius)
			art_rect.texture = _get_planet_display_texture(pid)
			art_rect.visible = texture != null
			art_rect.position = pos - art_size * 0.5
			art_rect.size = art_size
			art_rect.pivot_offset = art_size * 0.5
			art_rect.scale = Vector2(hover_scale, hover_scale)
			art_rect.modulate = Color.WHITE if unlocked else Color(0.30, 0.30, 0.38, 0.46)

		if _planet_emoji_labels.has(pid):
			var emo: Label = _planet_emoji_labels[pid] as Label
			emo.position = pos - Vector2(17.0, 19.0)
			emo.pivot_offset = emo.size * 0.5
			emo.scale = Vector2(hover_scale, hover_scale)
			emo.visible = unlocked and texture == null

		if _planet_name_labels.has(pid):
			var nl: Label = _planet_name_labels[pid] as Label
			var pdata: Dictionary = GameData.PLANET_DATA[pid]
			var col: Color = pdata["color"]
			nl.size = Vector2(150.0, 22.0)
			nl.position = Vector2(pos.x - nl.size.x * 0.5, pos.y + _planet_label_y_offset(pid, radius))
			nl.add_theme_color_override("font_color",
				col if unlocked else Color(0.28, 0.28, 0.38))

		if _planet_buttons.has(pid):
			var btn: Button = _planet_buttons[pid] as Button
			var hit_size: float = _planet_radius() * PLANET_HOVER_SCALE * 2.2
			btn.position = pos - Vector2(hit_size * 0.5, hit_size * 0.5)
			btn.size = Vector2(hit_size, hit_size)

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

func _planet_visual_radius(pid: String) -> float:
	return _planet_radius() * _planet_hover_scale(pid)

func _planet_art_rect(pid: String, center: Vector2, display_radius: float) -> Rect2:
	var art_size: Vector2 = _planet_art_display_size(pid, display_radius)
	return Rect2(center - art_size * 0.5, art_size)

func _planet_art_display_size(pid: String, display_radius: float) -> Vector2:
	var region: Rect2 = _planet_art_region(pid)
	var max_side: float = max(region.size.x, region.size.y)
	if max_side <= 0.001:
		return Vector2(display_radius * 2.0, display_radius * 2.0)
	return region.size * ((display_radius * 2.0) / max_side)

func _planet_label_y_offset(pid: String, radius: float) -> float:
	var texture: Texture2D = _get_planet_art(pid)
	if texture == null:
		return radius + 14.0
	return _planet_art_display_size(pid, radius).y * 0.5 + 14.0

func _planet_art_region(pid: String) -> Rect2:
	if PLANET_ART_REGIONS.has(pid):
		return PLANET_ART_REGIONS[pid] as Rect2
	var texture: Texture2D = _get_planet_art(pid)
	if texture != null:
		return Rect2(Vector2.ZERO, texture.get_size())
	return Rect2(Vector2.ZERO, Vector2(128.0, 128.0))

func _get_planet_display_texture(pid: String) -> Texture2D:
	if _planet_display_texture_cache.has(pid):
		return _planet_display_texture_cache[pid] as Texture2D
	var texture: Texture2D = _get_planet_art(pid)
	if texture == null:
		return null
	var atlas: AtlasTexture = AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = _planet_art_region(pid)
	_planet_display_texture_cache[pid] = atlas
	return atlas

func _planet_hover_scale(pid: String) -> float:
	return float(_planet_hover_scales.get(pid, 1.0))

func _target_planet_hover_scale(pid: String) -> float:
	if _hovered_planet == pid and GameData.is_planet_unlocked(pid):
		return PLANET_HOVER_SCALE
	return 1.0

func _update_hover_zoom(delta: float) -> bool:
	var changed := false
	var amount: float = clampf(delta * PLANET_HOVER_SPEED, 0.0, 1.0)
	for pid: String in GameData.PLANET_ORDER:
		var current_scale: float = float(_planet_hover_scales.get(pid, 1.0))
		var target_scale: float = _target_planet_hover_scale(pid)
		var next_scale: float = lerpf(current_scale, target_scale, amount)
		if absf(next_scale - target_scale) <= PLANET_HOVER_EPSILON:
			next_scale = target_scale
		if absf(next_scale - current_scale) > 0.0001:
			_planet_hover_scales[pid] = next_scale
			changed = true
	return changed

func _set_hovered_planet(pid: String) -> void:
	if _hovered_planet == pid:
		return
	_hovered_planet = pid
	queue_redraw()

func _clear_hovered_planet(pid: String) -> void:
	if _hovered_planet != pid:
		return
	_hovered_planet = ""
	queue_redraw()

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

func _apply_mission_panel_theme(planet_col: Color) -> void:
	if _mission_panel == null:
		return
	var bg: Color = _theme_mix(Color(0.025, 0.030, 0.055, 0.96), planet_col, 0.16, 0.96)
	var border: Color = _theme_mix(Color(0.18, 0.22, 0.32, 0.70), planet_col, 0.72, 0.90)
	_mission_panel.add_theme_stylebox_override("panel", _make_theme_style(bg, border, 2, 8))

func _theme_mix(base: Color, tint: Color, amount: float, alpha: float = -1.0) -> Color:
	var mixed: Color = base.lerp(tint, amount)
	if alpha >= 0.0:
		mixed.a = alpha
	return mixed

func _make_theme_style(fill: Color, border: Color, border_width: int = 1, radius: int = 6) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.border_width_top = border_width
	style.border_width_bottom = border_width
	style.border_width_left = border_width
	style.border_width_right = border_width
	style.set_corner_radius_all(radius)
	return style

func _mission_row_style(planet_col: Color, state: String, is_boss: bool) -> StyleBoxFlat:
	var accent: Color = _theme_mix(planet_col, Color.WHITE, 0.12) if is_boss else planet_col
	match state:
		"active":
			return _make_theme_style(
				_theme_mix(Color(0.045, 0.050, 0.085, 0.94), accent, 0.46, 0.94),
				Color(accent.r, accent.g, accent.b, 0.96),
				2, 7
			)
		"completed":
			return _make_theme_style(
				_theme_mix(Color(0.035, 0.052, 0.070, 0.88), accent, 0.30, 0.88),
				_theme_mix(Color(0.16, 0.22, 0.28, 0.64), accent, 0.72, 0.80),
				1, 7
			)
		_:
			return _make_theme_style(
				_theme_mix(Color(0.035, 0.038, 0.055, 0.78), accent, 0.18, 0.78),
				_theme_mix(Color(0.10, 0.11, 0.17, 0.50), accent, 0.62, 0.58),
				1, 7
			)

func _badge_style(planet_col: Color, state: String, is_boss: bool) -> StyleBoxFlat:
	var accent: Color = _theme_mix(planet_col, Color.WHITE, 0.12) if is_boss else planet_col
	match state:
		"active":
			return _make_theme_style(
				_theme_mix(Color(0.045, 0.050, 0.085, 0.96), accent, 0.52, 0.96),
				Color(accent.r, accent.g, accent.b, 0.98),
				2, 6
			)
		"completed":
			return _make_theme_style(
				_theme_mix(Color(0.030, 0.085, 0.080, 0.90), accent, 0.34, 0.90),
				_theme_mix(Color(0.18, 0.62, 0.42, 0.75), accent, 0.54, 0.82),
				1, 6
			)
		_:
			return _make_theme_style(
				_theme_mix(Color(0.055, 0.058, 0.078, 0.88), accent, 0.16, 0.88),
				_theme_mix(Color(0.16, 0.17, 0.24, 0.62), accent, 0.45, 0.68),
				1, 6
			)

func _apply_button_theme(btn: Button, accent: Color, enabled: bool) -> void:
	if not enabled:
		var disabled_fill: Color = _theme_mix(Color(0.045, 0.048, 0.064, 0.84), accent, 0.18, 0.84)
		var disabled_border: Color = _theme_mix(Color(0.12, 0.13, 0.18, 0.56), accent, 0.58, 0.62)
		var disabled_style: StyleBoxFlat = _make_theme_style(disabled_fill, disabled_border, 1, 6)
		btn.add_theme_stylebox_override("normal", disabled_style)
		btn.add_theme_stylebox_override("hover", disabled_style)
		btn.add_theme_stylebox_override("pressed", disabled_style)
		btn.add_theme_stylebox_override("disabled", disabled_style)
		btn.add_theme_color_override("font_disabled_color", _theme_mix(Color(0.38, 0.40, 0.50), accent, 0.38))
		btn.add_theme_color_override("font_color", _theme_mix(Color(0.38, 0.40, 0.50), accent, 0.38))
		return

	btn.add_theme_stylebox_override("normal", _make_theme_style(
		_theme_mix(Color(0.055, 0.064, 0.095, 0.96), accent, 0.48, 0.96),
		Color(accent.r, accent.g, accent.b, 0.92),
		2, 6
	))
	btn.add_theme_stylebox_override("hover", _make_theme_style(
		_theme_mix(Color(0.070, 0.078, 0.115, 0.98), accent, 0.64, 0.98),
		Color(accent.r, accent.g, accent.b, 1.0),
		2, 6
	))
	btn.add_theme_stylebox_override("pressed", _make_theme_style(
		_theme_mix(Color(0.030, 0.036, 0.060, 0.98), accent, 0.76, 0.98),
		Color(accent.r, accent.g, accent.b, 1.0),
		2, 6
	))
	btn.add_theme_color_override("font_color", _theme_mix(Color(0.86, 0.90, 1.00), accent, 0.32))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(1.0, 1.0, 1.0))

# ── Planet selection ──────────────────────────────────────────

func _select_planet(planet_id: String) -> void:
	var animate_panel: bool = not _selected.is_empty() and _selected != planet_id
	_selected = planet_id
	queue_redraw()
	_refresh_panel(animate_panel)

func _refresh_panel(animate_change: bool = false) -> void:
	for c: Node in _panel_vbox.get_children():
		c.queue_free()

	if _selected.is_empty():
		return

	var pdata: Dictionary = GameData.PLANET_DATA.get(_selected, {})
	var col: Color = pdata.get("color", Color.WHITE)
	var done: int  = GameData.missions_done.get(_selected, 0)
	_apply_mission_panel_theme(col)

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
	desc_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.52, 0.55, 0.68), col, 0.28))
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_text.add_child(desc_lbl)

	_panel_vbox.add_child(_gap(8))

	var sec_lbl := Label.new()
	sec_lbl.text = "MISE"
	sec_lbl.add_theme_font_size_override("font_size", 15)
	sec_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.48, 0.52, 0.65), col, 0.58))
	_panel_vbox.add_child(sec_lbl)

	for m: int in 4:
		_panel_vbox.add_child(_make_mission_row(m, done, col))

	_panel_vbox.add_child(_gap(14))

	# Summary
	var sum_lbl := Label.new()
	if done >= 4:
		sum_lbl.text = "✓  Planeta splněna"
		sum_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.28, 0.88, 0.40), col, 0.22))
	else:
		sum_lbl.text = "Splněno: %d / 4 misí" % done
		sum_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.45, 0.50, 0.62), col, 0.35))
	sum_lbl.add_theme_font_size_override("font_size", 14)
	_panel_vbox.add_child(sum_lbl)

	var runs: int = GameData.planet_runs.get(_selected, 0)
	if runs > 0:
		var runs_lbl := Label.new()
		runs_lbl.text = "Pokusy na planetě: %d" % runs
		runs_lbl.add_theme_font_size_override("font_size", 13)
		runs_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.35, 0.38, 0.50), col, 0.32))
		_panel_vbox.add_child(runs_lbl)

	if animate_change:
		_animate_mission_panel_change()
	else:
		_reset_mission_panel_animation()

func _animate_mission_panel_change() -> void:
	if _mission_panel == null or _panel_vbox == null:
		return
	_reset_mission_panel_animation()
	_mission_panel.pivot_offset = _mission_panel.size * 0.5
	_mission_panel.scale = Vector2(MISSION_PANEL_CHANGE_SCALE, MISSION_PANEL_CHANGE_SCALE)
	_mission_panel.modulate = Color(1.0, 1.0, 1.0, 0.86)
	_panel_vbox.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_mission_panel_tween = create_tween()
	_mission_panel_tween.set_parallel(true)
	_mission_panel_tween.set_trans(Tween.TRANS_QUAD)
	_mission_panel_tween.set_ease(Tween.EASE_OUT)
	_mission_panel_tween.tween_property(_mission_panel, "scale", Vector2.ONE, MISSION_PANEL_CHANGE_DURATION)
	_mission_panel_tween.tween_property(_mission_panel, "modulate", Color.WHITE, MISSION_PANEL_CHANGE_DURATION)
	_mission_panel_tween.tween_property(_panel_vbox, "modulate", Color.WHITE, MISSION_PANEL_CHANGE_DURATION * 0.85)

func _reset_mission_panel_animation() -> void:
	if _mission_panel_tween != null:
		if _mission_panel_tween.is_valid():
			_mission_panel_tween.kill()
		_mission_panel_tween = null
	if _mission_panel != null:
		_mission_panel.scale = Vector2.ONE
		_mission_panel.modulate = Color.WHITE
	if _panel_vbox != null:
		_panel_vbox.modulate = Color.WHITE

func _make_mission_row(m: int, done: int, planet_col: Color) -> Control:
	var is_boss: bool = (m == 3)
	var state: String = "locked"
	if m < done:
		state = "completed"
	elif m == done:
		state = "active"

	var row_panel := PanelContainer.new()
	row_panel.custom_minimum_size = Vector2(0, 56)
	row_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row_panel.add_theme_stylebox_override("panel", _mission_row_style(planet_col, state, is_boss))

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 52)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 10)
	row_panel.add_child(row)

	# Status badge
	var badge := PanelContainer.new()
	badge.custom_minimum_size = Vector2(46, 46)
	badge.add_theme_stylebox_override("panel", _badge_style(planet_col, state, is_boss))
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

	if m < done:
		# Completed
		badge_lbl.text = "✓"
		badge_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.20, 0.88, 0.38), planet_col, 0.55))
		name_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.64, 0.72, 0.82), planet_col, 0.52))
		diff_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.34, 0.48, 0.56), planet_col, 0.55))
		btn.text = "↩ Opakovat"
		_apply_button_theme(btn, planet_col, true)
		btn.pressed.connect(func() -> void: _launch(m))
	elif m == done:
		# Next available mission
		var mc: Color = _theme_mix(planet_col, Color.WHITE, 0.12) if is_boss else planet_col
		badge_lbl.text = "⚡" if is_boss else "▶"
		badge_lbl.add_theme_color_override("font_color", mc)
		name_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.92, 0.94, 1.00), planet_col, 0.16))
		diff_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.52, 0.58, 0.72), planet_col, 0.36))
		btn.text = "🚀 ZAHÁJIT"
		_apply_button_theme(btn, mc, true)
		btn.pressed.connect(func() -> void: _launch(m))
	else:
		# Locked
		badge_lbl.text = "🔒"
		badge_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.34, 0.36, 0.48), planet_col, 0.42))
		name_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.30, 0.32, 0.42), planet_col, 0.28))
		diff_lbl.add_theme_color_override("font_color", _theme_mix(Color(0.22, 0.24, 0.32), planet_col, 0.30))
		btn.text = "Zamčeno"
		btn.disabled = true
		_apply_button_theme(btn, planet_col, false)

	return row_panel

func _launch(mission_idx: int) -> void:
	GameData.current_planet  = _selected
	GameData.current_mission = mission_idx
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _gap(h: int = 6) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s
