extends "res://scripts/level/enemy_base.gd"
## Босс-персонаж ближнего боя: подходит, замахивается (видно заранее) и рубит,
## прыгает за игроком. Особые приёмы зависят от look:
##   "liael"   — веер стрел; после боя остаётся на коленях;
##   "yavalen" — рывок и Щит рода (временно не получает урона);
##   "tizhen"  — два клинка-серпа: вихрь вокруг себя и бросок серпа; при малом здоровье сбегает;
##   "parius_demon" — Демонический клинок, волна Огня правды; на 35% бой обрывается (сюжет);
##   "parius_possessed" — Пегрус в теле Париуса: веера тьмы и рывки; на 50% уходит в метель.

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
var _shield := 0.0
var _spin := 0.0
var _fleeing := 0.0


func _ready() -> void:
	max_hp = {"liael": 350, "yavalen": 400, "tizhen": 450, "parius_demon": 500, "parius_possessed": 600}.get(look, 350)
	touch_damage = 12
	if look == "parius_demon":
		# поединок обрывается катсценой: Париус остаётся стоять
		leave_body = look
		leave_pose = "stand"
		leave_name = display_name
	elif look not in ["tizhen", "parius_possessed"]:
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


func take_damage(amount: int, from: Vector2, blood := false) -> void:
	if _shield > 0.0 or _fleeing > 0.0:
		return
	if look == "parius_demon" and hp - amount <= max_hp * 0.35:
		super.take_damage(hp, from, blood)
		return
	if look in ["tizhen", "parius_possessed"] and hp - amount <= max_hp * (0.12 if look == "tizhen" else 0.5):
		# Тижен не погибает: на последних силах уходит с поля боя
		hp = maxi(hp - amount, 1)
		_fleeing = 1.2
		_flash = 0.15
		remove_from_group("enemies")
		died.emit()
		return
	super.take_damage(amount, from, blood)


func _physics_process(delta: float) -> void:
	tick_effects(delta)
	_t += delta
	if _fleeing > 0.0:
		_fleeing -= delta
		modulate.a = clampf(_fleeing / 1.2, 0.0, 1.0)
		velocity = Vector2(-facing * 260.0, -260.0)
		move_and_slide()
		if _fleeing <= 0.0:
			queue_free()
		return
	_attack_cd -= delta
	_special_cd -= delta
	_slash = maxf(_slash - delta, 0.0)
	_shield = maxf(_shield - delta, 0.0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 900.0)
	var player := get_player()
	if player == null or player.dead or player_safe(player):
		velocity.x = _knock.x
		move_and_slide()
		return
	var d: Vector2 = player.global_position - global_position
	if _windup <= 0.0 and _dash <= 0.0 and _spin <= 0.0:
		facing = 1 if d.x > 0.0 else -1

	if _spin > 0.0:
		# вихрь глеф: ранит всех вокруг
		_spin -= delta
		velocity.x = facing * 90.0
		if absf(d.x) < 80.0 and absf(d.y) < 70.0 and not player_safe(player):
			player.take_damage(15, global_position)
	elif _windup > 0.0:
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
		var spd := (170.0 if look == "tizhen" else 150.0) if absf(d.x) > 60.0 else 0.0
		velocity.x = facing * spd + _knock.x
		if is_on_floor() and (d.y < -70.0 or is_on_wall()):
			velocity.y = -620.0
	if in_safe_zone(global_position + Vector2(facing * 24, -SIZE.y / 2)):
		velocity.x = minf(velocity.x, 0.0) if facing > 0 else maxf(velocity.x, 0.0)
	move_and_slide()


func _do_slash(player: Node2D) -> void:
	_slash = 0.18
	_attack_cd = 0.9 if look == "tizhen" else 1.1
	var hit := Rect2(global_position + Vector2(facing * 10 - (70 if facing < 0 else 0), -SIZE.y), Vector2(70, SIZE.y))
	var them := Rect2(player.global_position - Vector2(12, 48), Vector2(24, 48))
	if hit.intersects(them) and not player_safe(player):
		player.take_damage(SLASH_DAMAGE, global_position)


func _special(player: Node2D) -> void:
	match look:
		"liael":
			_special_cd = 4.0
			var eye := global_position + Vector2(0, -40)
			var aim: Vector2 = (player.center() - eye).normalized()
			for i in 3:
				var p := ProjectileScript.new()
				var dir := Vector2.from_angle(aim.angle() + (i - 1) * 0.18 - 0.06)
				p.setup(dir * 540.0, 10, 1 | 2, Color(0.1, 0.35, 0.3))
				p.global_position = eye + aim * 24.0
				get_parent().add_child(p)
		"yavalen":
			_special_cd = 4.0
			if randf() < 0.5:
				_dash = 0.3
			else:
				_shield = 1.6
		"parius_demon":
			_special_cd = 3.5
			if randf() < 0.5:
				_dash = 0.3
			else:
				var p := ProjectileScript.new()
				p.kind = "truth"
				p.setup(Vector2(facing * 560.0, 0), 20, 1 | 2, Color(1.0, 0.85, 0.4))
				p.global_position = global_position + Vector2(facing * 30, -30)
				get_parent().add_child(p)
		"parius_possessed":
			_special_cd = 2.6
			if randf() < 0.4:
				_dash = 0.3
			else:
				var eye := global_position + Vector2(0, -40)
				var aim: Vector2 = (player.center() - eye).normalized()
				for i in 5:
					var p := ProjectileScript.new()
					p.kind = "magic"
					p.setup(Vector2.from_angle(aim.angle() + (i - 2) * 0.22) * 320.0, 14, 1 | 2, Color(0.6, 0.3, 1.0))
					p.global_position = eye + aim * 24.0
					get_parent().add_child(p)
		"tizhen":
			_special_cd = 3.2
			if randf() < 0.5:
				_spin = 0.9
			else:
				var eye := global_position + Vector2(0, -32)
				var p := ProjectileScript.new()
				p.kind = "glaive"
				p.setup((player.center() - eye).normalized() * 480.0, 16, 1 | 2, Color(0.75, 0.8, 0.85))
				p.global_position = eye
				get_parent().add_child(p)


func _draw() -> void:
	if _windup > 0.0:
		draw_circle(Vector2(0, -SIZE.y / 2), 40, Color(1, 0.9, 0.3, 0.25))
	Characters.draw(self, look, Vector2.ZERO, 1.2, "stand", facing, _t, false)
	if _flash > 0.0:
		draw_rect(Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y), Color(1, 1, 1, 0.5))
	if look == "tizhen":
		_draw_glaives()
	else:
		# меч: поднят при замахе, опущен после удара
		var hand := Vector2(facing * 12, -30)
		var ang := -1.3 if _windup > 0.0 else (0.9 if _slash > 0.0 else -0.4)
		var demon := look.begins_with("parius")
		var tip := hand + Vector2(cos(ang) * facing, sin(ang)) * (60.0 if demon else 46.0)
		if demon:
			draw_line(hand, tip, Color(0.6, 0.85, 1.0, 0.3) if look == "parius_demon" else Color(0.6, 0.3, 1.0, 0.35), 13.0)
			draw_line(hand, tip, Color(0.3, 0.04, 0.08), 7.0)
			draw_line(hand, tip, Color(0.6, 0.85, 1.0) if look == "parius_demon" else Color(0.75, 0.55, 1.0), 2.0)
		else:
			draw_line(hand, tip, Color(0.85, 0.88, 0.95), 5.0)
		if _slash > 0.0:
			draw_arc(hand, 46, -1.3 if facing > 0 else PI - 0.9, 0.9 if facing > 0 else PI + 1.3, 12, Color(1, 1, 1, 0.6), 3.0)
	if _shield > 0.0:
		draw_circle(Vector2(0, -30), 46, Color(0.45, 0.85, 1.0, 0.3))
		draw_arc(Vector2(0, -30), 46, 0, TAU, 32, Color(0.7, 0.95, 1.0, 0.9), 3.0)
	# полоска здоровья босса
	draw_rect(Rect2(-60, -SIZE.y - 40, 120, 8), Color(0.15, 0.15, 0.15))
	draw_rect(Rect2(-60, -SIZE.y - 40, 120.0 * hp / max_hp, 8), Color(0.9, 0.15, 0.15))
	draw_string(ThemeDB.fallback_font, Vector2(-60, -SIZE.y - 46), display_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 14, Color(0.1, 0.1, 0.1))


func _draw_glaives() -> void:
	# два клинка-серпа; во время вихря вращаются вокруг Тижена
	for side in [-1, 1]:
		var hand := Vector2(side * 16, -32)
		var ang: float
		if _spin > 0.0:
			var a := _t * 16.0 + (PI if side < 0 else 0.0)
			hand = Vector2(0, -32) + Vector2.from_angle(a) * 34.0
			ang = a + PI / 2
		elif _windup > 0.0:
			ang = -PI / 2 - side * 0.3
			hand += Vector2(0, -10)
		elif _slash > 0.0:
			ang = 0.2 * facing
			hand += Vector2(facing * 20, 0)
		else:
			ang = -PI / 2 + side * 0.35
		Characters.draw_warglaive(self, hand, ang, 1.15, _t)
	if _spin > 0.0:
		draw_arc(Vector2(0, -32), 62, 0, TAU, 24, Color(0.35, 1.0, 0.45, 0.45), 3.0)
