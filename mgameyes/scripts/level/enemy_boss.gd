extends "res://scripts/level/enemy_base.gd"
## Страж Пепельных врат — босс. Парит над ареной, стреляет веером огненных шаров,
## а когда здоровья меньше половины — злится и стреляет чаще.

const ProjectileScript := preload("res://scripts/level/projectile.gd")
const ArcherScript := preload("res://scripts/level/enemy_archer.gd")
const SIZE := Vector2(64, 84)

var _home := Vector2.ZERO
var _t := 0.0
var _shoot_cd := 2.0
var _summoned := false


func _ready() -> void:
	variant = "demon"
	max_hp = 400
	touch_damage = 25
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)
	_home = position


func enraged() -> bool:
	return hp < max_hp / 2


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	_t += delta
	var target := _home + Vector2(sin(_t * 0.5) * 380.0, sin(_t * 1.3) * 30.0)
	velocity = (target - position) * 1.5 + _knock * 0.3
	move_and_slide()
	var player := get_player()
	if player == null or player.dead:
		return
	touch_player(player, Rect2(global_position - Vector2(SIZE.x / 2, SIZE.y), SIZE))
	if enraged() and not _summoned:
		# вторая фаза: Морвен призывает подмогу
		_summoned = true
		for sx in [-1, 1]:
			var a := ArcherScript.new()
			a.variant = "demon"
			get_parent().spawn_enemy(a, global_position + Vector2(sx * 160, -40))
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
			p.global_position = center + aim * 40.0
			get_parent().add_child(p)


func _draw() -> void:
	draw_blood_glow(70, Vector2(0, -SIZE.y / 2))
	var r := Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y)
	var base := Color(0.65, 0.05, 0.08) if not enraged() else Color(0.85, 0.15, 0.05)
	draw_rect(r, body_color(base))
	draw_rect(r, Color(0.2, 0.0, 0.0), false, 3.0)
	for sx in [-1, 1]:
		draw_colored_polygon(PackedVector2Array([
			Vector2(sx * 14, -SIZE.y), Vector2(sx * 34, -SIZE.y - 30), Vector2(sx * 26, -SIZE.y)]), Color(0.15, 0.1, 0.08))
		draw_rect(Rect2(sx * 14 - 6, -SIZE.y + 18, 12, 8), Color(1, 0.85, 0.2))
	draw_rect(Rect2(-16, -SIZE.y + 44, 32, 6), Color(0.1, 0.0, 0.0))
	# полоска здоровья босса
	draw_rect(Rect2(-60, -SIZE.y - 46, 120, 8), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-60, -SIZE.y - 46, 120.0 * hp / max_hp, 8), Color(0.9, 0.15, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(-60, -SIZE.y - 52), "Морвен", HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Color(0.2, 0.0, 0.0))
