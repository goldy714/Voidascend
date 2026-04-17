extends Node2D

var _inventory_container: VBoxContainer
var _info_label:          Label
var _slots_lbl:           Label
var _ship_view:           Control   # ShipHangarView

func _ready() -> void:
	_build_background()
	_build_ui()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.09)
	bg.size = get_viewport_rect().size
	add_child(bg)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	# ── Top bar ───────────────────────────────────────────────────
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, 56)
	ui.add_child(top)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 12)
	top.add_child(top_hbox)

	var back_btn := Button.new()
	back_btn.text = "← Zpět"
	back_btn.custom_minimum_size = Vector2(110, 0)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	top_hbox.add_child(back_btn)

	var ship: Dictionary = GameData.SHIP_DATA[GameData.current_ship]
	var g: Vector2i = ship["grid"]
	var title := Label.new()
	title.text = "  HANGÁR — %s  (%d×%d grid)" % [ship["name"], g.x, g.y]
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color(0.25, 0.75, 1.00))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title)

	_info_label = Label.new()
	_info_label.add_theme_font_size_override("font_size", 15)
	_info_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	top_hbox.add_child(_info_label)

	# ── Main split ────────────────────────────────────────────────
	var split := HBoxContainer.new()
	split.set_anchors_preset(Control.PRESET_FULL_RECT)
	split.offset_top = 58
	split.add_theme_constant_override("separation", 0)
	ui.add_child(split)

	# ── Left half: ship with interactive slots ────────────────────
	_ship_view = load("res://scripts/ship_hangar_view.gd").new()
	_ship_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ship_view.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	split.add_child(_ship_view)
	_ship_view.rebuild(_refresh_inventory)

	# Vertical divider
	var divider := VSeparator.new()
	split.add_child(divider)

	# ── Right half: inventory ─────────────────────────────────────
	var right_vbox := VBoxContainer.new()
	right_vbox.custom_minimum_size = Vector2(540, 0)
	right_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 0)
	split.add_child(right_vbox)

	# Inventory header
	var hdr := PanelContainer.new()
	hdr.custom_minimum_size = Vector2(0, 52)
	right_vbox.add_child(hdr)

	var hdr_hbox := HBoxContainer.new()
	hdr_hbox.add_theme_constant_override("separation", 16)
	hdr.add_child(hdr_hbox)

	var hdr_lbl := Label.new()
	hdr_lbl.text = "  📦  Inventář"
	hdr_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hdr_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hdr_lbl.add_theme_font_size_override("font_size", 18)
	hdr_lbl.add_theme_color_override("font_color", Color(0.75, 0.82, 1.00))
	hdr_hbox.add_child(hdr_lbl)

	_slots_lbl = Label.new()
	var slots_lbl: Label = _slots_lbl
	slots_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	slots_lbl.add_theme_font_size_override("font_size", 15)
	slots_lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.75))
	hdr_hbox.add_child(slots_lbl)

	# Drag hint
	var hint_lbl := Label.new()
	hint_lbl.text = "  Přetáhni modul na slot lodi"
	hint_lbl.add_theme_font_size_override("font_size", 13)
	hint_lbl.add_theme_color_override("font_color", Color(0.42, 0.50, 0.60))
	right_vbox.add_child(hint_lbl)

	# Scrollable module list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical   = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(scroll)

	_inventory_container = VBoxContainer.new()
	_inventory_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_inventory_container.add_theme_constant_override("separation", 2)
	scroll.add_child(_inventory_container)

	# Unequip drop zone at the bottom
	var drop_zone := PanelContainer.new()
	drop_zone.custom_minimum_size = Vector2(0, 72)
	right_vbox.add_child(drop_zone)

	var dz_lbl := Label.new()
	dz_lbl.text = "  🗑  Přetáhni instalovaný modul sem pro odebrání ze slotu"
	dz_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dz_lbl.add_theme_font_size_override("font_size", 22)
	dz_lbl.add_theme_color_override("font_color", Color(0.70, 0.38, 0.38))
	drop_zone.add_child(dz_lbl)

	drop_zone.set_drag_forwarding(
		func(_pos: Vector2) -> Variant: return null,
		func(_pos: Vector2, data: Variant) -> bool:
			return data is Dictionary and data.get("type") == "slot_module",
		func(_pos: Vector2, data: Variant) -> void:
			var from_slot: int = data.get("from_slot", -1)
			if from_slot >= 0:
				GameData.unequip_module(from_slot)
				_set_info("✓ Modul odebrán ze slotu")
				_refresh_inventory()
				_ship_view.rebuild(_refresh_inventory)
	)

	_refresh_inventory()

# ── Refresh ───────────────────────────────────────────────────────

func _refresh_inventory() -> void:
	_build_inventory_list()
	_update_slots_label()

func _update_slots_label() -> void:
	var filled: int = 0
	for m: String in GameData.installed_modules:
		if not m.is_empty():
			filled += 1
	if is_instance_valid(_slots_lbl):
		_slots_lbl.text = "Sloty: %d / %d   " % [filled, GameData.get_slot_count()]

func _build_inventory_list() -> void:
	for ch in _inventory_container.get_children():
		ch.queue_free()
	await get_tree().process_frame

	var found_any: bool = false

	for mid: String in GameData.MODULE_DATA.keys():
		if mid not in GameData.owned_modules:
			continue

		var total_owned: int = GameData.owned_modules.get(mid, 0)
		var available: int   = GameData.available_count(mid)
		var mdata: Dictionary = GameData.MODULE_DATA.get(mid, {})
		var cat: String       = mdata.get("category", "")
		var cc: Color         = GameData.CAT_COLORS.get(cat, Color.GRAY)

		var row: PanelContainer = load("res://scripts/hangar_inv_row.gd").new()
		row.module_id = mid
		row.custom_minimum_size = Vector2(0, 64)
		if available <= 0:
			row.modulate = Color(1, 1, 1, 0.40)
		_inventory_container.add_child(row)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		row.add_child(hbox)

		# Category colour strip
		var swatch := ColorRect.new()
		swatch.color = cc
		swatch.custom_minimum_size = Vector2(7, 0)
		hbox.add_child(swatch)

		# Module icon
		var icon: Control = load("res://scripts/module_icon.gd").new()
		icon.set("module_id", mid)
		icon.custom_minimum_size = Vector2(56, 56)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if available <= 0:
			icon.modulate = Color(1, 1, 1, 0.30)
		hbox.add_child(icon)

		# Module info
		var info := VBoxContainer.new()
		info.alignment = BoxContainer.ALIGNMENT_CENTER
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(info)

		var name_lbl := Label.new()
		name_lbl.text = mdata.get("name", mid)
		name_lbl.add_theme_font_size_override("font_size", 16)
		name_lbl.add_theme_color_override("font_color",
			cc if available > 0 else Color(0.48, 0.48, 0.52))
		info.add_child(name_lbl)

		var desc_lbl := Label.new()
		desc_lbl.text = mdata.get("desc", "")
		desc_lbl.add_theme_font_size_override("font_size", 12)
		desc_lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.58))
		info.add_child(desc_lbl)

		# Count
		var count_lbl := Label.new()
		count_lbl.add_theme_font_size_override("font_size", 13)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if available > 0:
			count_lbl.text = "×%d\ndostupné" % available
			count_lbl.add_theme_color_override("font_color", Color(0.88, 0.88, 0.50))
		else:
			count_lbl.text = "×%d\nvše\nvybaveno" % total_owned
			count_lbl.add_theme_color_override("font_color", Color(0.42, 0.42, 0.42))
		hbox.add_child(count_lbl)

		_inventory_container.add_child(HSeparator.new())
		found_any = true

	if not found_any:
		var lbl := Label.new()
		lbl.text = "Žádné moduly. Nakup v Obchodě."
		lbl.add_theme_color_override("font_color", Color(0.50, 0.50, 0.55))
		lbl.add_theme_font_size_override("font_size", 15)
		_inventory_container.add_child(lbl)

func _set_info(msg: String) -> void:
	if is_instance_valid(_info_label):
		_info_label.text = msg
