extends Node2D

const CATEGORIES := ["all", "weapon", "shield", "engine", "collector", "cargo", "special"]
const CAT_NAMES  := {
	"all": "Vše", "weapon": "Zbraně", "shield": "Štíty",
	"engine": "Motory", "collector": "Sběrači", "cargo": "Náklad", "special": "Aktivní",
	"test": "🧪 Testovací"
}

var _active_cat: String = "all"
var _list_container: VBoxContainer
var _status_lbl: Label
var _metal_lbl: Label
var _crystal_lbl: Label

func _ready() -> void:
	_build_background()
	_build_ui()
	_refresh_list()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		SettingsMenu.open()

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.09)
	bg.size = get_viewport_rect().size
	add_child(bg)

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	add_child(ui)

	# ── Top bar ──────────────────────────────────────────────
	var top := PanelContainer.new()
	top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top.custom_minimum_size = Vector2(0, 56)
	ui.add_child(top)

	var top_hbox := HBoxContainer.new()
	top_hbox.add_theme_constant_override("separation", 10)
	top.add_child(top_hbox)

	var back_btn := Button.new()
	back_btn.text = "← Zpět"
	back_btn.custom_minimum_size = Vector2(100, 0)
	back_btn.pressed.connect(func() -> void:
		get_tree().change_scene_to_file("res://scenes/hub.tscn"))
	top_hbox.add_child(back_btn)

	var title := Label.new()
	title.text = "  OBCHOD"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color(0.30, 0.85, 0.45))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(title)

	_metal_lbl = Label.new()
	_metal_lbl.text = "⚙ %d" % GameData.metal_scrap
	_metal_lbl.add_theme_font_size_override("font_size", 17)
	top_hbox.add_child(_metal_lbl)

	_crystal_lbl = Label.new()
	_crystal_lbl.text = "  💎 %d" % GameData.void_crystals
	_crystal_lbl.add_theme_font_size_override("font_size", 17)
	_crystal_lbl.add_theme_color_override("font_color", Color(0.25, 0.92, 1.00))
	top_hbox.add_child(_crystal_lbl)

	# ── Category filter buttons ───────────────────────────────
	var cat_bar := PanelContainer.new()
	cat_bar.anchor_left   = 0; cat_bar.anchor_right  = 1
	cat_bar.anchor_top    = 0; cat_bar.anchor_bottom = 0
	cat_bar.offset_top    = 56; cat_bar.offset_bottom = 96
	ui.add_child(cat_bar)

	var cat_hbox := HBoxContainer.new()
	cat_hbox.add_theme_constant_override("separation", 4)
	cat_bar.add_child(cat_hbox)

	var active_cats: Array = CATEGORIES.duplicate()
	if GameData.tester_mode:
		active_cats.append("test")
	for cat in active_cats:
		var btn := Button.new()
		btn.text = CAT_NAMES[cat]
		btn.custom_minimum_size = Vector2(0, 32)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", 13)
		if cat == "test":
			btn.add_theme_color_override("font_color", Color(0.95, 0.75, 0.25))
		var c: String = cat
		btn.pressed.connect(func() -> void: _set_category(c))
		cat_hbox.add_child(btn)

	# ── Status label ──────────────────────────────────────────
	_status_lbl = Label.new()
	_status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_lbl.add_theme_font_size_override("font_size", 14)
	_status_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3))
	_status_lbl.anchor_left   = 0; _status_lbl.anchor_right  = 1
	_status_lbl.anchor_top    = 0; _status_lbl.anchor_bottom = 0
	_status_lbl.offset_top    = 96; _status_lbl.offset_bottom = 120
	ui.add_child(_status_lbl)

	# ── Scrollable module list ────────────────────────────────
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_top = 120
	ui.add_child(scroll)

	_list_container = VBoxContainer.new()
	_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_container.add_theme_constant_override("separation", 4)
	scroll.add_child(_list_container)

# ── Build module list ─────────────────────────────────────────────
func _refresh_list() -> void:
	for ch in _list_container.get_children():
		ch.queue_free()
	await get_tree().process_frame

	_metal_lbl.text = "⚙ %d" % GameData.metal_scrap
	_crystal_lbl.text = "  💎 %d" % GameData.void_crystals

	# Sort: researched first, then by research_cost
	var module_ids := GameData.MODULE_DATA.keys()
	module_ids.sort_custom(func(a: String, b: String) -> bool:
		var ra := a in GameData.researched_modules
		var rb := b in GameData.researched_modules
		if ra != rb: return ra
		return GameData.MODULE_DATA[a].get("research_cost", 0) < \
			   GameData.MODULE_DATA[b].get("research_cost", 0)
	)

	for mid in module_ids:
		var mdata: Dictionary = GameData.MODULE_DATA[mid]
		var cat: String = mdata.get("category", "")
		var is_test: bool = mdata.get("is_test", false)
		if is_test:
			# Test modules appear ONLY in the "test" tab, and only in tester mode.
			if _active_cat != "test" or not GameData.tester_mode:
				continue
		else:
			if _active_cat == "test":
				continue
			if _active_cat != "all" and cat != _active_cat:
				continue
		_list_container.add_child(_make_module_row(mid, mdata))
		_list_container.add_child(HSeparator.new())

func _make_module_row(mid: String, mdata: Dictionary) -> HBoxContainer:
	var cat: String       = mdata.get("category", "")
	var researched: bool  = mid in GameData.researched_modules
	var owned_count: int  = GameData.owned_modules.get(mid, 0)
	var res_cost: int     = mdata.get("research_cost", 0)
	var buy_cost: int     = mdata.get("buy_cost", 0)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.custom_minimum_size = Vector2(0, 72)

	# Category swatch
	var swatch := ColorRect.new()
	swatch.color = GameData.CAT_COLORS.get(cat, Color.GRAY)
	swatch.custom_minimum_size = Vector2(7, 0)
	row.add_child(swatch)

	# Module icon (animated ShipDraw graphic)
	var icon: Control = load("res://scripts/module_icon.gd").new()
	icon.set("module_id", mid)
	icon.custom_minimum_size = Vector2(64, 64)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if not researched:
		icon.modulate = Color(1, 1, 1, 0.35)
	row.add_child(icon)

	# Info
	var info_col := VBoxContainer.new()
	info_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_col.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(info_col)

	# Name + lock badge on same line
	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 6)
	info_col.add_child(name_row)

	var name_lbl := Label.new()
	name_lbl.text = mdata.get("name", mid)
	name_lbl.add_theme_font_size_override("font_size", 17)
	if not researched:
		name_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	name_row.add_child(name_lbl)

	var lock_lbl := Label.new()
	lock_lbl.add_theme_font_size_override("font_size", 13)
	lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if researched:
		lock_lbl.text = "🔓"
	else:
		lock_lbl.text = "🔒"
	name_row.add_child(lock_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = mdata.get("desc", "")
	desc_lbl.add_theme_font_size_override("font_size", 12)
	desc_lbl.add_theme_color_override("font_color", Color(0.55, 0.55, 0.65))
	info_col.add_child(desc_lbl)

	# Owned count
	if owned_count > 0:
		var owned_lbl := Label.new()
		owned_lbl.text = "Vlastní: %d" % owned_count
		owned_lbl.add_theme_font_size_override("font_size", 12)
		owned_lbl.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
		info_col.add_child(owned_lbl)

	# Action buttons
	var btn_col := VBoxContainer.new()
	btn_col.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_col.add_theme_constant_override("separation", 4)
	row.add_child(btn_col)

	if not researched:
		var res_btn := Button.new()
		res_btn.text = "Zkoumat\n💎 %d" % res_cost
		res_btn.custom_minimum_size = Vector2(120, 52)
		res_btn.add_theme_font_size_override("font_size", 13)
		res_btn.disabled = not GameData.can_research(mid)
		if not res_btn.disabled:
			res_btn.modulate = Color(0.25, 0.85, 1.00)
		var m: String = mid
		res_btn.pressed.connect(func() -> void: _on_research(m))
		btn_col.add_child(res_btn)
	else:
		var buy_btn := Button.new()
		buy_btn.text = "Koupit\n⚙ %d" % buy_cost
		buy_btn.custom_minimum_size = Vector2(120, 52)
		buy_btn.add_theme_font_size_override("font_size", 13)
		buy_btn.disabled = not GameData.can_buy(mid)
		if not buy_btn.disabled:
			buy_btn.modulate = Color(0.35, 0.90, 0.45)
		var m: String = mid
		buy_btn.pressed.connect(func() -> void: _on_buy(m))
		btn_col.add_child(buy_btn)

	return row

# ── Actions ───────────────────────────────────────────────────────
func _set_category(cat: String) -> void:
	_active_cat = cat
	_refresh_list()

func _on_research(module_id: String) -> void:
	if GameData.research_module(module_id):
		_status_lbl.text = "✓ Vyzkoumal jsi: %s" % GameData.MODULE_DATA[module_id].get("name", module_id)
	else:
		_status_lbl.text = "Nedostatek 💎 void krystalů!"
	_refresh_list()

func _on_buy(module_id: String) -> void:
	if GameData.buy_module(module_id):
		_status_lbl.text = "✓ Koupeno: %s (celkem: %d ks)" % [
			GameData.MODULE_DATA[module_id].get("name", module_id),
			GameData.owned_modules.get(module_id, 0)
		]
	else:
		_status_lbl.text = "Nedostatek ⚙ kovového šrotu!"
	_refresh_list()
