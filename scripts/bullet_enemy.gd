extends Area2D

const SPEED := 260.0
const DAMAGE := 10

var direction: Vector2 = Vector2.DOWN

func _ready() -> void:
	collision_layer = 8   # enemy_bullet
	collision_mask  = 1   # hits: player
	var shape := CircleShape2D.new()
	shape.radius = 6.0
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	rotation = direction.angle() + PI / 2.0

	var spr := Sprite2D.new()
	spr.texture = load("res://assets/bullets/bullet_enemy.png")
	add_child(spr)

func _physics_process(delta: float) -> void:
	position += direction * SPEED * delta
	var sz := get_viewport_rect().size
	if position.y > sz.y + 70.0 or position.x < -70.0 or position.x > sz.x + 70.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.take_damage(DAMAGE)
		queue_free()
