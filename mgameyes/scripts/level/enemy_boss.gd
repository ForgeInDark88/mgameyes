extends "res://scripts/level/enemy_base.gd"
## Страж Оскала — босс: парящий каменный череп. Стреляет веером проклятых искр,
## а на половине здоровья злится, стреляет чаще и пробуждает двух каменных стражей.

const ProjectileScript := preload("res://scripts/level/projectile.gd")
const WalkerScript := preload("res://scripts/level/enemy_walker.gd")
const SIZE := Vector2(80, 80)

var _home := Vector2.ZERO
var _t := 0.0
var _shoot_cd := 2.0
var _summoned := false


func _ready() -> void:
	variant = "guardian"
	max_hp = 450
	touch_damage = 25
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)
	_home = position - Vector2(0, 150)


func enraged() -> bool:
	return hp * 2 < max_hp


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	_t += delta
	var target := _home + Vector2(sin(_t * 0.5) * 360.0, sin(_t * 1.3) * 30.0)
	velocity = (target - position) * 1.5 + _knock * 0.2
	move_and_slide()
	var player := get_player()
	if player == null or player.dead:
		return
	touch_player(player, Rect2(global_position - Vector2(SIZE.x / 2, SIZE.y), SIZE))
	if enraged() and not _summoned:
		_summoned = true
		for sx in [-1, 1]:
			var g := WalkerScript.new()
			g.variant = "guardian"
			get_parent().spawn_enemy(g, _home + Vector2(sx * 220, 150))
	if player_safe(player):
		return
	_shoot_cd -= delta
	if _shoot_cd <= 0.0:
		_shoot_cd = 1.3 if enraged() else 2.2
		var center := global_position + Vector2(0, -SIZE.y / 2)
		var aim: Vector2 = (player.center() - center).normalized()
		var count := 5 if enraged() else 3
		for i in count:
			var p := ProjectileScript.new()
			p.fire = true
			var ang := aim.angle() + (i - (count - 1) / 2.0) * 0.25
			p.setup(Vector2.from_angle(ang) * 340.0, 15, 1 | 2, Color(1, 0.4, 0.1))
			p.global_position = center + aim * 46.0
			get_parent().add_child(p)


func _draw() -> void:
	var c := Vector2(0, -SIZE.y / 2)
	var stone := body_color(Color(0.5, 0.46, 0.42) if not enraged() else Color(0.55, 0.38, 0.32))
	draw_circle(c, 40, stone)
	draw_rect(Rect2(c + Vector2(-26, 18), Vector2(52, 22)), stone)
	for sx in [-1, 1]:
		draw_circle(c + Vector2(sx * 15, -6), 11, Color(0.08, 0.03, 0.02))
		draw_circle(c + Vector2(sx * 15, -6), 5 + sin(_t * 5.0) * 1.5, Color(1, 0.3, 0.1))
	for k in 5:
		draw_rect(Rect2(c + Vector2(-22 + k * 10, 26), Vector2(7, 12)), Color(0.85, 0.8, 0.7))
	draw_line(c + Vector2(-30, -20), c + Vector2(-10, -36), Color(1, 0.4, 0.1, 0.7), 2.0)
	draw_rect(Rect2(-60, -SIZE.y - 30, 120, 8), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-60, -SIZE.y - 30, 120.0 * hp / max_hp, 8), Color(0.9, 0.15, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(-60, -SIZE.y - 36), "Страж Оскала", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Color(0.9, 0.8, 0.7))
