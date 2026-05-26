extends Node

const CURSOR_PATH: String = "res://assets/ui/cursor_starship.png"
const CURSOR_HOTSPOT: Vector2 = Vector2(5.0, 5.0)
const CURSOR_SHAPES: Array[int] = [
	Input.CURSOR_ARROW,
	Input.CURSOR_POINTING_HAND,
	Input.CURSOR_DRAG,
	Input.CURSOR_CAN_DROP,
]

var _cursor_texture: Texture2D = null

func _ready() -> void:
	_apply_cursor()

func _apply_cursor() -> void:
	if _cursor_texture == null:
		_cursor_texture = _load_cursor_texture()
	if _cursor_texture == null:
		return
	for cursor_shape: int in CURSOR_SHAPES:
		Input.set_custom_mouse_cursor(_cursor_texture, cursor_shape, CURSOR_HOTSPOT)

func _load_cursor_texture() -> Texture2D:
	var imported_texture: Texture2D = load(CURSOR_PATH) as Texture2D
	if imported_texture != null:
		return imported_texture

	var image: Image = Image.new()
	var err: int = image.load(CURSOR_PATH)
	if err != OK or image.is_empty():
		push_warning("Could not load starship cursor image: %s" % CURSOR_PATH)
		return null
	return ImageTexture.create_from_image(image)
