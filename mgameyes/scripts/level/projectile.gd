extends Area2D
## Стрела. Летит по прямой с небольшой гравитацией, ранит то, во что попала.

var velocity := Vector2.ZERO
var damage := 1
var color := Color.BLACK
var _life := 3.0


func setup(vel: Vector2, dmg: int, mask: int, col: Color) -> void:
	velocity = vel
	damage = dmg
	collision_layer = 0
	collision_mask = mask
	color = col


func _ready() -> void:
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(14, 4)
	cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	velocity.y += 200.0 * delta
	position += velocity * delta
	rotation = velocity.angle()
	_life -= delta
	if _life <= 0.0:
		queue_free()


func _on_body_entered(body: Node) -> void:
	# стрелы не ломают блоки — для этого есть меч и бомбы
	if body.has_method("take_damage") and not body.is_in_group("breakable"):
		body.take_damage(damage, global_position - velocity.normalized() * 20)
	queue_free()


func _draw() -> void:
	draw_line(Vector2(-12, 0), Vector2(8, 0), color, 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(5, -4), Vector2(5, 4)]), color)
	draw_line(Vector2(-12, 0), Vector2(-16, -4), color, 1.5)
	draw_line(Vector2(-12, 0), Vector2(-16, 4), color, 1.5)
