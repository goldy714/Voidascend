extends Node

const CURSOR_MODE_STARSHIP: String = "starship"
const CURSOR_MODE_CROSSHAIR: String = "crosshair"
const STARSHIP_CURSOR_PATH: String = "res://assets/ui/cursor_starship.png"
const CROSSHAIR_CURSOR_PATH: String = "res://assets/ui/cursor_crosshair.png"
const STARSHIP_HOTSPOT: Vector2 = Vector2(10.0, 10.0)
const CROSSHAIR_HOTSPOT: Vector2 = Vector2(32.0, 32.0)
const STARSHIP_FORWARD_ANGLE: float = -2.356194490192345
const CURSOR_LAYER: int = 128
const CURSOR_MIN_MOVE_DISTANCE: float = 1.2
const CURSOR_ROTATION_SPEED: float = 18.0
const STARSHIP_SCALE: float = 0.88
const CROSSHAIR_SCALE: float = 0.5
const TRAIL_GHOST_COUNT: int = 6
const TRAIL_LIFETIME: float = 0.20
const TRAIL_SAMPLE_INTERVAL: float = 0.025
const TRAIL_START_ALPHA: float = 0.28
const TRAIL_END_ALPHA: float = 0.04

var _cursor_layer: CanvasLayer = null
var _cursor_sprite: Sprite2D = null
var _trail_sprites: Array[Sprite2D] = []
var _cursor_mode: String = CURSOR_MODE_STARSHIP
var _texture_cache: Dictionary = {}
var _has_mouse_position: bool = false
var _last_mouse_position: Vector2 = Vector2.ZERO
var _target_rotation: float = 0.0
var _trail_positions: Array[Vector2] = []
var _trail_rotations: Array[float] = []
var _trail_ages: Array[float] = []
var _trail_sample_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_cursor_overlay()
	_apply_cursor_mode()
	set_process(true)

func use_starship_cursor() -> void:
	_set_cursor_mode(CURSOR_MODE_STARSHIP)

func use_crosshair_cursor() -> void:
	_set_cursor_mode(CURSOR_MODE_CROSSHAIR)

func _set_cursor_mode(mode: String) -> void:
	if _cursor_mode == mode and _cursor_sprite != null:
		return
	_cursor_mode = mode
	_has_mouse_position = false
	_target_rotation = 0.0
	_clear_trail()
	_apply_cursor_mode()

func _process(delta: float) -> void:
	if _cursor_sprite == null:
		return

	var mouse_position: Vector2 = get_viewport().get_mouse_position()
	_cursor_sprite.position = mouse_position

	if _cursor_mode == CURSOR_MODE_CROSSHAIR:
		_cursor_sprite.rotation = 0.0
		_last_mouse_position = mouse_position
		_has_mouse_position = true
		_clear_trail()
		return

	_update_trail(delta)
	if not _has_mouse_position:
		_has_mouse_position = true
		_last_mouse_position = mouse_position
		return

	var movement: Vector2 = mouse_position - _last_mouse_position
	if movement.length() >= CURSOR_MIN_MOVE_DISTANCE:
		_target_rotation = movement.angle() - STARSHIP_FORWARD_ANGLE
		_trail_sample_timer += delta
		if _trail_sample_timer >= TRAIL_SAMPLE_INTERVAL:
			_add_trail_sample(_last_mouse_position, _cursor_sprite.rotation)
			_trail_sample_timer = 0.0
	_last_mouse_position = mouse_position

	_cursor_sprite.rotation = lerp_angle(
		_cursor_sprite.rotation,
		_target_rotation,
		clampf(delta * CURSOR_ROTATION_SPEED, 0.0, 1.0)
	)

func _build_cursor_overlay() -> void:
	_cursor_layer = CanvasLayer.new()
	_cursor_layer.layer = CURSOR_LAYER
	_cursor_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_cursor_layer)

	for _i: int in range(TRAIL_GHOST_COUNT):
		var ghost: Sprite2D = Sprite2D.new()
		ghost.centered = false
		ghost.visible = false
		ghost.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		_cursor_layer.add_child(ghost)
		_trail_sprites.append(ghost)

	_cursor_sprite = Sprite2D.new()
	_cursor_sprite.centered = false
	_cursor_sprite.position = get_viewport().get_mouse_position()
	_cursor_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_cursor_layer.add_child(_cursor_sprite)

func _apply_cursor_mode() -> void:
	if _cursor_sprite == null:
		return
	var cursor_texture: Texture2D = _load_cursor_texture(_cursor_path())
	if cursor_texture == null:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		return
	_cursor_sprite.texture = cursor_texture
	_cursor_sprite.offset = -_cursor_hotspot()
	var cursor_scale: float = _cursor_scale()
	_cursor_sprite.scale = Vector2(cursor_scale, cursor_scale)
	_cursor_sprite.rotation = 0.0
	_apply_trail_texture(cursor_texture)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _apply_trail_texture(cursor_texture: Texture2D) -> void:
	var use_trail: bool = _cursor_mode == CURSOR_MODE_STARSHIP
	for ghost: Sprite2D in _trail_sprites:
		ghost.texture = cursor_texture if use_trail else null
		ghost.offset = -STARSHIP_HOTSPOT
		ghost.visible = false

func _add_trail_sample(position: Vector2, rotation: float) -> void:
	if _cursor_mode != CURSOR_MODE_STARSHIP:
		return
	_trail_positions.push_front(position)
	_trail_rotations.push_front(rotation)
	_trail_ages.push_front(0.0)
	while _trail_positions.size() > TRAIL_GHOST_COUNT:
		_trail_positions.pop_back()
		_trail_rotations.pop_back()
		_trail_ages.pop_back()
	_refresh_trail_sprites()

func _update_trail(delta: float) -> void:
	for i: int in range(_trail_ages.size() - 1, -1, -1):
		_trail_ages[i] = _trail_ages[i] + delta
		if _trail_ages[i] > TRAIL_LIFETIME:
			_trail_positions.remove_at(i)
			_trail_rotations.remove_at(i)
			_trail_ages.remove_at(i)
	_refresh_trail_sprites()

func _refresh_trail_sprites() -> void:
	for i: int in range(_trail_sprites.size()):
		var ghost: Sprite2D = _trail_sprites[i]
		if _cursor_mode != CURSOR_MODE_STARSHIP or i >= _trail_positions.size():
			ghost.visible = false
			continue
		var age_ratio: float = clampf(_trail_ages[i] / TRAIL_LIFETIME, 0.0, 1.0)
		var depth_ratio: float = 1.0 - float(i) / float(TRAIL_GHOST_COUNT)
		var alpha: float = lerpf(TRAIL_START_ALPHA, TRAIL_END_ALPHA, age_ratio) * depth_ratio
		var ghost_scale: float = STARSHIP_SCALE * (0.96 - float(i) * 0.045)
		ghost.position = _trail_positions[i]
		ghost.rotation = _trail_rotations[i]
		ghost.scale = Vector2(ghost_scale, ghost_scale)
		ghost.modulate = Color(0.55, 0.82, 1.0, alpha)
		ghost.visible = alpha > 0.015

func _clear_trail() -> void:
	_trail_positions.clear()
	_trail_rotations.clear()
	_trail_ages.clear()
	_trail_sample_timer = 0.0
	for ghost: Sprite2D in _trail_sprites:
		ghost.visible = false

func _cursor_path() -> String:
	if _cursor_mode == CURSOR_MODE_CROSSHAIR:
		return CROSSHAIR_CURSOR_PATH
	return STARSHIP_CURSOR_PATH

func _cursor_hotspot() -> Vector2:
	if _cursor_mode == CURSOR_MODE_CROSSHAIR:
		return CROSSHAIR_HOTSPOT
	return STARSHIP_HOTSPOT

func _cursor_scale() -> float:
	if _cursor_mode == CURSOR_MODE_CROSSHAIR:
		return CROSSHAIR_SCALE
	return STARSHIP_SCALE

func _load_cursor_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	var imported_texture: Texture2D = load(path) as Texture2D
	if imported_texture != null:
		_texture_cache[path] = imported_texture
		return imported_texture

	var image: Image = Image.new()
	var err: int = image.load(path)
	if err != OK or image.is_empty():
		push_warning("Could not load cursor image: %s" % path)
		return null
	var image_texture: Texture2D = ImageTexture.create_from_image(image)
	_texture_cache[path] = image_texture
	return image_texture
