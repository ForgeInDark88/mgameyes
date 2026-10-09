extends StaticBody2D
## Оранжевый (деревянный) блок с концепта — ломается мечом или бомбой.

const SIZE := 32.0

var hp := 20


func _ready() -> void:
	add_to_group("breakable")
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(SIZE, SIZE)
	cs.shape = shape
	add_child(cs)


func take_damage(amount: int, _from: Vector2) -> void:
	hp -= amount
	queue_redraw()
	if hp <= 0:
		queue_free()


func _draw() -> void:
	var r := Rect2(-SIZE / 2, -SIZE / 2, SIZE, SIZE)
	draw_rect(r, Color(0.72, 0.47, 0.32))
	draw_rect(r, Color(0.4, 0.24, 0.14), false, 2.0)
	draw_line(Vector2(-SIZE / 2, 2), Vector2(SIZE / 2, -1), Color(0.4, 0.24, 0.14), 1.5)
	if hp <= 10:
		draw_line(Vector2(-8, -12), Vector2(2, 0), Color(0.25, 0.14, 0.08), 2.0)
		draw_line(Vector2(2, 0), Vector2(-2, 12), Color(0.25, 0.14, 0.08), 2.0)
