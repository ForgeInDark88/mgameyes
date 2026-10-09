extends "res://scripts/level/enemy_base.gd"
## Верховный маг Иллариона — босс. Парит над залом, телепортируется,
## стреляет веером лунных сфер, а на половине здоровья — двойным веером.
## После победы его тело остаётся на полу.

const ProjectileScript := preload("res://scripts/level/projectile.gd")
const Characters := preload("res://scripts/data/characters.gd")
const SIZE := Vector2(30, 60)

var _spots: Array = []
var _t := 0.0
var _shoot_cd := 2.0
var _blink_cd := 4.0
var _blink := 0.0
var _target := Vector2.ZERO


func _ready() -> void:
	variant = "mage"
	max_hp = 450
	touch_damage = 15
	leave_body = "elf_mage"
	leave_pose = "fallen"
	leave_name = "Верховный маг"
	super._ready()
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)
	# точки телепорта вокруг места появления
	for dx in [-360, -180, 0, 180, 360]:
		_spots.append(position + Vector2(dx, -120 - absf(dx) * 0.15))
	_target = _spots[2]


func enraged() -> bool:
	return hp * 2 < max_hp


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	_t += delta
	_blink = maxf(_blink - delta, 0.0)
	velocity = (_target + Vector2(0, sin(_t * 2.0) * 12.0) - position) * 3.0
	move_and_slide()
	var player := get_player()
	if player == null or player.dead or player_safe(player):
		return
	_blink_cd -= delta
	if _blink_cd <= 0.0:
		_blink_cd = 3.0 if enraged() else 4.5
		_blink = 0.3
		_target = _spots.pick_random()
		position = _target
	_shoot_cd -= delta
	if _shoot_cd <= 0.0:
		_shoot_cd = 1.4 if enraged() else 2.0
		var eye := global_position + Vector2(0, -SIZE.y * 0.7)
		var aim: Vector2 = (player.center() - eye).normalized()
		var count := 7 if enraged() else 5
		for i in count:
			var p := ProjectileScript.new()
			p.kind = "magic"
			var ang := aim.angle() + (i - (count - 1) / 2.0) * 0.2
			p.setup(Vector2.from_angle(ang) * 300.0, 14, 1 | 2, Color(0.6, 0.8, 1.0))
			p.global_position = eye + aim * 30.0
			get_parent().add_child(p)


func _draw() -> void:
	if _blink > 0.0:
		draw_circle(Vector2(0, -30), 60 * (1.0 - _blink / 0.3) + 10, Color(0.7, 0.85, 1.0, _blink * 2.0))
	draw_circle(Vector2(0, -30), 44, Color(0.6, 0.8, 1.0, 0.15 + 0.05 * sin(_t * 4.0)))
	var player := get_player()
	var face := 1 if player and player.global_position.x > global_position.x else -1
	Characters.draw(self, "elf_mage", Vector2.ZERO, 1.2, "stand", face, _t)
	if _flash > 0.0:
		draw_rect(Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y), Color(1, 1, 1, 0.5))
	draw_rect(Rect2(-60, -SIZE.y - 44, 120, 8), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-60, -SIZE.y - 44, 120.0 * hp / max_hp, 8), Color(0.6, 0.8, 1.0))
	draw_string(ThemeDB.fallback_font, Vector2(-70, -SIZE.y - 50), "Верховный маг", HORIZONTAL_ALIGNMENT_CENTER, 140, 14, Color(0.1, 0.1, 0.2))
