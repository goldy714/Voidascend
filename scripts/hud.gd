extends CanvasLayer

var _hp_bar: ProgressBar
var _metal_lbl: Label
var _crystal_lbl: Label
var _wave_lbl: Label
var _ability_lbl: Label
var _overlay: ColorRect

func _ready() -> void:
	_build_top_bar()
	_build_ability_bar()
	_build_game_over()

# ── Top HUD bar ──────────────────────────────────────────────────
func _build_top_bar() -> void:
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	panel.custom_minimum_size = Vector2(0, 64)
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var hp_col := VBoxContainer.new()
	hp_col.custom_minimum_size = Vector2(180, 0)
	hbox.add_child(hp_col)

	var hp_lbl := Label.new()
	hp_lbl.text = "HP"
	hp_lbl.add_theme_font_size_override("font_size", 11)
	hp_col.add_child(hp_lbl)

	_hp_bar = ProgressBar.new()
	_hp_bar.custom_minimum_size = Vector2(180, 20)
	_hp_bar.show_percentage = false
	hp_col.add_child(_hp_bar)

	_metal_lbl = Label.new()
	_metal_lbl.text = "⚙ 0"
	_metal_lbl.add_theme_font_size_override("font_size", 17)
	hbox.add_child(_metal_lbl)

	_crystal_lbl = Label.new()
	_crystal_lbl.text = "💎 0"
	_crystal_lbl.add_theme_font_size_override("font_size", 17)
	_crystal_lbl.add_theme_color_override("font_color", Color(0.25, 0.92, 1.00))
	hbox.add_child(_crystal_lbl)

	_wave_lbl = Label.new()
	_wave_lbl.text = "Vlna -"
	_wave_lbl.add_theme_font_size_override("font_size", 17)
	_wave_lbl.add_theme_color_override("font_color", Color(1.00, 0.90, 0.20))
	hbox.add_child(_wave_lbl)

# ── Ability indicator (bottom) ────────────────────────────────────
func _build_ability_bar() -> void:
	var bar := PanelContainer.new()
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.custom_minimum_size = Vector2(0, 36)
	bar.anchor_top = 1.0
	bar.offset_top = -36
	bar.offset_bottom = 0.0
	add_child(bar)

	var hbox := HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	bar.add_child(hbox)

	_ability_lbl = Label.new()
	_ability_lbl.text = "[SPACE] Dash: READY"
	_ability_lbl.add_theme_font_size_override("font_size", 14)
	_ability_lbl.add_theme_color_override("font_color", Color.GREEN)
	hbox.add_child(_ability_lbl)

# ── Game over overlay ─────────────────────────────────────────────
func _build_game_over() -> void:
	_overlay = ColorRect.new()
	_overlay.color = Color(0.0, 0.0, 0.0, 0.80)
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_overlay)
	_overlay.hide()

func _sep(h: int = 8) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s

# ── Public update methods ─────────────────────────────────────────
func update_hp(current: int, maximum: int) -> void:
	_hp_bar.max_value = maximum
	_hp_bar.value = current

func update_metal(amount: int) -> void:
	_metal_lbl.text = "⚙ %d" % amount

func update_crystals(amount: int) -> void:
	_crystal_lbl.text = "💎 %d" % amount

func update_wave(wave_num: int) -> void:
	_wave_lbl.text = "Vlna %d" % wave_num

func update_ability(timer: float, cooldown: float) -> void:
	var ship_name: String = GameData.SHIP_DATA[GameData.current_ship].get("active", "Schopnost")
	if timer <= 0.0:
		_ability_lbl.text = "[SPACE] %s: READY" % ship_name
		_ability_lbl.add_theme_color_override("font_color", Color.GREEN)
	else:
		_ability_lbl.text = "[SPACE] %s: %.1fs" % [ship_name, timer]
		_ability_lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))

func show_game_over(victory: bool, metal: int, crystals: int) -> void:
	for c: Node in _overlay.get_children():
		c.queue_free()

	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 30)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	# Title
	var title := Label.new()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	if victory:
		title.text = "✓  MISE SPLNĚNA"
		title.add_theme_color_override("font_color", Color(0.28, 0.90, 0.42))
	else:
		title.text = "✗  MISE PROHRÁNA"
		title.add_theme_color_override("font_color", Color(0.90, 0.25, 0.25))
	vbox.add_child(title)

	# Planet + mission context
	var pdata: Dictionary = GameData.PLANET_DATA.get(GameData.current_planet, {})
	var mission_names: Array[String] = ["Mise 1", "Mise 2", "Mise 3", "⚡ BOSS"]
	var planet_col: Color = pdata.get("color", Color.WHITE)
	var ctx := Label.new()
	ctx.text = "%s %s  —  %s" % [
		pdata.get("emoji", ""), pdata.get("name", ""), mission_names[GameData.current_mission]
	]
	ctx.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ctx.add_theme_font_size_override("font_size", 16)
	ctx.add_theme_color_override("font_color", planet_col)
	vbox.add_child(ctx)

	vbox.add_child(_sep(6))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_sep(4))

	# Resources earned
	var metal_keep: int = metal if victory else int(metal * 0.5)
	var m_lbl := Label.new()
	m_lbl.text = "⚙  +%d kovový šrot" % metal_keep
	if not victory:
		m_lbl.text += "  (50% za prohru)"
	m_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	m_lbl.add_theme_font_size_override("font_size", 20)
	vbox.add_child(m_lbl)

	var c_lbl := Label.new()
	c_lbl.text = "💎  +%d void krystalů" % crystals
	c_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c_lbl.add_theme_font_size_override("font_size", 20)
	c_lbl.add_theme_color_override("font_color", Color(0.25, 0.92, 1.00))
	vbox.add_child(c_lbl)

	vbox.add_child(_sep(4))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_sep(8))

	# Action buttons
	if victory:
		var next_done: int = GameData.missions_done.get(GameData.current_planet, 0)
		if next_done < 4:
			var next_names: Array[String] = ["Mise 1", "Mise 2", "Mise 3", "⚡ BOSS"]
			var next_btn := Button.new()
			next_btn.text = "DALŠÍ: %s  →" % next_names[next_done]
			next_btn.custom_minimum_size = Vector2(300, 58)
			next_btn.add_theme_font_size_override("font_size", 20)
			next_btn.modulate = planet_col
			next_btn.pressed.connect(func() -> void:
				GameData.current_mission = next_done
				get_tree().reload_current_scene())
			vbox.add_child(next_btn)
	else:
		var retry := Button.new()
		retry.text = "↩  ZKUSIT ZNOVU"
		retry.custom_minimum_size = Vector2(300, 56)
		retry.add_theme_font_size_override("font_size", 19)
		retry.modulate = Color(0.88, 0.48, 0.15)
		retry.pressed.connect(func() -> void: get_tree().reload_current_scene())
		vbox.add_child(retry)

	var map_btn := Button.new()
	map_btn.text = "🗺  MAPA PLANET"
	map_btn.custom_minimum_size = Vector2(300, 52)
	map_btn.add_theme_font_size_override("font_size", 18)
	map_btn.modulate = Color(0.45, 0.60, 0.90)
	map_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/planet_map.tscn"))
	vbox.add_child(map_btn)

	var hub_btn := Button.new()
	hub_btn.text = "🏠  DO ZÁKLADNY"
	hub_btn.custom_minimum_size = Vector2(300, 52)
	hub_btn.add_theme_font_size_override("font_size", 18)
	hub_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	vbox.add_child(hub_btn)

	_overlay.show()
