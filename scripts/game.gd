extends Node2D

const PLAYER_SCENE = preload("res://scenes/player.tscn")

@onready var _wave_spawner: Node  = $WaveSpawner
@onready var _hud: CanvasLayer    = $HUD

var _player: CharacterBody2D = null
var _game_over: bool = false
var _paused: bool = false
var _pause_layer: CanvasLayer = null

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

func _ready() -> void:
	_spawn_background()
	GameData.start_run()
	_spawn_player()
	_wave_spawner.wave_started.connect(_hud.update_wave)
	_wave_spawner.wave_completed.connect(_on_wave_completed)
	_wave_spawner.all_waves_completed.connect(_on_victory)
	_wave_spawner.start_waves()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not event.is_echo() and not _game_over:
		_toggle_pause()

func _toggle_pause() -> void:
	_paused = not _paused
	get_tree().paused = _paused
	if _paused:
		_pause_layer = _build_pause_menu()
		add_child(_pause_layer)
	else:
		if is_instance_valid(_pause_layer):
			_pause_layer.queue_free()
		_pause_layer = null

func _process(_delta: float) -> void:
	# Update ability indicator every frame
	if is_instance_valid(_player):
		_hud.update_ability(_player.get_ability_timer(), _player.get_ability_cooldown())

# ── Background ────────────────────────────────────────────────────
func _spawn_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.09)
	bg.size = get_viewport_rect().size
	bg.z_index = -10
	add_child(bg)

	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var sz := get_viewport_rect().size
	for _i in 110:
		var star := ColorRect.new()
		var s := rng.randf_range(1.0, 2.8)
		star.size = Vector2(s, s)
		star.color = Color(1, 1, 1, rng.randf_range(0.15, 0.80))
		star.position = Vector2(rng.randf() * sz.x, rng.randf() * sz.y)
		star.z_index = -9
		add_child(star)

# ── Player ────────────────────────────────────────────────────────
func _spawn_player() -> void:
	_player = PLAYER_SCENE.instantiate()
	var sz := get_viewport_rect().size
	_player.global_position = Vector2(sz.x * 0.5, sz.y - 120.0)
	_player.z_index = 2
	add_child(_player)

	_player.died.connect(_on_player_died)
	_player.hp_changed.connect(_hud.update_hp)
	_player.metal_changed.connect(_hud.update_metal)
	_player.crystals_changed.connect(_hud.update_crystals)

	_hud.update_hp(_player._max_hp, _player._max_hp)

# ── Events ────────────────────────────────────────────────────────
func _on_wave_completed(wave_num: int) -> void:
	print("Vlna %d dokoncena" % wave_num)

func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	_wave_spawner.stop()

	var metal: int    = _player.metal_collected    if is_instance_valid(_player) else 0
	var crystals: int = _player.crystals_collected if is_instance_valid(_player) else 0

	GameData.end_run(false, metal, crystals)
	GameData.save_game()
	await get_tree().create_timer(0.9).timeout
	_hud.show_game_over(false, metal, crystals)

func _on_victory() -> void:
	if _game_over:
		return
	_game_over = true

	var metal: int    = _player.metal_collected    if is_instance_valid(_player) else 0
	var crystals: int = _player.crystals_collected if is_instance_valid(_player) else 0

	GameData.end_run(true, metal, crystals)
	GameData.complete_mission()
	await get_tree().create_timer(1.0).timeout
	_hud.show_game_over(true, metal, crystals)

# ── Pause menu ────────────────────────────────────────────────────────────────
func _build_pause_menu() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.process_mode = Node.PROCESS_MODE_ALWAYS

	# Dim overlay
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.68)
	layer.add_child(dim)

	# Centred panel
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(420, 0)
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "⏸  PAUZA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color(0.25, 0.75, 1.00))
	vbox.add_child(title)

	vbox.add_child(_sep(6))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_sep(4))

	# ── Navigation buttons ────────────────────────────────────────────
	_pause_btn(vbox, "▶   Pokračovat", Color(0.28, 0.82, 0.45),
		func() -> void: _toggle_pause())

	_pause_btn(vbox, "🏠   Zpět do základny", Color(0.30, 0.55, 0.90),
		func() -> void:
			get_tree().paused = false
			get_tree().change_scene_to_file("res://scenes/hub.tscn"))

	vbox.add_child(_sep(2))

	_pause_btn(vbox, "⚙   Nastavení rozlišení", Color(0.55, 0.58, 0.70),
		func() -> void: _open_resolution_menu(layer))

	vbox.add_child(_sep(2))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_sep(2))

	_pause_btn(vbox, "✕   Ukončit hru", Color(0.78, 0.28, 0.28),
		func() -> void: get_tree().quit())

	vbox.add_child(_sep(4))
	vbox.add_child(HSeparator.new())
	vbox.add_child(_sep(4))

	# ── Random tip ────────────────────────────────────────────────────
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

	vbox.add_child(_sep(4))

	return layer


func _pause_btn(parent: VBoxContainer, txt: String, clr: Color, cb: Callable) -> void:
	var btn := Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 54)
	btn.add_theme_font_size_override("font_size", 18)
	btn.modulate = clr
	btn.pressed.connect(cb)
	parent.add_child(btn)


func _sep(h: int) -> Control:
	var s := Control.new()
	s.custom_minimum_size = Vector2(0, h)
	return s


func _open_resolution_menu(layer: CanvasLayer) -> void:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.55)
	layer.add_child(overlay)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical   = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(480, 0)
	layer.add_child(panel)

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

	var resolutions: Array = [
		{"label": "1280 × 720   (HD)",        "size": Vector2i(1280, 720)},
		{"label": "1600 × 900   (HD+)",        "size": Vector2i(1600, 900)},
		{"label": "1920 × 1080  (Full HD)",    "size": Vector2i(1920, 1080)},
		{"label": "2560 × 1440  (2K / QHD)",  "size": Vector2i(2560, 1440)},
		{"label": "3840 × 2160  (4K / UHD)",  "size": Vector2i(3840, 2160)},
	]

	var current_win_size := DisplayServer.window_get_size()
	var is_fs: bool = DisplayServer.window_get_mode() in [
		DisplayServer.WINDOW_MODE_FULLSCREEN,
		DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN]

	for r: Dictionary in resolutions:
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
