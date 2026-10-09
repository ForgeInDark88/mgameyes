extends Area2D
## Шипы: ранят игрока и подбрасывают вверх.

const TILE := 32.0

## true — вода/нечистоты вместо шипов
var water := false
var _t := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(TILE, TILE * 0.5)
	cs.shape = shape
	cs.position = Vector2(TILE / 2, TILE * 0.75)
	add_child(cs)


func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		if body.has_method("take_damage"):
			body.take_damage(10, body.global_position + Vector2(0, 10))


func _process(delta: float) -> void:
	if water:
		_t += delta
		queue_redraw()


func _draw() -> void:
	if water:
		var col := Color(0.3, 0.4, 0.15, 0.9) if get_parent().get("theme_id") in ["sewer", "dungeon"] else Color(0.25, 0.5, 0.85, 0.85)
		draw_rect(Rect2(0, TILE * 0.3, TILE, TILE * 0.7), col)
		draw_line(Vector2(0, TILE * 0.3 + sin(_t * 3.0 + position.x) * 2.0), Vector2(TILE, TILE * 0.3 + sin(_t * 3.0 + position.x + 1.0) * 2.0), col.lightened(0.4), 2.0)
		return
	for i in 4:
		var x := i * TILE / 4
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, TILE), Vector2(x + TILE / 8, TILE * 0.45), Vector2(x + TILE / 4, TILE)]),
			Color(0.55, 0.55, 0.6))
