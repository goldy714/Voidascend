extends Node2D

const SCROLL_SPEED := 58.0
const STAR_COUNT := 110
const STAR_SEED := 12345

var _scroll: float = 0.0
var _tile_size: Vector2 = Vector2.ZERO
var _stars: Array[Dictionary] = []


func _ready() -> void:
	z_index = -10
	_rebuild_tile()


func _process(delta: float) -> void:
	if get_viewport_rect().size != _tile_size:
		_rebuild_tile()

	if _tile_size.y <= 0.0:
		return

	_scroll = fmod(_scroll + SCROLL_SPEED * delta, _tile_size.y)
	queue_redraw()


func _draw() -> void:
	var sz := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.02, 0.02, 0.09))

	for offset_y in [-_tile_size.y, 0.0]:
		_draw_star_tile(Vector2(0.0, offset_y + _scroll))


func _rebuild_tile() -> void:
	_tile_size = get_viewport_rect().size
	_scroll = 0.0
	_stars.clear()

	var rng := RandomNumberGenerator.new()
	rng.seed = STAR_SEED
	for _i in STAR_COUNT:
		var s := rng.randf_range(1.0, 2.8)
		var alpha := rng.randf_range(0.15, 0.80)
		var pos := Vector2(rng.randf() * _tile_size.x, rng.randf() * _tile_size.y)
		_stars.append({
			"position": pos,
			"size": Vector2(s, s),
			"color": Color(1, 1, 1, alpha),
		})

	queue_redraw()


func _draw_star_tile(offset: Vector2) -> void:
	for star: Dictionary in _stars:
		draw_rect(Rect2(star["position"] + offset, star["size"]), star["color"])
