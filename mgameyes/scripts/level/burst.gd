extends Node2D
## Вспышка вокруг героя (Демонический ожог): ранит всех в радиусе один раз.

var radius := 120.0
var damage := 30
var color := Color(0.75, 0.05, 0.1)
## "dark" — Демонический ожог, "vortex" — Вихрь клинков Тижена
var style := "dark"
const Characters := preload("res://scripts/data/characters.gd")
var _t := 0.0


func _ready() -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, global_position)
	q.collision_mask = 1 | 4
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 32):
		if hit.collider and hit.collider.is_in_group("enemies"):
			GameState.player_hit(hit.collider, damage, global_position)


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _t > 0.45:
		queue_free()


func _draw() -> void:
	var k := _t / 0.45
	if style == "vortex":
		draw_arc(Vector2.ZERO, radius * 0.85, 0, TAU, 32, Color(color.r, color.g, color.b, 0.6 * (1.0 - k)), 6.0)
		for i in 3:
			var a := _t * 18.0 + i * TAU / 3.0
			Characters.draw_warglaive(self, Vector2.from_angle(a) * radius * 0.6, a + PI / 2, 1.0, _t)
		return
	draw_circle(Vector2.ZERO, radius * (0.3 + k * 0.7), Color(0.1, 0.0, 0.0, 0.5 * (1.0 - k)))
	draw_arc(Vector2.ZERO, radius * (0.3 + k * 0.7), 0, TAU, 32, Color(color.r, color.g, color.b, 1.0 - k), 8.0)
	for i in 10:
		var a := i * TAU / 10.0 + _t * 3.0
		draw_line(Vector2.from_angle(a) * radius * k * 0.5, Vector2.from_angle(a) * radius * k, Color(1, 0.3, 0.1, 1.0 - k), 3.0)
