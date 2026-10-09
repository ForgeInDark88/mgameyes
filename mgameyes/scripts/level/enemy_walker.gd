extends "res://scripts/level/enemy_base.gd"
## Пехотинец Ордена: ходит по земле, разворачивается у стен и обрывов,
## замечает игрока и бежит к нему. Ранит касанием.

const SIZE := Vector2(28, 40)
const SPEED := 70.0
const CHASE_SPEED := 140.0
const GRAVITY := 1500.0

var dir := -1


func _ready() -> void:
	max_hp = 3
	super._ready()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	var speed := SPEED
	var player := get_player()
	if player and not player.dead:
		var d: Vector2 = player.global_position - global_position
		if absf(d.x) < 260.0 and absf(d.y) < 64.0:
			dir = 1 if d.x > 0.0 else -1
			speed = CHASE_SPEED
		_touch_damage(player)

	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	velocity.x = dir * speed + _knock.x
	if is_on_floor() and _knock == Vector2.ZERO:
		# обрыв впереди — разворот
		var ahead := global_transform.translated(Vector2(dir * (SIZE.x / 2 + 4), 0))
		if not test_move(ahead, Vector2(0, 8)):
			dir = -dir
			velocity.x = dir * speed
	move_and_slide()
	if is_on_wall():
		dir = -dir


func _touch_damage(player: Node2D) -> void:
	var me := Rect2(global_position - Vector2(SIZE.x / 2, SIZE.y), SIZE)
	var them := Rect2(player.global_position - Vector2(12, 48), Vector2(24, 48))
	if me.intersects(them):
		player.take_damage(1, global_position)


func _draw() -> void:
	var r := Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y)
	draw_rect(r, body_color(Color(0.75, 0.12, 0.12)))
	draw_rect(r, Color(0.35, 0.05, 0.05), false, 2.0)
	draw_rect(Rect2(dir * 6 - 3, -32, 6, 5), Color(1, 0.9, 0.3))
	# копьё
	draw_line(Vector2(dir * 10, -18), Vector2(dir * 26, -26), Color(0.4, 0.3, 0.2), 3.0)
	draw_hp_bar(-SIZE.y - 8)
