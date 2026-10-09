extends Area2D
## Снаряд: стрела (летит с небольшой гравитацией) или огненный шар демонов.

var velocity := Vector2.ZERO
var damage := 10
var color := Color.BLACK
var from_player := false
var fire := false
var _life := 3.0
var _t := 0.0


func setup(vel: Vector2, dmg: int, mask: int, col: Color) -> void:
	velocity = vel
	damage = dmg
	collision_layer = 0
	collision_mask = mask
	color = col


func _ready() -> void:
	var cs := CollisionShape2D.new()
	if fire:
		var c := CircleShape2D.new()
		c.radius = 8
		cs.shape = c
	else:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(14, 4)
		cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	rotation = velocity.angle()


func _physics_process(delta: float) -> void:
	_t += delta
	if not fire:
		velocity.y += 200.0 * delta
	position += velocity * delta
	rotation = velocity.angle()
	_life -= delta
	if _life <= 0.0:
		queue_free()
	if fire:
		queue_redraw()


func _on_body_entered(body: Node) -> void:
	# стрелы не ломают блоки — для этого есть меч и бомбы
	if body.has_method("take_damage") and not body.is_in_group("breakable"):
		var from := global_position - velocity.normalized() * 20
		if from_player:
			GameState.player_hit(body, damage, from)
		else:
			body.take_damage(damage, from)
	queue_free()


func _draw() -> void:
	if fire:
		var flick := 1.0 + sin(_t * 30.0) * 0.15
		draw_circle(Vector2(-6, 0), 7 * flick, Color(1, 0.4, 0.05, 0.5))
		draw_circle(Vector2.ZERO, 8 * flick, Color(1, 0.35, 0.05))
		draw_circle(Vector2(2, 0), 4, Color(1, 0.9, 0.4))
		return
	draw_line(Vector2(-12, 0), Vector2(8, 0), color, 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(5, -4), Vector2(5, 4)]), color)
	draw_line(Vector2(-12, 0), Vector2(-16, -4), color, 1.5)
	draw_line(Vector2(-12, 0), Vector2(-16, 4), color, 1.5)
