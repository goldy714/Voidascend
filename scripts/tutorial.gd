extends CanvasLayer

# arm_target is normalized (0..1) relative to viewport — converted in _show_step.
const STEPS: Array[Dictionary] = [
	{
		"title":      "Vítej, pilote! 👋",
		"body":       "Jsem Zyx, tvůj navigátor.\nPostarám se, aby tě první mise nepřekvapila.\nDovolte mi ukázat, jak fungují moduly lodi.",
		"cat":        "",
		"cat_color":  Color(0.30, 0.55, 0.90),
		"cat_emoji":  "🛸",
		"cat_name":   "Modulový systém",
		"arm_target": Vector2(0.48, 0.30),
		"expression": 2,
	},
	{
		"title":      "⚔️  Zbraně",
		"body":       "Automaticky střílí na nepřátele — žádné tlačítko.\nČím více zbraní nainstalujete, tím vyšší firepower.\nAle zbraně zabírají drahé sloty jiným modulům!",
		"cat":        "weapon",
		"cat_color":  Color(0.85, 0.20, 0.20),
		"cat_emoji":  "⚔️",
		"cat_name":   "Zbraně",
		"arm_target": Vector2(0.30, 0.50),
		"expression": 0,
	},
	{
		"title":      "🚀  Motory",
		"body":       "Bez motoru se loď NEPOHNE.\nVždy nainstaluj aspoň jeden — je to základ přežití.\nSilnější motor = vyšší rychlost = snazší uhýbání.",
		"cat":        "engine",
		"cat_color":  Color(0.95, 0.50, 0.10),
		"cat_emoji":  "🚀",
		"cat_name":   "Motory",
		"arm_target": Vector2(0.30, 0.50),
		"expression": 1,
	},
	{
		"title":      "🛡️  Štíty",
		"body":       "Přidají extra HP a pasivní obranu.\nOdrazový štít vrací nepřátelské střely zpět!\nKombinace štítu s léčením je základ tankování.",
		"cat":        "shield",
		"cat_color":  Color(0.20, 0.50, 0.95),
		"cat_emoji":  "🛡️",
		"cat_name":   "Štíty",
		"arm_target": Vector2(0.30, 0.50),
		"expression": 0,
	},
	{
		"title":      "🦾  Sběrači  &  📦  Náklad",
		"body":       "Oba moduly musíš mít, jinak nesebereš nic!\nSběrač bez nákladu = suroviny padají k zemi.\nNáklad bez sběrače = ani nedosáhneš na ně.",
		"cat":        "collector",
		"cat_color":  Color(0.80, 0.70, 0.10),
		"cat_emoji":  "🦾",
		"cat_name":   "Sběrači + Náklad",
		"arm_target": Vector2(0.30, 0.50),
		"expression": 1,
	},
	{
		"title":      "⚡  Speciální moduly",
		"body":       "Aktivní schopnosti — aktivuj je mezerníkem v boji.\nTime Slow, EMP, Repair unit, Bojová stíhačka...\nMají cooldown, takže načasování je klíčové!",
		"cat":        "special",
		"cat_color":  Color(0.70, 0.20, 0.90),
		"cat_emoji":  "⚡",
		"cat_name":   "Speciální",
		"arm_target": Vector2(0.30, 0.50),
		"expression": 0,
	},
	{
		"title":      "Připraven k boji! 🚀",
		"body":       "Teď víš vše o modulech.\nSestav loď v Hangáru, vyzkumej nové moduly v Obchodě\na vydej se na první misi na planetě Glacius. Hodně štěstí!",
		"cat":        "",
		"cat_color":  Color(0.28, 0.88, 0.42),
		"cat_emoji":  "✓",
		"cat_name":   "Připraven!",
		"arm_target": Vector2(0.60, 0.20),
		"expression": 2,
	},
]

const PANEL_BG := Color(0.11, 0.13, 0.21, 0.97)

var _step: int = 0
var _char_draw: Control
var _cat_panel: PanelContainer
var _cat_emoji_lbl: Label
var _cat_name_lbl: Label
var _title_lbl: Label
var _body_lbl: Label
var _step_lbl: Label
var _back_btn: Button
var _next_btn: Button

func _ready() -> void:
	# Dim overlay
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.74)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Character + tail drawer
	_char_draw = load("res://scripts/tutorial_draw.gd").new()
	_char_draw.set_anchors_preset(Control.PRESET_FULL_RECT)
	_char_draw.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_char_draw)

	_build_bubble()
	_show_step(0)

# ── Speech bubble ─────────────────────────────────────────────

func _build_bubble() -> void:
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var bubble := PanelContainer.new()
	bubble.anchor_left   = 0.0
	bubble.anchor_right  = 1.0
	bubble.anchor_top    = 0.0
	bubble.anchor_bottom = 1.0
	bubble.offset_left   = vp.x * 0.16
	bubble.offset_right  = -20.0
	bubble.offset_top    = vp.y * 0.49
	bubble.offset_bottom = -55.0

	var sty := StyleBoxFlat.new()
	sty.bg_color = PANEL_BG
	sty.border_color = Color(0.28, 0.35, 0.58, 0.90)
	sty.set_border_width_all(2)
	sty.set_corner_radius_all(14)
	bubble.add_theme_stylebox_override("panel", sty)
	add_child(bubble)

	var margin := MarginContainer.new()
	for s: String in ["left","right","top","bottom"]:
		margin.add_theme_constant_override("margin_" + s, 20)
	bubble.add_child(margin)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	margin.add_child(hbox)

	# ── Left: category card ───────────────────────────────────────
	_cat_panel = PanelContainer.new()
	_cat_panel.custom_minimum_size = Vector2(220, 0)
	hbox.add_child(_cat_panel)

	var cat_vbox := VBoxContainer.new()
	cat_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	cat_vbox.add_theme_constant_override("separation", 8)
	_cat_panel.add_child(cat_vbox)

	_cat_emoji_lbl = Label.new()
	_cat_emoji_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cat_emoji_lbl.add_theme_font_size_override("font_size", 52)
	cat_vbox.add_child(_cat_emoji_lbl)

	_cat_name_lbl = Label.new()
	_cat_name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cat_name_lbl.add_theme_font_size_override("font_size", 17)
	cat_vbox.add_child(_cat_name_lbl)

	# ── Divider ───────────────────────────────────────────────────
	var div := VSeparator.new()
	hbox.add_child(div)

	# ── Right: text + nav ─────────────────────────────────────────
	var right_vbox := VBoxContainer.new()
	right_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_vbox.add_theme_constant_override("separation", 10)
	hbox.add_child(right_vbox)

	_title_lbl = Label.new()
	_title_lbl.add_theme_font_size_override("font_size", 32)
	_title_lbl.add_theme_color_override("font_color", Color(0.90, 0.93, 1.00))
	right_vbox.add_child(_title_lbl)

	_body_lbl = Label.new()
	_body_lbl.add_theme_font_size_override("font_size", 17)
	_body_lbl.add_theme_color_override("font_color", Color(0.70, 0.74, 0.88))
	_body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_vbox.add_child(_body_lbl)

	# Nav row
	var nav := HBoxContainer.new()
	nav.add_theme_constant_override("separation", 10)
	right_vbox.add_child(nav)

	_step_lbl = Label.new()
	_step_lbl.add_theme_font_size_override("font_size", 14)
	_step_lbl.add_theme_color_override("font_color", Color(0.40, 0.44, 0.58))
	nav.add_child(_step_lbl)

	var skip_btn := Button.new()
	skip_btn.text = "Přeskočit"
	skip_btn.add_theme_font_size_override("font_size", 14)
	skip_btn.modulate = Color(0.50, 0.52, 0.62)
	skip_btn.pressed.connect(_finish)
	nav.add_child(skip_btn)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav.add_child(spacer)

	_back_btn = Button.new()
	_back_btn.text = "← Zpět"
	_back_btn.custom_minimum_size = Vector2(110, 44)
	_back_btn.add_theme_font_size_override("font_size", 16)
	_back_btn.pressed.connect(_prev_step)
	nav.add_child(_back_btn)

	_next_btn = Button.new()
	_next_btn.custom_minimum_size = Vector2(130, 44)
	_next_btn.add_theme_font_size_override("font_size", 16)
	_next_btn.pressed.connect(_next_step)
	nav.add_child(_next_btn)

# ── Step logic ────────────────────────────────────────────────

func _show_step(n: int) -> void:
	_step = n
	var s: Dictionary = STEPS[n]
	var col: Color = s["cat_color"]

	# Update character
	var vp: Vector2 = get_viewport().get_visible_rect().size
	var norm: Vector2 = s["arm_target"]
	_char_draw.arm_target = Vector2(norm.x * vp.x, norm.y * vp.y)
	_char_draw.expression = s["expression"]
	_char_draw.queue_redraw()

	# Category card
	_cat_emoji_lbl.text = s["cat_emoji"]
	_cat_name_lbl.text  = s["cat_name"]
	_cat_name_lbl.add_theme_color_override("font_color", col)

	var cat_sty := StyleBoxFlat.new()
	cat_sty.bg_color = Color(col.r * 0.14, col.g * 0.14, col.b * 0.16, 0.95)
	cat_sty.border_color = Color(col.r, col.g, col.b, 0.70)
	cat_sty.set_border_width_all(2)
	cat_sty.set_corner_radius_all(10)
	_cat_panel.add_theme_stylebox_override("panel", cat_sty)

	# Text
	_title_lbl.text = s["title"]
	_body_lbl.text  = s["body"]
	_step_lbl.text  = "%d / %d" % [n + 1, STEPS.size()]

	# Buttons
	_back_btn.visible = n > 0
	if n == STEPS.size() - 1:
		_next_btn.text    = "Hotovo  ✓"
		_next_btn.modulate = Color(0.28, 0.88, 0.42)
	else:
		_next_btn.text    = "Další  →"
		_next_btn.modulate = Color(0.30, 0.65, 1.00)

func _next_step() -> void:
	if _step >= STEPS.size() - 1:
		_finish()
	else:
		_show_step(_step + 1)

func _prev_step() -> void:
	if _step > 0:
		_show_step(_step - 1)

func _finish() -> void:
	GameData.tutorial_done = true
	GameData.save_game()
	queue_free()
