extends "res://scripts/level/enemy_base.gd"
## Пехотинец: ходит по земле, разворачивается у стен и обрывов,
## замечает игрока и бежит к нему. Ранит касанием.
## variant "elf" — эльф-разведчик (быстрый, с кинжалом), "demon" — рогатый демон.

const SIZE := Vector2(28, 42)
const GRAVITY := 1500.0

var speed := 70.0
var chase_speed := 140.0
var dir := -1


func _ready() -> void:
	if variant == "elf":
		max_hp = 30
		speed = 90.0
		chase_speed = 170.0
		touch_damage = 12
	else:
		max_hp = 40
		touch_damage = 18
	super._ready()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	var spd := speed
	var player := get_player()
	if player and not player.dead:
		var d: Vector2 = player.global_position - global_position
		if absf(d.x) < 280.0 and absf(d.y) < 64.0 and not player_safe(player):
			dir = 1 if d.x > 0.0 else -1
			spd = chase_speed
		touch_player(player, Rect2(global_position - Vector2(SIZE.x / 2, SIZE.y), SIZE))

	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	velocity.x = dir * spd + _knock.x
	if is_on_floor() and _knock == Vector2.ZERO:
		# обрыв впереди — разворот
		var ahead := global_transform.translated(Vector2(dir * (SIZE.x / 2 + 4), 0))
		if not test_move(ahead, Vector2(0, 8)):
			dir = -dir
			velocity.x = dir * spd
	# в лагерь у точки старта враги не заходят
	if in_safe_zone(global_position + Vector2(dir * (SIZE.x / 2 + 6), -SIZE.y / 2)):
		dir = -dir
		velocity.x = dir * spd
	move_and_slide()
	if is_on_wall():
		dir = -dir


func _draw() -> void:
	draw_blood_glow(34, Vector2(0, -SIZE.y / 2))
	var r := Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y)
	if variant == "elf":
		# эльф-разведчик: бирюзовый плащ, острые уши, кинжал
		draw_rect(r, body_color(Color(0.25, 0.65, 0.65)))
		draw_rect(r, Color(0.1, 0.3, 0.3), false, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-dir * 12, -34), Vector2(-dir * 24, -42), Vector2(-dir * 12, -28)]), Color(0.95, 0.85, 0.7))
		draw_rect(Rect2(dir * 6 - 3, -34, 6, 4), Color(0.1, 0.2, 0.2))
		draw_line(Vector2(dir * 12, -18), Vector2(dir * 28, -22), Color(0.8, 0.85, 0.9), 3.0)
	else:
		# демон: тёмно-красный, рога, жёлтые глаза
		draw_rect(r, body_color(Color(0.55, 0.08, 0.1)))
		draw_rect(r, Color(0.25, 0.02, 0.03), false, 2.0)
		for sx in [-1, 1]:
			draw_colored_polygon(PackedVector2Array([Vector2(sx * 6, -SIZE.y), Vector2(sx * 14, -SIZE.y - 12), Vector2(sx * 12, -SIZE.y)]), Color(0.2, 0.15, 0.1))
		draw_rect(Rect2(dir * 6 - 3, -34, 6, 5), Color(1, 0.9, 0.3))
		draw_line(Vector2(dir * 10, -18), Vector2(dir * 24, -10), Color(0.2, 0.15, 0.1), 4.0)
	draw_hp_bar(-SIZE.y - 20)
