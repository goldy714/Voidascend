extends Node2D

# ── Animation state ──────────────────────────────────────────────────────────
var _t: float = 0.0

# Floating debris
var _debris: Array = []
const DEBRIS_COUNT := 55

# Shooting stars
var _shooting_stars: Array = []
var _next_star_t: float = 3.0


func _ready() -> void:
	_init_debris()
	_build_ui()


func _init_debris() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5577
	var sz := get_viewport_rect().size
	for _i in DEBRIS_COUNT:
		_debris.append({
			"pos":   Vector2(rng.randf() * sz.x, rng.randf() * sz.y),
			"vel":   Vector2(rng.randf_range(-14.0, 14.0), rng.randf_range(-24.0, -5.0)),
			"size":  rng.randf_range(0.6, 2.2),
			"alpha": rng.randf_range(0.10, 0.48),
			"phase": rng.randf() * TAU,
			"blue":  rng.randf() > 0.42,
		})


func _process(delta: float) -> void:
	_t += delta
	var sz := get_viewport_rect().size

	# Move debris
	for p: Dictionary in _debris:
		p["pos"] += p["vel"] * delta
		if p["pos"].y < -10.0: p["pos"].y = sz.y + 10.0
		if p["pos"].x < -10.0: p["pos"].x = sz.x + 10.0
		elif p["pos"].x > sz.x + 10.0: p["pos"].x = -10.0

	# Shooting stars
	_next_star_t -= delta
	if _next_star_t <= 0.0:
		_next_star_t = randf_range(3.5, 9.0)
		_shooting_stars.append({
			"pos":  Vector2(randf_range(50.0, sz.x * 0.75), randf_range(20.0, sz.y * 0.45)),
			"vel":  Vector2(randf_range(380.0, 680.0), randf_range(100.0, 280.0)),
			"len":  randf_range(55.0, 140.0),
			"life": 1.0,
		})
	var alive: Array = []
	for ss: Dictionary in _shooting_stars:
		ss["pos"]  += ss["vel"] * delta
		ss["life"] -= delta * 1.6
		if ss["life"] > 0.0:
			alive.append(ss)
	_shooting_stars = alive

	queue_redraw()


func _draw() -> void:
	var sz := get_viewport_rect().size

	# ── Deep-space background ─────────────────────────────────────────────
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.010, 0.010, 0.075))

	# ── Nebulae ───────────────────────────────────────────────────────────
	_nebula(Vector2(sz.x * 0.76, sz.y * 0.20), 500.0, Color(0.28, 0.07, 0.58, 0.065))
	_nebula(Vector2(sz.x * 0.84, sz.y * 0.10), 300.0, Color(0.15, 0.03, 0.48, 0.048))
	_nebula(Vector2(sz.x * 0.09, sz.y * 0.78), 400.0, Color(0.04, 0.28, 0.54, 0.070))
	_nebula(Vector2(sz.x * 0.48, sz.y * 0.52), 640.0, Color(0.04, 0.08, 0.32, 0.038))

	# ── Planet Glacius (bottom-right, partially off screen) ───────────────
	var pc   := Vector2(sz.x * 0.90, sz.y * 1.10)
	var pr   := 400.0
	# Atmospheric glow rings
	for i: int in range(12, 0, -1):
		draw_circle(pc, pr + i * 26.0, Color(0.14, 0.48, 0.88, 0.015))
	# Planet body
	draw_circle(pc, pr, Color(0.09, 0.32, 0.65))
	# Ice bands / cloud layers
	draw_circle(pc + Vector2(-55.0, -85.0),  pr * 0.74, Color(0.16, 0.45, 0.78, 0.50))
	draw_circle(pc + Vector2( 28.0, -125.0), pr * 0.50, Color(0.22, 0.58, 0.90, 0.38))
	draw_circle(pc + Vector2(-15.0,  -45.0), pr * 0.25, Color(0.60, 0.86, 1.00, 0.24))
	# Terminator shadow
	draw_circle(pc + Vector2(180.0, 210.0),  pr * 0.90, Color(0.03, 0.12, 0.30, 0.62))

	# ── Stars ─────────────────────────────────────────────────────────────
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for _i: int in 240:
		var x:            float = rng.randf() * sz.x
		var y:            float = rng.randf() * sz.y
		var s:            float = rng.randf_range(0.5, 2.8)
		var a:            float = rng.randf_range(0.12, 0.95)
		var twink_flag:   float = rng.randf()
		var twink_speed:  float = rng.randf_range(0.8, 3.8)
		var twink_phase:  float = rng.randf() * TAU
		var color_roll:   float = rng.randf()
		if twink_flag > 0.76:
			a *= 0.35 + 0.65 * (0.5 + 0.5 * sin(_t * twink_speed + twink_phase))
		var col: Color
		if color_roll > 0.84:
			col = Color(0.55, 0.76, 1.00, a)    # blue-white
		elif color_roll > 0.93:
			col = Color(1.00, 0.88, 0.62, a)    # warm
		else:
			col = Color(0.92, 0.95, 1.00, a)    # cold white
		draw_circle(Vector2(x, y), s * 0.5, col)

	# ── Floating debris / dust ────────────────────────────────────────────
	for p: Dictionary in _debris:
		var a: float = p["alpha"] * (0.55 + 0.45 * sin(_t * 1.6 + p["phase"]))
		var col: Color = Color(0.38, 0.68, 1.00, a) if p["blue"] else Color(0.82, 0.90, 1.00, a)
		draw_circle(p["pos"], p["size"], col)

	# ── Shooting stars ────────────────────────────────────────────────────
	for ss: Dictionary in _shooting_stars:
		var a:    float   = ss["life"] * 0.90
		var tail: Vector2 = ss["pos"] - (ss["vel"] as Vector2).normalized() * ss["len"]
		draw_line(ss["pos"], tail, Color(0.85, 0.93, 1.00, a), 1.5)
		draw_circle(ss["pos"], 1.8, Color(1.00, 1.00, 1.00, a))


# Soft nebula blob: three overlapping circles
func _nebula(center: Vector2, radius: float, color: Color) -> void:
	draw_circle(center, radius, color)
	draw_circle(center + Vector2( radius * 0.30, -radius * 0.16), radius * 0.72, color)
	draw_circle(center + Vector2(-radius * 0.20,  radius * 0.26), radius * 0.62, color)


# ── UI ────────────────────────────────────────────────────────────────────────
func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	# Centred column
	var center_box := VBoxContainer.new()
	center_box.set_anchors_preset(Control.PRESET_CENTER)
	center_box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	center_box.grow_vertical   = Control.GROW_DIRECTION_BOTH
	center_box.alignment = BoxContainer.ALIGNMENT_CENTER
	center_box.add_theme_constant_override("separation", 32)
	ui.add_child(center_box)

	var title := Label.new()
	title.text = "VOID ASCENT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 112)
	title.add_theme_color_override("font_color", Color(0.22, 0.75, 1.00))
	center_box.add_child(title)

	var sub := Label.new()
	sub.text = "Překonej prázdnotu. Vzestup začíná."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 19)
	sub.add_theme_color_override("font_color", Color(0.45, 0.62, 0.86))
	center_box.add_child(sub)

	var start_btn := Button.new()
	start_btn.text = "▶   DO ZÁKLADNY"
	start_btn.custom_minimum_size = Vector2(340, 76)
	start_btn.add_theme_font_size_override("font_size", 28)
	start_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	center_box.add_child(start_btn)

	# ── Settings button (top-right corner) ───────────────────────────────
	var settings_btn := Button.new()
	settings_btn.text = "⚙"
	settings_btn.custom_minimum_size = Vector2(52, 52)
	settings_btn.add_theme_font_size_override("font_size", 22)
	settings_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	settings_btn.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	settings_btn.grow_vertical   = Control.GROW_DIRECTION_END
	settings_btn.offset_left   = -64
	settings_btn.offset_top    =  12
	settings_btn.offset_right  = -12
	settings_btn.offset_bottom =  64
	settings_btn.pressed.connect(_open_resolution_menu.bind(ui))
	ui.add_child(settings_btn)


func _open_resolution_menu(ui: CanvasLayer) -> void:
	# ── Dim overlay ───────────────────────────────────────────────────────
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.62)
	ui.add_child(overlay)

	# ── Popup panel ───────────────────────────────────────────────────────
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(500, 0)
	ui.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

	# Header row
	var hdr := HBoxContainer.new()
	vbox.add_child(hdr)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "⚙   Rozlišení a zobrazení"
	hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_lbl.add_theme_font_size_override("font_size", 20)
	hdr_lbl.add_theme_color_override("font_color", Color(0.25, 0.75, 1.00))
	hdr.add_child(hdr_lbl)

	var close_btn := Button.new()
	close_btn.text = "✕"
	close_btn.custom_minimum_size = Vector2(42, 42)
	close_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		panel.queue_free())
	hdr.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# Resolution presets
	var resolutions: Array = [
		{"label": "1280 × 720   (HD)",          "size": Vector2i(1280, 720)},
		{"label": "1600 × 900   (HD+)",          "size": Vector2i(1600, 900)},
		{"label": "1920 × 1080  (Full HD)",      "size": Vector2i(1920, 1080)},
		{"label": "2560 × 1440  (2K / QHD)",     "size": Vector2i(2560, 1440)},
	]

	var current_win_size := DisplayServer.window_get_size()
	var is_fullscreen: bool = DisplayServer.window_get_mode() \
		in [DisplayServer.WINDOW_MODE_FULLSCREEN,
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]

	for r: Dictionary in resolutions:
		var btn := Button.new()
		btn.text = r["label"]
		btn.custom_minimum_size = Vector2(0, 52)
		btn.add_theme_font_size_override("font_size", 17)
		var is_active: bool = (not is_fullscreen) and (current_win_size == r["size"])
		if is_active:
			btn.modulate = Color(0.28, 0.82, 1.00)
		var target: Vector2i = r["size"]
		btn.pressed.connect(func() -> void:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.window_set_size(target)
			var screen_sz := DisplayServer.screen_get_size()
			DisplayServer.window_set_position((screen_sz - target) / 2)
			overlay.queue_free()
			panel.queue_free())
		vbox.add_child(btn)

	vbox.add_child(HSeparator.new())

	# Fullscreen button
	var fs_btn := Button.new()
	fs_btn.text = "⛶   Celá obrazovka (Fullscreen)"
	fs_btn.custom_minimum_size = Vector2(0, 52)
	fs_btn.add_theme_font_size_override("font_size", 17)
	if is_fullscreen:
		fs_btn.modulate = Color(0.28, 0.82, 1.00)
	fs_btn.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		overlay.queue_free()
		panel.queue_free())
	vbox.add_child(fs_btn)
