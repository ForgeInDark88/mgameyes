extends Area2D
## Выход с локации. Открывается, когда все враги побеждены.

signal entered

var active := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(32, 64)
	cs.shape = shape
	cs.position = Vector2(0, -32)
	add_child(cs)
	body_entered.connect(_on_body_entered)


func _on_body_entered(b: Node) -> void:
	if b.is_in_group("player"):
		entered.emit()


func activate() -> void:
	active = true
	# если игрок уже стоит в портале
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			entered.emit()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var r := Rect2(-18, -68, 36, 68)
	draw_rect(r, Color(0.3, 0.25, 0.2))
	var inner := r.grow(-5)
	if active:
		var glow := 0.6 + 0.3 * sin(_t * 4.0)
		draw_rect(inner, Color(0.4, 0.85, 1.0, glow))
	else:
		draw_rect(inner, Color(0.12, 0.12, 0.14))
		draw_line(inner.position, inner.end, Color(0.5, 0.15, 0.15), 3.0)
		draw_line(Vector2(inner.end.x, inner.position.y), Vector2(inner.position.x, inner.end.y), Color(0.5, 0.15, 0.15), 3.0)
