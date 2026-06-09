extends CharacterBody2D

signal died(position: Vector2, metal: int, crystals: int)

@export var move_speed: float = 86.0
@export var max_hp: int = 22
@export var shoot_interval: float = 2.35
@export var projectile_damage: int = 6
@export var projectile_speed: float = 230.0
@export var metal_drop: int = 7
@export var crystal_drop: int = 0
@export var sprite_modulate: Color = Color.WHITE

const BULLET_SCENE = preload("res://scenes/bullet_enemy.tscn")
const ENEMY_ART_DIR: String = "res://assets/enemies"
const CONTACT_DAMAGE: int = 12
const CONTACT_INTERVAL: float = 0.9
const EDGE_PADDING: float = 48.0
const BATTLEFIELD_TOP_PADDING: float = 92.0
const BATTLEFIELD_BOTTOM_PADDING: float = 90.0
const SWARM_FOLLOW_MIN_DISTANCE: float = 170.0
const SWARM_FOLLOW_DISTANCE: float = 220.0
const SWARM_FOLLOW_UPDATE_INTERVAL: float = 0.22
const SWARM_SPEED_MIN: float = 0.80
const SWARM_SPEED_MAX: float = 1.08
const SPRITE_SCALE: float = 0.78
const BODY_RADIUS: float = 26.0
const MOVE_FRAME_TIME: float = 0.085
const MOVE_MAX_FRAMES: int = 9

static var _swarm_targets: Dictionary = {}
static var _swarm_target_update_at: Dictionary = {}
static var _swarm_speed_mults: Dictionary = {}
static var _swarm_member_counts: Dictionary = {}
static var _texture_cache: Dictionary = {}

var _hp: int
var _shoot_timer: float
var _contact_timer: float = 0.0
var _player_touching: bool = false
var _target_marked: bool = false
var _target_damage_mult: float = 1.0
var _entered_screen: bool = false
var _swarm_id: String = ""
var _swarm_offset: Vector2 = Vector2.ZERO
var _entry_target: Vector2 = Vector2.ZERO
var _dying: bool = false
var _sprite: Sprite2D = null
var _move_frames: Array = []
var _animation_offset_msec: int = 0


func configure_swarm(
	swarm_id: String,
	swarm_offset: Vector2,
	initial_center: Vector2,
	entry_target_value: Variant = null
) -> void:
	_swarm_id = swarm_id
	_swarm_offset = swarm_offset
	if entry_target_value is Vector2:
		_entry_target = entry_target_value
	else:
		_entry_target = initial_center + swarm_offset
	if not _swarm_targets.has(_swarm_id):
		_swarm_targets[_swarm_id] = initial_center
		_swarm_target_update_at[_swarm_id] = 0
		_swarm_speed_mults[_swarm_id] = randf_range(SWARM_SPEED_MIN, SWARM_SPEED_MAX)


func _ready() -> void:
	if _swarm_id.is_empty():
		configure_swarm("harvester_solo_%d" % get_instance_id(), Vector2.ZERO, global_position)

	_swarm_member_counts[_swarm_id] = int(_swarm_member_counts.get(_swarm_id, 0)) + 1
	_hp = max_hp
	_shoot_timer = randf_range(0.75, shoot_interval)
	add_to_group("enemies")

	collision_layer = 2
	collision_mask = 0
	var body_shape := CircleShape2D.new()
	body_shape.radius = BODY_RADIUS
	var body_cs := CollisionShape2D.new()
	body_cs.shape = body_shape
	add_child(body_cs)

	var contact_area := Area2D.new()
	contact_area.collision_layer = 0
	contact_area.collision_mask = 1
	var area_shape := CircleShape2D.new()
	area_shape.radius = BODY_RADIUS
	var area_cs := CollisionShape2D.new()
	area_cs.shape = area_shape
	contact_area.add_child(area_cs)
	contact_area.body_entered.connect(_on_contact_body_entered)
	contact_area.body_exited.connect(_on_contact_body_exited)
	add_child(contact_area)

	_setup_sprite()


func _exit_tree() -> void:
	if _swarm_id.is_empty():
		return
	var remaining: int = int(_swarm_member_counts.get(_swarm_id, 1)) - 1
	if remaining <= 0:
		_swarm_member_counts.erase(_swarm_id)
		_swarm_targets.erase(_swarm_id)
		_swarm_target_update_at.erase(_swarm_id)
		_swarm_speed_mults.erase(_swarm_id)
	else:
		_swarm_member_counts[_swarm_id] = remaining


func _setup_sprite() -> void:
	_sprite = Sprite2D.new()
	_move_frames = _load_move_frames()
	_animation_offset_msec = randi_range(0, int(MOVE_FRAME_TIME * 1000.0) * MOVE_MAX_FRAMES)
	if _move_frames.is_empty():
		_sprite.texture = load("%s/enemy_harvester.png" % ENEMY_ART_DIR)
	else:
		_sprite.texture = _move_frames[0] as Texture2D
	_sprite.scale = Vector2(SPRITE_SCALE, SPRITE_SCALE)
	_sprite.modulate = sprite_modulate
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if _dying:
		velocity = Vector2.ZERO
		return

	var viewport_size: Vector2 = get_viewport_rect().size

	if not _entered_screen:
		var entry_delta: Vector2 = _entry_target - global_position
		if entry_delta.length() > 1.0:
			velocity = entry_delta.normalized() * move_speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		if _is_inside_visible_screen(viewport_size):
			_entered_screen = true
			global_position = _clamp_to_visible_engagement_area(global_position, viewport_size)
			_choose_swarm_target(viewport_size, global_position - _swarm_offset)
	else:
		_update_swarm_target(viewport_size)
		var target_value: Variant = _swarm_targets.get(_swarm_id, global_position)
		var swarm_target: Vector2 = target_value if target_value is Vector2 else global_position
		var target_pos: Vector2 = _clamp_to_battlefield(
			swarm_target + _swarm_offset,
			viewport_size
		)
		var target_delta: Vector2 = target_pos - global_position
		if target_delta.length() > 1.0:
			var speed_mult: float = float(_swarm_speed_mults.get(_swarm_id, 1.0))
			velocity = target_delta.normalized() * move_speed * speed_mult
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		global_position = _clamp_to_visible_engagement_area(global_position, viewport_size)

	_update_sprite_rotation(delta)
	_update_sprite_animation()

	if _target_marked:
		queue_redraw()

	_shoot_timer -= delta
	if _shoot_timer <= 0.0:
		_shoot_timer = shoot_interval + randf_range(-0.25, 0.35)
		_fire()

	if _player_touching:
		_contact_timer -= delta
		if _contact_timer <= 0.0:
			_contact_timer = CONTACT_INTERVAL
			var player := get_tree().get_first_node_in_group("player")
			if is_instance_valid(player):
				player.take_damage(CONTACT_DAMAGE)


func _update_swarm_target(viewport_size: Vector2) -> void:
	var center_pos: Vector2 = global_position - _swarm_offset
	if not _swarm_targets.has(_swarm_id):
		_choose_swarm_target(viewport_size, center_pos)
		return
	var update_at: int = int(_swarm_target_update_at.get(_swarm_id, 0))
	if Time.get_ticks_msec() >= update_at:
		_choose_swarm_target(viewport_size, center_pos)


func _choose_swarm_target(viewport_size: Vector2, center_pos: Vector2) -> void:
	var bounds: Rect2 = _battlefield_bounds(viewport_size)
	var center_margin: float = max(8.0, _swarm_offset.length())
	var min_x: float = min(bounds.position.x + center_margin, bounds.end.x)
	var max_x: float = max(min_x, bounds.end.x - center_margin)
	var min_y: float = min(bounds.position.y + center_margin, bounds.end.y)
	var max_y: float = max(min_y, bounds.end.y - center_margin)
	var target: Vector2 = center_pos
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D and is_instance_valid(player):
		var player_2d: Node2D = player
		var away_from_player: Vector2 = center_pos - player_2d.global_position
		if away_from_player.length_squared() <= 1.0:
			away_from_player = Vector2.UP
		away_from_player = away_from_player.normalized()
		var follow_distance: float = SWARM_FOLLOW_DISTANCE
		if center_pos.distance_to(player_2d.global_position) < SWARM_FOLLOW_MIN_DISTANCE:
			follow_distance = SWARM_FOLLOW_MIN_DISTANCE
		target = player_2d.global_position + away_from_player * follow_distance
	target = Vector2(
		clampf(target.x, min_x, max_x),
		clampf(target.y, min_y, max_y)
	)
	_swarm_targets[_swarm_id] = target
	_swarm_target_update_at[_swarm_id] = Time.get_ticks_msec() + int(
		SWARM_FOLLOW_UPDATE_INTERVAL * 1000.0
	)


func _update_sprite_rotation(delta: float) -> void:
	if _sprite == null or velocity.length_squared() <= 1.0:
		return
	var target_rotation: float = velocity.angle() + PI / 2.0
	_sprite.rotation = lerp_angle(_sprite.rotation, target_rotation, clampf(delta * 12.0, 0.0, 1.0))


func _update_sprite_animation() -> void:
	if _sprite == null or _move_frames.is_empty():
		return
	if velocity.length_squared() <= 1.0:
		_sprite.texture = _move_frames[0] as Texture2D
		return
	var frame_time_msec: int = max(1, int(MOVE_FRAME_TIME * 1000.0))
	var frame_index: int = int((Time.get_ticks_msec() + _animation_offset_msec) / frame_time_msec) \
		% _move_frames.size()
	_sprite.texture = _move_frames[frame_index] as Texture2D


static func _load_move_frames() -> Array:
	var frames: Array = []
	for i: int in MOVE_MAX_FRAMES:
		var texture: Texture2D = null
		for path: String in [
			"%s/enemy_harvester_move_%02d.png" % [ENEMY_ART_DIR, i],
			"%s/enemy_harvester_move_%d.png" % [ENEMY_ART_DIR, i],
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


func _battlefield_bounds(viewport_size: Vector2) -> Rect2:
	var left: float = EDGE_PADDING
	var right: float = max(left, viewport_size.x - EDGE_PADDING)
	var top: float = BATTLEFIELD_TOP_PADDING
	var bottom: float = max(top, viewport_size.y - BATTLEFIELD_BOTTOM_PADDING)
	return Rect2(
		Vector2(left, top),
		Vector2(max(1.0, right - left), max(1.0, bottom - top))
	)


func _clamp_to_battlefield(pos: Vector2, viewport_size: Vector2) -> Vector2:
	var bounds: Rect2 = _battlefield_bounds(viewport_size)
	return Vector2(
		clampf(pos.x, bounds.position.x, bounds.end.x),
		clampf(pos.y, bounds.position.y, bounds.end.y)
	)


func _clamp_to_visible_engagement_area(pos: Vector2, viewport_size: Vector2) -> Vector2:
	var max_x: float = max(0.0, viewport_size.x)
	var max_y: float = max(0.0, viewport_size.y)
	return Vector2(
		clampf(pos.x, 0.0, max_x),
		clampf(pos.y, 0.0, max_y)
	)


func _is_inside_visible_screen(viewport_size: Vector2) -> bool:
	return global_position.x >= 0.0 \
		and global_position.x <= viewport_size.x \
		and global_position.y >= 0.0 \
		and global_position.y <= viewport_size.y


func _fire() -> void:
	var target: Node2D = _choose_attack_target()
	if not is_instance_valid(target):
		return
	var bullet: Node2D = BULLET_SCENE.instantiate()
	bullet.global_position = global_position
	bullet.direction = (target.global_position - global_position).normalized()
	bullet.damage = projectile_damage
	bullet.speed = projectile_speed
	get_parent().add_child(bullet)


func _choose_attack_target() -> Node2D:
	var decoys: Array = get_tree().get_nodes_in_group("enemy_decoys")
	if not decoys.is_empty():
		var decoy_value: Variant = decoys[randi() % decoys.size()]
		if decoy_value is Node2D and is_instance_valid(decoy_value):
			var decoy: Node2D = decoy_value
			return decoy
	var player := get_tree().get_first_node_in_group("player")
	if player is Node2D and is_instance_valid(player):
		var player_2d: Node2D = player
		return player_2d
	return null


func _on_contact_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_touching = true
		_contact_timer = 0.0


func _on_contact_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_touching = false


func _draw() -> void:
	if not _target_marked:
		return
	var pulse: float = 0.5 + 0.5 * sin(float(Time.get_ticks_msec()) * 0.008)
	var col := Color(1.0, 0.28, 0.18, 0.72 + 0.22 * pulse)
	draw_arc(Vector2.ZERO, 35.0 + 3.0 * pulse, 0.0, TAU, 40, col, 2.4)
	draw_arc(Vector2.ZERO, 22.0, 0.0, TAU, 32, Color(1.0, 0.78, 0.24, 0.50), 1.4)
	draw_line(Vector2(-44.0, 0.0), Vector2(-28.0, 0.0), col, 2.0)
	draw_line(Vector2(28.0, 0.0), Vector2(44.0, 0.0), col, 2.0)
	draw_line(Vector2(0.0, -44.0), Vector2(0.0, -28.0), col, 2.0)
	draw_line(Vector2(0.0, 28.0), Vector2(0.0, 44.0), col, 2.0)


func set_target_marker(damage_mult: float) -> void:
	_target_marked = true
	_target_damage_mult = max(1.0, damage_mult)
	queue_redraw()


func clear_target_marker() -> void:
	_target_marked = false
	_target_damage_mult = 1.0
	queue_redraw()


func take_damage(amount: int) -> void:
	if _dying:
		return
	_hp -= int(ceil(float(amount) * _target_damage_mult))
	modulate = Color(1.0, 0.5, 0.5)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.12)
	if _hp <= 0:
		_die()


func _die() -> void:
	if _dying:
		return
	_dying = true
	remove_from_group("enemies")
	died.emit(global_position, metal_drop, crystal_drop)
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)
