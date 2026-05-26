extends Node2D

const SCROLL_SPEED: float = 58.0
const STAR_COUNT: int = 110
const BIOME_PARTICLE_COUNT: int = 34
const STAR_SEED: int = 12345
const PLANET_SEEDS: Dictionary = {
	"glacius": 3101,
	"infernus": 4201,
	"toxar": 5301,
	"shadowveil": 6401,
	"void_station": 7501,
}

var _scroll: float = 0.0
var _tile_size: Vector2 = Vector2.ZERO
var _stars: Array[Dictionary] = []
var _biome_particles: Array[Dictionary] = []
var _planet_id: String = "glacius"
var _mission_idx: int = 0
var _accent_color: Color = Color(0.20, 0.65, 1.00)
var _base_color: Color = Color(0.02, 0.02, 0.09)
var _secondary_color: Color = Color(0.62, 0.86, 1.00)
var _haze_color: Color = Color(0.12, 0.42, 0.74)

func configure(planet_id: String, mission_idx: int, accent_color: Color) -> void:
	_planet_id = planet_id
	_mission_idx = mission_idx
	_accent_color = accent_color
	_apply_planet_theme()
	if is_inside_tree():
		_rebuild_tile()

func _ready() -> void:
	z_index = -10
	_apply_planet_theme()
	_rebuild_tile()

func _process(delta: float) -> void:
	if get_viewport_rect().size != _tile_size:
		_rebuild_tile()

	if _tile_size.y <= 0.0:
		return

	_scroll = fmod(_scroll + SCROLL_SPEED * delta, _tile_size.y)
	queue_redraw()

func _draw() -> void:
	var sz: Vector2 = get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, sz), _base_color)
	_draw_biome_backdrop(sz)

	for offset_y: float in [-_tile_size.y, 0.0]:
		var offset: Vector2 = Vector2(0.0, offset_y + _scroll)
		_draw_star_tile(offset)
		_draw_biome_tile(offset)

func _apply_planet_theme() -> void:
	match _planet_id:
		"glacius":
			_base_color = Color(0.015, 0.027, 0.070)
			_secondary_color = Color(0.68, 0.90, 1.00)
			_haze_color = Color(0.10, 0.48, 0.88)
		"infernus":
			_base_color = Color(0.070, 0.023, 0.015)
			_secondary_color = Color(1.00, 0.55, 0.16)
			_haze_color = Color(0.82, 0.16, 0.06)
		"toxar":
			_base_color = Color(0.020, 0.052, 0.030)
			_secondary_color = Color(0.52, 1.00, 0.22)
			_haze_color = Color(0.20, 0.72, 0.16)
		"shadowveil":
			_base_color = Color(0.018, 0.012, 0.035)
			_secondary_color = Color(0.78, 0.34, 1.00)
			_haze_color = Color(0.30, 0.08, 0.56)
		"void_station":
			_base_color = Color(0.018, 0.020, 0.030)
			_secondary_color = Color(0.72, 0.86, 1.00)
			_haze_color = Color(0.18, 0.25, 0.38)
		_:
			_base_color = Color(0.02, 0.02, 0.09)
			_secondary_color = _accent_color.lerp(Color.WHITE, 0.35)
			_haze_color = _accent_color

func _rebuild_tile() -> void:
	_tile_size = get_viewport_rect().size
	_scroll = 0.0
	_stars.clear()
	_biome_particles.clear()

	var seed_base: int = int(PLANET_SEEDS.get(_planet_id, STAR_SEED)) + _mission_idx * 101
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_base
	for _i: int in STAR_COUNT:
		var s: float = rng.randf_range(1.0, 2.8)
		var alpha: float = rng.randf_range(0.14, 0.74)
		var pos: Vector2 = Vector2(rng.randf() * _tile_size.x, rng.randf() * _tile_size.y)
		var star_col: Color = Color.WHITE.lerp(_accent_color, rng.randf_range(0.0, 0.32))
		star_col.a = alpha
		_stars.append({
			"position": pos,
			"size": Vector2(s, s),
			"color": star_col,
		})

	for _i: int in _biome_particle_count():
		_biome_particles.append({
			"position": Vector2(rng.randf() * _tile_size.x, rng.randf() * _tile_size.y),
			"size": rng.randf_range(3.0, 10.0 + float(_mission_idx) * 1.4),
			"alpha": rng.randf_range(0.10, 0.32),
			"drift": rng.randf_range(0.0, TAU),
		})

	queue_redraw()

func _biome_particle_count() -> int:
	match _planet_id:
		"void_station":
			return 24
		"shadowveil":
			return 30
		_:
			return BIOME_PARTICLE_COUNT

func _draw_biome_backdrop(sz: Vector2) -> void:
	var mission_alpha: float = 0.035 + float(_mission_idx) * 0.006
	draw_circle(Vector2(sz.x * 0.22, sz.y * 0.24), sz.x * 0.34,
		Color(_haze_color.r, _haze_color.g, _haze_color.b, mission_alpha))
	draw_circle(Vector2(sz.x * 0.78, sz.y * 0.62), sz.x * 0.30,
		Color(_accent_color.r, _accent_color.g, _accent_color.b, mission_alpha * 0.72))

	match _planet_id:
		"glacius":
			_draw_frost_lanes(sz)
		"infernus":
			_draw_heat_streaks(sz)
		"void_station":
			_draw_station_grid(sz)

func _draw_frost_lanes(sz: Vector2) -> void:
	for i: int in 4:
		var y: float = fmod(float(i) * sz.y * 0.28 + _scroll * 0.30, sz.y)
		draw_line(Vector2(0.0, y), Vector2(sz.x, y - sz.x * 0.06),
			Color(0.66, 0.90, 1.00, 0.050), 2.0)

func _draw_heat_streaks(sz: Vector2) -> void:
	for i: int in 5:
		var y: float = fmod(float(i) * sz.y * 0.23 + _scroll * 0.42, sz.y)
		draw_line(Vector2(sz.x * 0.10, y + 70.0), Vector2(sz.x * 0.88, y - 20.0),
			Color(1.00, 0.30, 0.08, 0.045), 3.0)

func _draw_station_grid(sz: Vector2) -> void:
	var spacing: float = 92.0
	var offset: float = fmod(_scroll * 0.45, spacing)
	var col: Color = Color(_secondary_color.r, _secondary_color.g, _secondary_color.b, 0.055)
	var x: float = -spacing + offset
	while x < sz.x + spacing:
		draw_line(Vector2(x, 0.0), Vector2(x + sz.y * 0.16, sz.y), col, 1.0)
		x += spacing
	var y: float = -spacing + offset
	while y < sz.y + spacing:
		draw_line(Vector2(0.0, y), Vector2(sz.x, y + sz.x * 0.08), col, 1.0)
		y += spacing

func _draw_star_tile(offset: Vector2) -> void:
	for star: Dictionary in _stars:
		draw_rect(Rect2(star["position"] + offset, star["size"]), star["color"])

func _draw_biome_tile(offset: Vector2) -> void:
	for particle: Dictionary in _biome_particles:
		var pos: Vector2 = particle["position"] + offset
		var size: float = float(particle["size"])
		var alpha: float = float(particle["alpha"])
		var drift: float = float(particle["drift"])
		pos.x += sin((_scroll + pos.y) * 0.016 + drift) * 7.0
		var col: Color = Color(_secondary_color.r, _secondary_color.g, _secondary_color.b, alpha)
		match _planet_id:
			"glacius":
				_draw_ice_shard(pos, size, col)
			"infernus":
				_draw_ember(pos, size, col)
			"toxar":
				_draw_spore(pos, size, col)
			"shadowveil":
				_draw_shadow_mote(pos, size, col, drift)
			"void_station":
				_draw_station_panel(pos, size, col)
			_:
				draw_circle(pos, size * 0.45, col)

func _draw_ice_shard(pos: Vector2, size: float, col: Color) -> void:
	var fill: Color = Color(col.r, col.g, col.b, col.a * 0.42)
	var points: PackedVector2Array = PackedVector2Array([
		pos + Vector2(0.0, -size),
		pos + Vector2(size * 0.42, 0.0),
		pos + Vector2(0.0, size),
		pos + Vector2(-size * 0.42, 0.0),
	])
	draw_polygon(points, PackedColorArray([fill]))
	draw_polyline(PackedVector2Array([points[0], points[1], points[2], points[3], points[0]]), col, 1.0)

func _draw_ember(pos: Vector2, size: float, col: Color) -> void:
	draw_circle(pos, size * 0.36, Color(col.r, col.g * 0.72, col.b * 0.42, col.a))
	draw_line(pos + Vector2(-size * 0.35, size * 0.75), pos + Vector2(size * 0.35, -size * 0.95),
		Color(1.00, 0.74, 0.18, col.a * 0.55), 1.3)

func _draw_spore(pos: Vector2, size: float, col: Color) -> void:
	draw_circle(pos, size * 0.48, Color(col.r, col.g, col.b, col.a * 0.46))
	draw_arc(pos, size * 0.82, 0.0, TAU, 18, Color(col.r, col.g, col.b, col.a * 0.70), 1.0)

func _draw_shadow_mote(pos: Vector2, size: float, col: Color, drift: float) -> void:
	draw_circle(pos, size * 0.52, Color(0.02, 0.01, 0.04, col.a * 0.70))
	draw_arc(pos, size * 0.92, drift, drift + PI * 1.15, 14,
		Color(col.r, col.g, col.b, col.a * 0.72), 1.2)

func _draw_station_panel(pos: Vector2, size: float, col: Color) -> void:
	var rect: Rect2 = Rect2(pos - Vector2(size * 1.35, size * 0.45), Vector2(size * 2.70, size * 0.90))
	draw_rect(rect, Color(0.08, 0.10, 0.14, col.a * 0.58))
	draw_rect(rect, Color(col.r, col.g, col.b, col.a * 0.82), false, 1.0)
