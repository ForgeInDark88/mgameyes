extends "res://scripts/level/enemy_base.gd"
## Стрелок. variant "demon" — летающий красный щит с концепта, стреляет огнём;
## variant "elf" — эльф-лучник, стоит на ветке/платформе и стреляет стрелами.

const ProjectileScript := preload("res://scripts/level/projectile.gd")

const SIGHT := 540.0
const GRAVITY := 1500.0

var size := Vector2(34, 48)
var shoot_interval := 1.8
var _home := Vector2.ZERO
var _t := 0.0
var _shoot_cd := 1.0
var _aim := Vector2.LEFT


func _ready() -> void:
	max_hp = 20 if variant == "elf" else 30
	super._ready()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	if variant == "elf":
		size = Vector2(26, 44)
		shoot_interval = 1.5
		cs.position = Vector2(0, -size.y / 2)
	else:
		motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	shape.size = size
	cs.shape = shape
	add_child(cs)
	_home = position
	_t = randf() * TAU
	_shoot_cd = randf_range(0.8, shoot_interval)


func _eye() -> Vector2:
	return global_position + (Vector2(0, -size.y * 0.6) if variant == "elf" else Vector2.ZERO)


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	_t += delta
	var player := get_player()
	var sees := false
	var dist := INF
	if player and not player.dead:
		var pc: Vector2 = player.center()
		dist = _eye().distance_to(pc)
		if dist < SIGHT and can_see(pc, _eye()):
			sees = true
			_aim = (pc - _eye()).normalized()
		_shoot_cd -= delta
		if sees and _shoot_cd <= 0.0:
			_shoot()

	if variant == "elf":
		velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
		velocity.x = _knock.x
		move_and_slide()
		return
	var target := _home + Vector2(sin(_t * 0.7) * 60.0, sin(_t * 1.6) * 14.0)
	if sees and dist < 220.0:
		# держим дистанцию
		target = position - _aim * 80.0
	velocity = (target - position) * 2.0 + _knock
	move_and_slide()


func _shoot() -> void:
	_shoot_cd = shoot_interval
	var p := ProjectileScript.new()
	if variant == "elf":
		# небольшая поправка вверх на гравитацию стрелы
		var dir := (_aim + Vector2(0, -0.08)).normalized()
		p.setup(dir * 520.0, 10, 1 | 2, Color(0.1, 0.35, 0.3))
	else:
		p.fire = true
		p.setup(_aim * 380.0, 15, 1 | 2, Color(1, 0.4, 0.1))
	p.global_position = _eye() + _aim * 24.0
	get_parent().add_child(p)


func _draw() -> void:
	var a := _aim.angle()
	if variant == "elf":
		draw_blood_glow(30, Vector2(0, -22))
		var r := Rect2(-size.x / 2, -size.y, size.x, size.y)
		var face := 1 if _aim.x >= 0.0 else -1
		draw_rect(r, body_color(Color(0.3, 0.55, 0.35)))
		draw_rect(r, Color(0.12, 0.28, 0.15), false, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(-face * 11, -34), Vector2(-face * 22, -44), Vector2(-face * 11, -28)]), Color(0.95, 0.85, 0.7))
		var bc := Vector2(face * 14, -26)
		draw_arc(bc, 16, a - 1.3, a + 1.3, 12, Color(0.45, 0.28, 0.1), 3.5)
		draw_line(bc + Vector2.from_angle(a - 1.3) * 16, bc + Vector2.from_angle(a + 1.3) * 16, Color(0.2, 0.2, 0.2), 1.0)
		draw_hp_bar(-size.y - 10)
		return
	draw_blood_glow(34)
	var c := body_color(Color(0.9, 0.12, 0.12))
	# щит
	draw_colored_polygon(PackedVector2Array([
		Vector2(-10, -24), Vector2(10, -24), Vector2(17, -6), Vector2(14, 14),
		Vector2(0, 24), Vector2(-14, 14), Vector2(-17, -6)]), c)
	# лук и стрела, направленные на игрока
	var bow_c := Vector2.from_angle(a) * 4
	draw_arc(bow_c, 12, a - PI / 2, a + PI / 2, 10, Color(0.15, 0.1, 0.05), 2.5)
	draw_line(bow_c - Vector2.from_angle(a) * 8, bow_c + Vector2.from_angle(a) * 22, Color.BLACK, 2.0)
	draw_hp_bar(-34)
