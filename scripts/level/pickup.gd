extends Area2D
## Предмет, лежащий на уровне. Подбирается касанием.

const Items := preload("res://scripts/data/items.gd")

var item_id := "potion"
var count := 1
var _t := 0.0
var _base_y := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14
	cs.shape = shape
	add_child(cs)
	_base_y = position.y
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_t += delta
	position.y = _base_y + sin(_t * 3.0) * 4.0


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and GameState.add_item(item_id, count):
		queue_free()


func _draw() -> void:
	draw_circle(Vector2.ZERO, 16, Color(1, 1, 0.7, 0.35))
	Items.draw_icon(self, item_id, Rect2(-14, -14, 28, 28))
