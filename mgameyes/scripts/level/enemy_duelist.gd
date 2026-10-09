extends "res://scripts/level/enemy_base.gd"
## Босс-персонаж с мечом: подходит, замахивается (видно заранее) и рубит,
## прыгает за игроком. look "liael" — ещё и стреляет веером стрел,
## look "yavalen" — делает рывки. После победы фигура остаётся на уровне.

const ProjectileScript := preload("res://scripts/level/projectile.gd")
const Characters := preload("res://scripts/data/characters.gd")
const GRAVITY := 1500.0
const SIZE := Vector2(28, 56)
const WINDUP := 0.4
const SLASH_DAMAGE := 18

var look := "liael"
var display_name := "Лиаэль"
var facing := -1
var _t := 0.0
var _windup := 0.0
var _slash := 0.0
var _attack_cd := 1.0
var _special_cd := 3.0
var _dash := 0.0


func _ready() -> void:
	max_hp = 350 if look == "liael" else 400
	touch_damage = 12
	leave_body = look
	leave_pose = "kneel" if look == "liael" else "fallen"
	leave_name = display_name
	super._ready()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	_t += delta
	_attack_cd -= delta
	_special_cd -= delta
	_slash = maxf(_slash - delta, 0.0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	var player := get_player()
	if player == null or player.dead or player_safe(player):
		velocity.x = _knock.x
		move_and_slide()
		return
	var d: Vector2 = player.global_position - global_position
	if _windup <= 0.0 and _dash <= 0.0:
		facing = 1 if d.x > 0.0 else -1

	if _windup > 0.0:
		# замах: стоим и готовим удар
		_windup -= delta
		velocity.x = _knock.x
		if _windup <= 0.0:
			_do_slash(player)
	elif _dash > 0.0:
		_dash -= delta
		velocity.x = facing * 520.0
		touch_player(player, Rect2(global_position - Vector2(SIZE.x / 2, SIZE.y), SIZE))
	elif absf(d.x) < 70.0 and absf(d.y) < 60.0 and _attack_cd <= 0.0:
		_windup = WINDUP
		velocity.x = 0.0
	elif _special_cd <= 0.0:
		_special(player)
	else:
		var spd := 150.0 if absf(d.x) > 60.0 else 0.0
		velocity.x = facing * spd + _knock.x
		if is_on_floor() and (d.y < -70.0 or is_on_wall()):
			velocity.y = -620.0
	if in_safe_zone(global_position + Vector2(facing * 24, -SIZE.y / 2)):
		velocity.x = minf(velocity.x, 0.0) if facing > 0 else maxf(velocity.x, 0.0)
	move_and_slide()


func _do_slash(player: Node2D) -> void:
	_slash = 0.18
	_attack_cd = 1.1
	var hit := Rect2(global_position + Vector2(facing * 10 - (70 if facing < 0 else 0), -SIZE.y), Vector2(70, SIZE.y))
	var them := Rect2(player.global_position - Vector2(12, 48), Vector2(24, 48))
	if hit.intersects(them) and not player_safe(player):
		player.take_damage(SLASH_DAMAGE, global_position)


func _special(player: Node2D) -> void:
	if look == "liael":
		_special_cd = 4.0
		var eye := global_position + Vector2(0, -40)
		var aim: Vector2 = (player.center() - eye).normalized()
		for i in 3:
			var p := ProjectileScript.new()
			var dir := Vector2.from_angle(aim.angle() + (i - 1) * 0.18 - 0.06)
			p.setup(dir * 540.0, 10, 1 | 2, Color(0.1, 0.35, 0.3))
			p.global_position = eye + aim * 24.0
			get_parent().add_child(p)
	else:
		_special_cd = 4.5
		_dash = 0.3


func _draw() -> void:
	if _windup > 0.0:
		draw_circle(Vector2(0, -SIZE.y / 2), 40, Color(1, 0.9, 0.3, 0.25))
	Characters.draw(self, look, Vector2.ZERO, 1.2, "stand", facing, _t)
	if _flash > 0.0:
		draw_rect(Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y), Color(1, 1, 1, 0.5))
	# меч: поднят при замахе, опущен после удара
	var hand := Vector2(facing * 12, -30)
	var ang := -1.3 if _windup > 0.0 else (0.9 if _slash > 0.0 else -0.4)
	var tip := hand + Vector2(cos(ang) * facing, sin(ang)) * 46
	draw_line(hand, tip, Color(0.85, 0.88, 0.95), 5.0)
	if _slash > 0.0:
		draw_arc(hand, 46, -1.3 if facing > 0 else PI - 0.9, 0.9 if facing > 0 else PI + 1.3, 12, Color(1, 1, 1, 0.6), 3.0)
	# полоска здоровья босса
	draw_rect(Rect2(-60, -SIZE.y - 40, 120, 8), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-60, -SIZE.y - 40, 120.0 * hp / max_hp, 8), Color(0.9, 0.15, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(-60, -SIZE.y - 46), display_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Color(0.1, 0.1, 0.1))
