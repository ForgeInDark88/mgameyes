extends CharacterBody2D
## Брошенная бомба: отскакивает и взрывается через секунду.

const RADIUS := 90.0
const DAMAGE := 30

var _fuse := 1.2
var _exploded := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 9
	cs.shape = shape
	add_child(cs)


func _physics_process(delta: float) -> void:
	queue_redraw()
	if _exploded > 0.0:
		_exploded -= delta
		if _exploded <= 0.0:
			queue_free()
		return
	velocity.y += 1200.0 * delta
	var col := move_and_collide(velocity * delta)
	if col:
		velocity = velocity.bounce(col.get_normal()) * 0.4
	_fuse -= delta
	if _fuse <= 0.0:
		_explode()


func _explode() -> void:
	_exploded = 0.25
	var shape := CircleShape2D.new()
	shape.radius = RADIUS
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, global_position)
	q.collision_mask = 1 | 4
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 32):
		var c = hit.collider
		if c:
			GameState.player_hit(c, DAMAGE, global_position)


func _draw() -> void:
	if _exploded > 0.0:
		var t := _exploded / 0.25
		draw_circle(Vector2.ZERO, RADIUS * (1.2 - t * 0.5), Color(1, 0.6, 0.1, t * 0.7))
		draw_circle(Vector2.ZERO, RADIUS * 0.5 * (1.2 - t * 0.5), Color(1, 0.95, 0.6, t))
		return
	draw_circle(Vector2.ZERO, 9, Color(0.15, 0.15, 0.18))
	var blink := int(_fuse * 10) % 2 == 0
	draw_circle(Vector2(5, -9), 3, Color(1, 0.3, 0.1) if blink else Color(1, 0.8, 0.2))
