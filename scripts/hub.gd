extends Node2D

func _ready() -> void:
	_build_background()
	_build_ui()
	if not GameData.tutorial_done:
		var tutorial: CanvasLayer = load("res://scripts/tutorial.gd").new()
		add_child(tutorial)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		SettingsMenu.open()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.09)
	bg.size = get_viewport_rect().size
	add_child(bg)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var sz := get_viewport_rect().size
	for _i in 100:
		var star := ColorRect.new()
		var s: float = rng.randf_range(1.0, 2.5)
		star.size = Vector2(s, s)
		star.color = Color(1, 1, 1, rng.randf_range(0.15, 0.75))
		star.position = Vector2(rng.randf() * sz.x, rng.randf() * sz.y)
		add_child(star)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	var ship: Dictionary = GameData.SHIP_DATA[GameData.current_ship]
	var g: Vector2i = ship["grid"]

	# ── Top bar ───────────────────────────────────────────────────
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, 56)
	ui.add_child(top)

	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 30)
	top.add_child(top_hbox)

	var title_lbl := Label.new()
	title_lbl.text = "ZÁKLADNA — Glacius 🧊"
	title_lbl.add_theme_font_size_override("font_size", 20)
	title_lbl.add_theme_color_override("font_color", Color(0.25, 0.75, 1.00))
	top_hbox.add_child(title_lbl)

	var metal_lbl := Label.new()
	metal_lbl.text = "⚙ %d" % GameData.metal_scrap
	metal_lbl.add_theme_font_size_override("font_size", 18)
	top_hbox.add_child(metal_lbl)

	var crystal_lbl := Label.new()
	crystal_lbl.text = "💎 %d" % GameData.void_crystals
	crystal_lbl.add_theme_font_size_override("font_size", 18)
	crystal_lbl.add_theme_color_override("font_color", Color(0.25, 0.92, 1.00))
	top_hbox.add_child(crystal_lbl)

	# ── Centre split: left ship | right info ─────────────────────
	var split := HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.offset_top    = 58
	split.offset_bottom = -90
	split.add_theme_constant_override("separation", 0)
	ui.add_child(split)

	# Left — ship preview
	var left_panel := PanelContainer.new()
	left_panel.custom_minimum_size = Vector2(420, 0)
	split.add_child(left_panel)

	var left_vbox := VBoxContainer.new()
	left_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	left_vbox.add_theme_constant_override("separation", 6)
	left_panel.add_child(left_vbox)

	var preview: Control = load("res://scripts/ship_preview.gd").new()
	preview.set("preview_scale", 3.2)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	left_vbox.add_child(preview)

	var slot_info := Label.new()
	slot_info.text = "Sloty: %d / %d" % [
		GameData.installed_modules.size(), GameData.get_slot_count()
	]
	slot_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slot_info.add_theme_font_size_override("font_size", 13)
	slot_info.add_theme_color_override("font_color", Color(0.55, 0.60, 0.72))
	left_vbox.add_child(slot_info)

	# Right — info panel
	var right_margin := MarginContainer.new()
	right_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_margin.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	right_margin.add_theme_constant_override("margin_left",  32)
	right_margin.add_theme_constant_override("margin_right", 32)
	right_margin.add_theme_constant_override("margin_top",   24)
	right_margin.add_theme_constant_override("margin_bottom", 12)
	split.add_child(right_margin)

	var right_vbox := VBoxContainer.new()
	right_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	right_vbox.add_theme_constant_override("separation", 14)
	right_margin.add_child(right_vbox)

	# Ship name
	var ship_lbl := Label.new()
	ship_lbl.text = "%s  %s" % [ship["emoji"], ship["name"]]
	ship_lbl.add_theme_font_size_override("font_size", 32)
	ship_lbl.add_theme_color_override("font_color", Color(0.90, 0.92, 1.00))
	right_vbox.add_child(ship_lbl)

	# Abilities
	var passive_lbl := Label.new()
	passive_lbl.text = "Pasivní: %s" % ship["passive"]
	passive_lbl.add_theme_font_size_override("font_size", 14)
	passive_lbl.add_theme_color_override("font_color", Color(0.62, 0.75, 0.62))
	right_vbox.add_child(passive_lbl)

	var active_lbl := Label.new()
	active_lbl.text = "[SPACE] Aktivní: %s" % ship["active"]
	active_lbl.add_theme_font_size_override("font_size", 14)
	active_lbl.add_theme_color_override("font_color", Color(0.62, 0.75, 0.62))
	right_vbox.add_child(active_lbl)

	right_vbox.add_child(_sep())

	# Grid overview (text slots)
	var grid_lbl := Label.new()
	grid_lbl.text = "Grid %d×%d  —  %d/%d slotů obsazeno" % [
		g.x, g.y, GameData.installed_modules.size(), GameData.get_slot_count()
	]
	grid_lbl.add_theme_font_size_override("font_size", 15)
	grid_lbl.add_theme_color_override("font_color", Color(0.70, 0.72, 0.88))
	right_vbox.add_child(grid_lbl)

	# Mini slot grid (text badges, same as before)
	var grid_container := GridContainer.new()
	grid_container.columns = g.x
	grid_container.add_theme_constant_override("h_separation", 6)
	grid_container.add_theme_constant_override("v_separation", 6)
	right_vbox.add_child(grid_container)

	for i: int in GameData.get_slot_count():
		var slot_panel := PanelContainer.new()
		slot_panel.custom_minimum_size = Vector2(70, 48)
		grid_container.add_child(slot_panel)

		var slot_lbl := Label.new()
		slot_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_lbl.vertical_alignment   = VERTICAL_ALIGNMENT_CENTER
		slot_panel.add_child(slot_lbl)

		var mid: String = ""
		if i < GameData.installed_modules.size():
			mid = GameData.installed_modules[i]

		if not mid.is_empty():
			var mdata: Dictionary = GameData.MODULE_DATA.get(mid, {})
			var cat: String = mdata.get("category", "")
			slot_lbl.text = GameData.CAT_SHORT.get(cat, "?")
			slot_lbl.add_theme_color_override("font_color",
				GameData.CAT_COLORS.get(cat, Color.WHITE))
			slot_lbl.add_theme_font_size_override("font_size", 16)
		else:
			slot_lbl.text = "+"
			slot_lbl.add_theme_color_override("font_color", Color(0.3, 0.3, 0.4))

	right_vbox.add_child(_sep())

	# Run info
	var runs_lbl := Label.new()
	runs_lbl.text = "Celkem runů: %d   |   Glacius: %d" % [
		GameData.total_runs, GameData.planet_runs.get("glacius", 0)
	]
	runs_lbl.add_theme_font_size_override("font_size", 14)
	runs_lbl.add_theme_color_override("font_color", Color(0.48, 0.52, 0.62))
	right_vbox.add_child(runs_lbl)

	# ── Bottom buttons ────────────────────────────────────────────
	var bottom := PanelContainer.new()
	bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.custom_minimum_size = Vector2(0, 88)
	bottom.anchor_top    = 1.0
	bottom.offset_top    = -88
	bottom.offset_bottom = 0
	ui.add_child(bottom)

	var btn_hbox := HBoxContainer.new()
	btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_hbox.add_theme_constant_override("separation", 16)
	bottom.add_child(btn_hbox)

	_make_btn(btn_hbox, "🔧 HANGÁR", Color(0.30, 0.55, 0.90),
		func() -> void: get_tree().change_scene_to_file("res://scenes/hangar.tscn"))
	_make_btn(btn_hbox, "🛒 OBCHOD", Color(0.25, 0.70, 0.35),
		func() -> void: get_tree().change_scene_to_file("res://scenes/shop.tscn"))
	_make_btn(btn_hbox, "🚀 MISE",   Color(0.85, 0.35, 0.15),
		func() -> void: get_tree().change_scene_to_file("res://scenes/planet_map.tscn"))

	# Tester menu button
	var tester_btn := Button.new()
	tester_btn.custom_minimum_size = Vector2(140, 60)
	tester_btn.add_theme_font_size_override("font_size", 15)
	_update_tester_btn(tester_btn)
	tester_btn.pressed.connect(func() -> void: _show_tester_menu(ui, tester_btn))
	btn_hbox.add_child(tester_btn)

func _make_btn(parent: HBoxContainer, txt: String, clr: Color, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(168, 60)
	btn.add_theme_font_size_override("font_size", 18)
	btn.modulate = clr
	btn.pressed.connect(cb)
	parent.add_child(btn)

func _update_tester_btn(btn: Button) -> void:
	if GameData.tester_mode:
		btn.text = "🧪 TESTER: ZAP"
		btn.modulate = Color(0.20, 0.90, 0.40)
	else:
		btn.text = "🧪 TESTER: VYP"
		btn.modulate = Color(0.45, 0.45, 0.50)

func _show_tester_menu(ui: CanvasLayer, tester_btn: Button) -> void:
	# Tmavý overlay — klik mimo zavře menu
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.55)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	ui.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = Vector2(320, 0)
	ui.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	vbox.add_theme_constant_override("margin_left",  20)
	vbox.add_theme_constant_override("margin_right", 20)
	vbox.add_theme_constant_override("margin_top",   16)
	vbox.add_theme_constant_override("margin_bottom",16)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "🧪 TESTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.20, 0.90, 0.40))
	vbox.add_child(title)

	vbox.add_child(_menu_sep())

	# ── Zapnout / vypnout tester režim ────────────────────────────
	var toggle_btn := Button.new()
	if GameData.tester_mode:
		toggle_btn.text = "🧪  Tester režim: ZAP  (klikni pro VYP)"
		toggle_btn.modulate = Color(0.20, 0.90, 0.40)
	else:
		toggle_btn.text = "🧪  Tester režim: VYP  (klikni pro ZAP)"
		toggle_btn.modulate = Color(0.65, 0.65, 0.70)
	toggle_btn.add_theme_font_size_override("font_size", 15)
	toggle_btn.pressed.connect(func() -> void:
		GameData.toggle_tester_mode()
		_update_tester_btn(tester_btn)
		overlay.queue_free()
		panel.queue_free()
		get_tree().reload_current_scene()
	)
	vbox.add_child(toggle_btn)

	vbox.add_child(_menu_sep())

	# ── Reset na první spuštění ───────────────────────────────────
	var reset_btn := Button.new()
	reset_btn.text = "🔄  Reset na první spuštění"
	reset_btn.add_theme_font_size_override("font_size", 15)
	reset_btn.pressed.connect(func() -> void:
		var dlg := ConfirmationDialog.new()
		dlg.title = "Reset hry?"
		dlg.dialog_text = "Vymaže save a spustí tutoriál od začátku."
		dlg.ok_button_text = "Potvrdit"
		dlg.cancel_button_text = "Zrušit"
		ui.add_child(dlg)
		dlg.popup_centered()
		dlg.confirmed.connect(func() -> void:
			GameData.reset_to_first_launch()
			get_tree().change_scene_to_file("res://scenes/hub.tscn")
		)
		dlg.visibility_changed.connect(func() -> void:
			if not dlg.visible: dlg.queue_free()
		)
	)
	vbox.add_child(reset_btn)

	vbox.add_child(_menu_sep())

	# ── Odemknout všechny moduly ──────────────────────────────────
	var unlock_btn := Button.new()
	unlock_btn.text = "🔓  Odemknout všechny moduly"
	unlock_btn.add_theme_font_size_override("font_size", 15)
	unlock_btn.modulate = Color(0.25, 0.80, 1.00)
	unlock_btn.pressed.connect(func() -> void:
		GameData.research_all_modules()
		overlay.queue_free()
		panel.queue_free()
		get_tree().reload_current_scene()
	)
	vbox.add_child(unlock_btn)

	# ── Koupit 10× od každého modulu (jen v tester módu) ─────────
	if GameData.tester_mode:
		vbox.add_child(_menu_sep())
		var buy_btn := Button.new()
		buy_btn.text = "🛒  Koupit 10× od každého modulu"
		buy_btn.add_theme_font_size_override("font_size", 15)
		buy_btn.modulate = Color(0.95, 0.75, 0.10)
		buy_btn.pressed.connect(func() -> void:
			GameData.buy_all_modules_ten()
			overlay.queue_free()
			panel.queue_free()
			get_tree().reload_current_scene()
		)
		vbox.add_child(buy_btn)

	vbox.add_child(_menu_sep())

	# ── Zavřít ────────────────────────────────────────────────────
	var close_btn := Button.new()
	close_btn.text = "Zavřít"
	close_btn.add_theme_font_size_override("font_size", 14)
	close_btn.modulate = Color(0.55, 0.55, 0.60)
	close_btn.pressed.connect(func() -> void:
		overlay.queue_free()
		panel.queue_free()
	)
	vbox.add_child(close_btn)

	overlay.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			overlay.queue_free()
			panel.queue_free()
	)

	# Vystředit panel po přidání dětí
	await get_tree().process_frame
	var vp := get_viewport_rect().size
	panel.position = (vp - panel.size) * 0.5

func _menu_sep() -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, 4)
	return s

func _sep() -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, 6)
	return s
