extends Area2D
## Шипы: ранят игрока и подбрасывают вверх.

const TILE := 32.0


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


func _draw() -> void:
	for i in 4:
		var x := i * TILE / 4
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, TILE), Vector2(x + TILE / 8, TILE * 0.45), Vector2(x + TILE / 4, TILE)]),
			Color(0.55, 0.55, 0.6))
