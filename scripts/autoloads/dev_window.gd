extends Node

const ARCHITECTURE: Array[String] = [
	"Tok hry vede z hlavního menu do základny, přes mapu planet do mise a zpět s výsledky.",
	"GameData drží ukládání, postup hráče, lodě, moduly a ekonomiku.",
	"Obrazovky používají sdílené kreslení lodí a modulů, aby náhledy, hangár i mise držely stejný vizuální styl.",
	"Mise skládá hráče, vlny nepřátel, střely, odměny, HUD a výsledek běhu.",
	"Sběr surovin závisí na cargo a sběračových modulech; sebrané odměny se zapisují do výsledku mise.",
]

const LAST_LOAD_CHANGES: Array[String] = [
	"Projekt jde spustit přímo z Godotu na Windows.",
	"Načítání sdílených herních skriptů je stabilnější.",
	"Bojové objekty a střely mají spolehlivější inicializaci.",
	"Herní assety jsou připravené pro načítání za běhu.",
	"Sběr odměn během mise je stabilnější.",
	"Přibyl vývojářský přehled architektury a posledních obecných změn.",
]

var _layer: CanvasLayer = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F1:
			open()


func is_open() -> bool:
	return is_instance_valid(_layer)


func open() -> void:
	if is_open():
		_close()
		return
	_layer = CanvasLayer.new()
	_layer.layer = 140
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(_layer)
	_build_window()


func _close() -> void:
	if is_instance_valid(_layer):
		_layer.queue_free()
	_layer = null


func _build_window() -> void:
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.72)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(760, 560)
	_layer.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	vbox.add_child(header)

	var title := Label.new()
	title.text = "VÝVOJÁŘSKÝ PŘEHLED"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.25, 0.75, 1.00))
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = "Zavřít"
	close_btn.custom_minimum_size = Vector2(78, 42)
	close_btn.pressed.connect(_close)
	header.add_child(close_btn)

	var hint := Label.new()
	hint.text = "F1 přepíná toto okno. Obsah shrnuje základní architekturu hry a obecné změny od posledního spuštění."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_font_size_override("font_size", 13)
	hint.add_theme_color_override("font_color", Color(0.56, 0.62, 0.74))
	vbox.add_child(hint)

	vbox.add_child(HSeparator.new())
	vbox.add_child(_section("Architektura", ARCHITECTURE))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_section("Obecné změny od posledního spuštění", LAST_LOAD_CHANGES))

	dim.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			_close()
	)

	await get_tree().process_frame
	var vp := get_viewport().get_visible_rect().size
	panel.position = (vp - panel.size) * 0.5


func _section(label: String, items: Array[String]) -> Control:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var heading := Label.new()
	heading.text = label
	heading.add_theme_font_size_override("font_size", 19)
	heading.add_theme_color_override("font_color", Color(0.88, 0.92, 1.00))
	box.add_child(heading)

	for item: String in items:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		box.add_child(row)

		var bullet := Label.new()
		bullet.text = "-"
		bullet.add_theme_font_size_override("font_size", 15)
		bullet.add_theme_color_override("font_color", Color(0.25, 0.75, 1.00))
		row.add_child(bullet)

		var text := Label.new()
		text.text = item
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.add_theme_font_size_override("font_size", 14)
		text.add_theme_color_override("font_color", Color(0.70, 0.75, 0.86))
		row.add_child(text)

	return box
