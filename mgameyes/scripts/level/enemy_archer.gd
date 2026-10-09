extends "res://scripts/level/enemy_base.gd"
## Лучник Ордена — красный летающий щит с луком с концепта.
## Парит, держит дистанцию и стреляет в игрока, если видит его.

const ProjectileScript := preload("res://scripts/level/projectile.gd")

const SIZE := Vector2(34, 48)
const SIGHT := 520.0
const SHOOT_INTERVAL := 1.8

var _home := Vector2.ZERO
var _t := 0.0
var _shoot_cd := 1.0
var _aim := Vector2.LEFT


func _ready() -> void:
	max_hp = 3
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	add_child(cs)
	_home = position
	_t = randf() * TAU


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	_t += delta
	var target := _home + Vector2(sin(_t * 0.7) * 60.0, sin(_t * 1.6) * 14.0)
	var player := get_player()
	var sees := false
	if player and not player.dead:
		var pc: Vector2 = player.center()
		var dist := global_position.distance_to(pc)
		if dist < SIGHT and can_see(pc, global_position):
			sees = true
			_aim = (pc - global_position).normalized()
			# держим дистанцию ~250 px
			if dist < 220.0:
				target = position - _aim * 80.0
		_shoot_cd -= delta
		if sees and _shoot_cd <= 0.0:
			_shoot()
	velocity = (target - position) * 2.0 + _knock
	move_and_slide()


func _shoot() -> void:
	_shoot_cd = SHOOT_INTERVAL
	var p := ProjectileScript.new()
	p.setup(_aim * 420.0, 1, 1 | 2, Color(0.5, 0.05, 0.05))
	p.global_position = global_position + _aim * 24.0
	get_parent().add_child(p)


func _draw() -> void:
	var c := body_color(Color(0.9, 0.12, 0.12))
	# щит
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -24), Vector2(10, -24), Vector2(17, -6), Vector2(14, 14),
		Vector2(0, 24), Vector2(-14, 14), Vector2(-17, -6)]), c)
	# лук и стрела, направленные на игрока
	var a := _aim.angle()
	var bow_c := Vector2.from_angle(a) * 4
	draw_arc(bow_c, 12, a - PI / 2, a + PI / 2, 10, Color(0.15, 0.1, 0.05), 2.5)
	draw_line(bow_c - Vector2.from_angle(a) * 8, bow_c + Vector2.from_angle(a) * 22, Color.BLACK, 2.0)
	draw_hp_bar(-34)
