extends Node

const TIPS: Array = [
	"Void krystaly jsou pozůstatky hvězd, které kolapsovaly před miliony let.",
	"Planeta Glacius je pokryta věčným ledem — přesto zde číhají cenné suroviny.",
	"Naváděné rakety potřebují zlomek sekundy k zacílení. Nespěchej.",
	"Bez motoru se loď nepohne. Motor je základ přežití.",
	"Cargo modul bez sběrače nestačí — suroviny nelze sebrat bez obou součástí.",
	"Vzácní nepřátelé nesou více surovin, ale jsou mnohem odolnější.",
	"Void prostorem se šíří záhadné signály. Nikdo neví, kdo je vysílá.",
	"Minigun má nízké poškození na výstřel, ale v součtu patří k nejsilnějším.",
	"Dash tě na okamžik učiní nezranitelným — využij ho, když jsi obklíčen.",
	"Čím více modulů, tím silnější loď. Hangár je tvůj nejlepší přítel.",
	"Každá mise je jiná. Vlny nepřátel se nikdy neopakují úplně stejně.",
	"Plasma kanon střílí pomalu, ale každá rána pálí. Ideální na vzácné nepřátele.",
	"Spread zbraň pokryje široký úhel — skvělá do hustých vln.",
	"Reflect štít vrací část poškození zpět. Nepřátelé se bojí vlastních střel.",
]

const RESOLUTIONS: Array = [
	{"label": "1280 × 720   (HD)",       "size": Vector2i(1280, 720)},
	{"label": "1600 × 900   (HD+)",       "size": Vector2i(1600, 900)},
	{"label": "1920 × 1080  (Full HD)",   "size": Vector2i(1920, 1080)},
	{"label": "2560 × 1440  (2K / QHD)",  "size": Vector2i(2560, 1440)},
	{"label": "3840 × 2160  (4K / UHD)",  "size": Vector2i(3840, 2160)},
]

var _layer: CanvasLayer = null

func is_open() -> bool:
	return is_instance_valid(_layer)

func open() -> void:
	if is_open():
		_close()
		return
	_layer = CanvasLayer.new()
	_layer.layer = 128
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)
	_build_menu()

func _close() -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null

# ── Main menu ─────────────────────────────────────────────────────────────────

func _build_menu() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	_layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(420, 0)
	_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚙  NASTAVENÍ"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.25, 0.75, 1.00))
	vbox.add_child(title)

	vbox.add_child(_gap(6))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_gap(4))

	_menu_btn(vbox, "▶   Pokračovat", Color(0.28, 0.82, 0.45), _close)

	vbox.add_child(_gap(2))

	_menu_btn(vbox, "⚙   Nastavení rozlišení", Color(0.55, 0.58, 0.70),
		func() -> void: _open_resolution_submenu())

	vbox.add_child(_gap(2))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_gap(2))

	_menu_btn(vbox, "✕   Ukončit hru", Color(0.78, 0.28, 0.28),
		func() -> void: get_tree().quit())

	vbox.add_child(_gap(4))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_gap(4))

	var tip_hbox := HBoxContainer.new()
	tip_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(tip_hbox)

	var tip_icon := Label.new()
	tip_icon.text = "💡"
	tip_icon.add_theme_font_size_override("font_size", 16)
	tip_hbox.add_child(tip_icon)

	var tip_lbl := Label.new()
	tip_lbl.text = TIPS[randi() % TIPS.size()]
	tip_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tip_lbl.add_theme_font_size_override("font_size", 13)
	tip_lbl.add_theme_color_override("font_color", Color(0.52, 0.60, 0.72))
	tip_hbox.add_child(tip_lbl)

	vbox.add_child(_gap(4))

# ── Resolution submenu ────────────────────────────────────────────────────────

func _open_resolution_submenu() -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	_layer.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(480, 0)
	_layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	panel.add_child(vbox)

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

	var current_win_size := DisplayServer.window_get_size()
	var is_fs: bool = DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]

	for r: Dictionary in RESOLUTIONS:
		var btn := Button.new()
		btn.text = r["label"]
		btn.custom_minimum_size = Vector2(0, 50)
		btn.add_theme_font_size_override("font_size", 17)
		if (not is_fs) and current_win_size == r["size"]:
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

	var fs_btn := Button.new()
	fs_btn.text = "⛶   Celá obrazovka (Fullscreen)"
	fs_btn.custom_minimum_size = Vector2(0, 50)
	fs_btn.add_theme_font_size_override("font_size", 17)
	if is_fs:
		fs_btn.modulate = Color(0.28, 0.82, 1.00)
	fs_btn.pressed.connect(func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		overlay.queue_free()
		panel.queue_free())
	vbox.add_child(fs_btn)

# ── Helpers ───────────────────────────────────────────────────────────────────

func _menu_btn(parent: VBoxContainer, txt: String, clr: Color, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 54)
	btn.add_theme_font_size_override("font_size", 18)
	btn.modulate = clr
	btn.pressed.connect(cb)
	parent.add_child(btn)

func _gap(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s
