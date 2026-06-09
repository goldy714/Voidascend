class_name ProjectileExplosion
extends Node2D

const FX_DIR: String = "res://assets/fx"
const FRAME_TIME: float = 0.045
const MAX_FRAMES: int = 8
const VALID_SIZES := ["small", "medium", "large"]

static var _texture_cache: Dictionary = {}

var effect_size: String = "small"
var _frames: Array = []
var _age: float = 0.0


func setup(origin: Vector2, requested_size: String) -> void:
	global_position = origin
	effect_size = requested_size if requested_size in VALID_SIZES else "small"


func _ready() -> void:
	z_as_relative = false
	z_index = 105
	_frames = _load_frames(effect_size)
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_age += delta
	var frame_count: int = _frames.size()
	if frame_count <= 0:
		frame_count = MAX_FRAMES
	var life: float = FRAME_TIME * float(frame_count)
	if _age >= life:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _frames.is_empty():
		_draw_fallback()
		return

	var frame_index: int = clamp(int(_age / FRAME_TIME), 0, _frames.size() - 1)
	var texture: Texture2D = _frames[frame_index] as Texture2D
	var texture_size: Vector2 = texture.get_size()
	draw_texture_rect(texture, Rect2(texture_size * -0.5, texture_size), false)


func _draw_fallback() -> void:
	var t: float = clamp(_age / (FRAME_TIME * float(MAX_FRAMES)), 0.0, 1.0)
	var scales := {
		"small": 0.55,
		"medium": 0.85,
		"large": 1.15,
	}
	var size_scale: float = float(scales.get(effect_size, 0.55))
	var alpha: float = 1.0 - t
	draw_circle(Vector2.ZERO, lerp(5.0, 23.0, t) * size_scale,
		Color(1.0, 0.26, 0.02, 0.45 * alpha))
	draw_circle(Vector2.ZERO, lerp(2.0, 9.0, t) * size_scale,
		Color(1.0, 0.82, 0.22, 0.76 * alpha))


static func _load_frames(size_name: String) -> Array:
	var frames: Array = []
	for i: int in MAX_FRAMES:
		var texture: Texture2D = null
		for path: String in [
			"%s/projectile_explosion_%s_%02d.png" % [FX_DIR, size_name, i],
			"%s/projectile_explosion_%s_%d.png" % [FX_DIR, size_name, i],
		]:
			texture = _load_texture(path)
			if texture != null:
				break
		if texture != null:
			frames.append(texture)
	return frames


static func _load_texture(path: String) -> Texture2D:
	if _texture_cache.has(path):
		return _texture_cache[path] as Texture2D

	var texture: Texture2D = null
	if ResourceLoader.exists(path, "Texture2D"):
		texture = load(path) as Texture2D
	elif FileAccess.file_exists(path):
		var image: Image = Image.new()
		var err: int = image.load(path)
		if err == OK and not image.is_empty():
			texture = ImageTexture.create_from_image(image)

	_texture_cache[path] = texture
	return texture
