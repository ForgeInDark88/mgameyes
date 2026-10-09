extends CharacterBody2D
## Игрок. Внешность и навыки берутся из героя текущей кампании (Явален, Париус).

signal hp_changed(hp: int, max_hp: int)
signal died

const Items := preload("res://scripts/data/items.gd")
const ProjectileScript := preload("res://scripts/level/projectile.gd")
const BombScript := preload("res://scripts/level/bomb.gd")
const BurstScript := preload("res://scripts/level/burst.gd")
const Characters := preload("res://scripts/data/characters.gd")
const Skills := preload("res://scripts/data/skills.gd")

const SIZE := Vector2(24, 48)
const SPEED := 260.0
const JUMP_VELOCITY := -600.0
const GRAVITY := 1500.0
const MAX_FALL := 900.0
const COYOTE_TIME := 0.1

const SWORD_DAMAGE := 10
const DEMON_BLADE_DAMAGE := 20
const GLAIVE_DAMAGE := 14
const ARROW_DAMAGE := 8
const POTION_HEAL := 40
const SWING_TIME := 0.2
const SWORD_LEN := 58.0
const AMULET_REGEN := 2.0

var max_hp := 100
var hp := 100
var facing := 1
var dead := false

var _air_jumps := 0
var _coyote := 0.0
var _invuln := 0.0
var _cooldown := 0.0
var _knock_x := 0.0
var _swing := 0.0
var _swing_dir := 1
var _camp_hint := 0.0
var _regen := 0.0
var _t := 0.0
## Перезарядка активных навыков: id -> оставшиеся секунды
var cooldowns := {}
## Сколько ещё держится Щит рода (Явален)
var shield_time := 0.0
## Рывок охотника (Тижен)
var _dash_time := 0.0
var _dash_hit: Array = []
var _dash_damage := 20


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = SIZE
	cs.shape = shape
	cs.position = Vector2(0, -SIZE.y / 2)
	add_child(cs)
	max_hp = GameState.max_hp()
	hp = max_hp
	# короткая неуязвимость после появления на уровне
	_invuln = 2.0


func refresh_max_hp() -> void:
	max_hp = GameState.max_hp()
	hp = max_hp
	hp_changed.emit(hp, max_hp)


func center() -> Vector2:
	return global_position + Vector2(0, -SIZE.y / 2)


func _physics_process(delta: float) -> void:
	_invuln = maxf(_invuln - delta, 0.0)
	_cooldown = maxf(_cooldown - delta, 0.0)
	_swing = maxf(_swing - delta, 0.0)
	_camp_hint = maxf(_camp_hint - delta, 0.0)
	_t += delta
	for k in cooldowns:
		cooldowns[k] = maxf(cooldowns[k] - delta, 0.0)
	shield_time = maxf(shield_time - delta, 0.0)
	if _dash_time > 0.0 and not dead:
		_dash_step(delta)
		return
	queue_redraw()
	if dead:
		return
	if GameState.has_item("amulet") and hp < max_hp:
		# Амулет Эрин: +2 HP в секунду
		_regen += AMULET_REGEN * delta
		if _regen >= 1.0:
			hp = mini(hp + int(_regen), max_hp)
			_regen -= int(_regen)
			hp_changed.emit(hp, max_hp)

	var controls_locked := get_tree().get_first_node_in_group("dialog_open") != null
	var dir := 0.0 if controls_locked else Input.get_axis("move_left", "move_right")

	velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
	velocity.x = dir * SPEED + _knock_x
	_knock_x = move_toward(_knock_x, 0.0, 1200.0 * delta)
	if dir != 0.0:
		facing = signi(int(signf(dir)))

	if is_on_floor():
		_coyote = COYOTE_TIME
		_air_jumps = 1 if GameState.has_item("boots") else 0
	else:
		_coyote -= delta

	if not controls_locked:
		if Input.is_action_just_pressed("jump"):
			if _coyote > 0.0:
				velocity.y = JUMP_VELOCITY
				_coyote = 0.0
			elif _air_jumps > 0:
				_air_jumps -= 1
				velocity.y = JUMP_VELOCITY * 0.9
		if Input.is_action_just_released("jump") and velocity.y < 0.0:
			velocity.y *= 0.5
		var actives := GameState.active_skills()
		for i in mini(actives.size(), 2):
			if Input.is_action_just_pressed("skill_%d" % (i + 1)):
				_use_skill(actives[i])
		if Input.is_action_pressed("use_item") and _cooldown <= 0.0:
			_use_selected_item(Input.is_action_just_pressed("use_item"))

	move_and_slide()

	if global_position.y > 5000:
		take_damage(999, global_position)


func _use_selected_item(just_pressed: bool) -> void:
	var id := GameState.selected_item_id()
	var aim := (get_global_mouse_position() - center()).normalized()
	if aim == Vector2.ZERO:
		aim = Vector2(facing, 0)
	if id in ["sword", "demon_blade", "warglaives", "bow", "bomb"] and in_camp():
		_camp_hint = 1.5
		return
	match id:
		"sword", "demon_blade":
			_sword_attack(aim, id == "demon_blade")
			_cooldown = 0.3
		"warglaives":
			_glaive_attack(aim)
			_cooldown = 0.25
		"bow":
			facing = 1 if aim.x >= 0.0 else -1
			_swing = 0.12
			var p := ProjectileScript.new()
			p.setup(aim * 750.0, ARROW_DAMAGE, 1 | 4, Color(0.15, 0.15, 0.15))
			p.from_player = true
			p.global_position = center() + aim * 30
			get_parent().add_child(p)
			_cooldown = 0.35
		"potion":
			if just_pressed and hp < max_hp:
				hp = mini(hp + POTION_HEAL, max_hp)
				hp_changed.emit(hp, max_hp)
				GameState.consume_selected()
				_cooldown = 0.3
		"bomb":
			if just_pressed:
				var b := BombScript.new()
				b.global_position = center()
				b.velocity = Vector2(aim.x * 380.0, minf(aim.y * 380.0, -200.0))
				get_parent().add_child(b)
				GameState.consume_selected()
				_cooldown = 0.5


func _use_skill(id: String) -> void:
	if cooldowns.get(id, 0.0) > 0.0:
		return
	if in_camp():
		_camp_hint = 1.5
		return
	var sk := Skills.get_skill(id)
	cooldowns[id] = sk.cooldown
	match id:
		"truth_fire":
			# волна белого огня летит вперёд и ранит всех на пути
			var aim := (get_global_mouse_position() - center())
			var dir := 1.0 if aim.x >= 0.0 else -1.0
			facing = int(dir)
			var p := ProjectileScript.new()
			p.setup(Vector2(dir * 620.0, 0), sk.damage, 1 | 4, sk.color)
			p.from_player = true
			p.kind = "truth"
			p.global_position = center() + Vector2(dir * 30, 0)
			get_parent().add_child(p)
		"erin_shield":
			shield_time = sk.duration
		"blade_vortex":
			var v := BurstScript.new()
			v.global_position = center()
			v.radius = 100.0
			v.damage = sk.damage
			v.color = sk.color
			v.style = "vortex"
			get_parent().add_child(v)
		"hunter_dash":
			var aim2 := get_global_mouse_position() - center()
			facing = 1 if aim2.x >= 0.0 else -1
			_dash_time = 0.22
			_dash_hit = []
			_dash_damage = sk.damage
		"demon_burn":
			var b := BurstScript.new()
			b.global_position = center()
			b.radius = 130.0
			b.damage = sk.damage
			b.color = sk.color
			get_parent().add_child(b)


## Рывок охотника: быстрый бросок вперёд, ранит всех на пути один раз.
func _dash_step(delta: float) -> void:
	_dash_time -= delta
	_invuln = maxf(_invuln, 0.1)
	velocity = Vector2(facing * 1000.0, 0.0)
	move_and_slide()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(60, 56)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, center())
	q.collision_mask = 4
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 16):
		var c = hit.collider
		if c and not c in _dash_hit:
			_dash_hit.append(c)
			GameState.player_hit(c, _dash_damage, center() - Vector2(facing * 30, 0))
	if _dash_time <= 0.0:
		velocity.x = facing * SPEED


## Лунные серпы: удар сразу вперёд и назад.
func _glaive_attack(aim: Vector2) -> void:
	_swing_dir = 1 if aim.x >= 0.0 else -1
	facing = _swing_dir
	_swing = SWING_TIME
	var hit_set := []
	for part in [[Vector2(70, 72), 38], [Vector2(44, 72), -24]]:
		var shape := RectangleShape2D.new()
		shape.size = part[0]
		var q := PhysicsShapeQueryParameters2D.new()
		q.shape = shape
		q.transform = Transform2D(0.0, center() + Vector2(_swing_dir * part[1], -4))
		q.collision_mask = 1 | 4
		q.exclude = [get_rid()]
		for hit in get_world_2d().direct_space_state.intersect_shape(q, 16):
			var c = hit.collider
			if c and not c in hit_set:
				hit_set.append(c)
				GameState.player_hit(c, GLAIVE_DAMAGE, center())


func _sword_attack(aim: Vector2, demon := false) -> void:
	_swing_dir = 1 if aim.x >= 0.0 else -1
	facing = _swing_dir
	_swing = SWING_TIME
	var shape := RectangleShape2D.new()
	shape.size = Vector2(84, 80) if demon else Vector2(64, 72)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, center() + Vector2(_swing_dir * (52 if demon else 42), -4))
	q.collision_mask = 1 | 4
	q.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 16):
		var c = hit.collider
		if c:
			GameState.player_hit(c, DEMON_BLADE_DAMAGE if demon else SWORD_DAMAGE, center())


func in_camp() -> bool:
	var lvl := get_parent()
	return lvl.has_method("is_safe") and lvl.is_safe(center())


func take_damage(amount: int, from: Vector2) -> void:
	if _invuln > 0.0 or dead:
		return
	if in_camp() and amount < 999:
		return
	if shield_time > 0.0 and amount < 999:
		return
	hp = maxi(hp - amount, 0)
	_invuln = 1.0
	var away := signf(global_position.x - from.x)
	_knock_x = (away if away != 0.0 else -facing) * 380.0
	velocity.y = -320.0
	hp_changed.emit(hp, max_hp)
	if hp <= 0:
		dead = true
		died.emit()


func _draw() -> void:
	var look := GameState.hero_look()
	if dead:
		Characters.draw(self, look, Vector2.ZERO, 1.0, "fallen", facing, _t)
		return
	if _invuln > 0.0 and int(_invuln * 12) % 2 == 0:
		return
	if _dash_time > 0.0:
		for k in 3:
			Characters.draw(self, look, Vector2(-facing * (k + 1) * 18, 0), 1.0, "stand", facing, _t, false)
		draw_rect(Rect2(-facing * 70 - 20, -48, 70, 48), Color(0.35, 1.0, 0.45, 0.25))
	Characters.draw(self, look, Vector2.ZERO, 1.0, "stand", facing, _t, false)
	if shield_time > 0.0:
		var a := 0.25 + 0.1 * sin(_t * 10.0)
		if shield_time < 0.6 and int(shield_time * 15) % 2 == 0:
			a *= 0.4
		draw_circle(Vector2(0, -24), 40, Color(0.45, 0.85, 1.0, a))
		draw_arc(Vector2(0, -24), 40, 0, TAU, 32, Color(0.7, 0.95, 1.0, 0.9), 3.0)
	if _camp_hint > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-90, -64), "В лагере не сражаются", HORIZONTAL_ALIGNMENT_CENTER, 180, 14, Color(0.2, 0.45, 0.25))
	# оружие в руке — крупнее, чтобы его было хорошо видно
	var id := GameState.selected_item_id()
	if id == "sword" or id == "demon_blade":
		_draw_sword(id == "demon_blade")
	elif id == "bow":
		_draw_bow()
	elif id == "warglaives":
		_draw_glaives()
	elif id != "":
		Items.draw_icon(self, id, Rect2(Vector2(facing * 16 - 15, -34), Vector2(30, 30)))


func _draw_sword(demon := false) -> void:
	var hand := Vector2(facing * 10, -24)
	var blade_len := SWORD_LEN * (1.25 if demon else 1.0)
	var angle: float
	if _swing > 0.0:
		var t := 1.0 - _swing / SWING_TIME
		angle = lerpf(-1.4, 1.1, t)
		if facing > 0:
			draw_arc(hand, blade_len, -1.4, angle, 16, Color(1, 1, 1, 0.55) if not demon else Color(0.6, 0.85, 1.0, 0.7), 3.0)
		else:
			draw_arc(hand, blade_len, PI - angle, PI + 1.4, 16, Color(1, 1, 1, 0.55) if not demon else Color(0.6, 0.85, 1.0, 0.7), 3.0)
	else:
		angle = -1.0
	var d := Vector2(cos(angle) * facing, sin(angle))
	var guard := hand + d * 10
	draw_line(hand - d * 6, guard, Color(0.4, 0.26, 0.12), 6.0)  # рукоять
	draw_line(guard - d.orthogonal() * 9, guard + d.orthogonal() * 9, Color(0.55, 0.45, 0.2), 5.0)  # гарда
	if demon:
		# демонический клинок: тёмная сталь со светящейся жилой Слезы Луны
		draw_line(guard, hand + d * blade_len, Color(0.6, 0.85, 1.0, 0.25), 15.0)
		draw_line(guard, hand + d * blade_len, Color(0.3, 0.04, 0.08), 9.0)
		draw_line(guard, hand + d * blade_len, Color(0.6, 0.85, 1.0), 2.5)
		draw_circle(guard, 4, Color(0.6, 0.85, 1.0))
	else:
		draw_line(guard, hand + d * SWORD_LEN, Color(0.82, 0.84, 0.9), 7.0)  # клинок
		draw_line(guard, hand + d * SWORD_LEN, Color(1, 1, 1, 0.6), 2.0)


func _draw_glaives() -> void:
	var t := 1.0 - _swing / SWING_TIME if _swing > 0.0 else 0.0
	if _swing > 0.0:
		# удар: передний серп описывает дугу, задний — бьёт назад
		var a := lerpf(-1.5, 1.2, t)
		Characters.draw_warglaive(self, Vector2(facing * 22, -26) + Vector2(cos(a) * facing, sin(a)) * 14, a * facing + (0.0 if facing > 0 else PI), 1.1, _t)
		Characters.draw_warglaive(self, Vector2(-facing * 18, -24), PI / 2 + facing * (2.0 - t * 2.5), 1.0, _t)
		draw_arc(Vector2(facing * 10, -26), 52, -1.5 if facing > 0 else PI - 1.2, 1.2 if facing > 0 else PI + 1.5, 14, Color(0.35, 1.0, 0.45, 0.6), 3.0)
	else:
		Characters.draw_warglaive(self, Vector2(facing * 16, -24), -PI / 2 + facing * 0.35, 1.0, _t)
		Characters.draw_warglaive(self, Vector2(-facing * 14, -26), -PI / 2 - facing * 0.35, 1.0, _t)


func _draw_bow() -> void:
	var c := Vector2(facing * 16, -26)
	var aim := (get_global_mouse_position() - center()).normalized()
	if aim == Vector2.ZERO or signf(aim.x) != facing:
		aim = Vector2(facing, 0)
	var a := aim.angle()
	draw_arc(c, 22, a - 1.3, a + 1.3, 16, Color(0.5, 0.3, 0.12), 5.0)
	var top := c + Vector2.from_angle(a - 1.3) * 22
	var bot := c + Vector2.from_angle(a + 1.3) * 22
	var pull := c - aim * (14.0 if _swing <= 0.0 else 4.0)
	draw_polyline(PackedVector2Array([top, pull, bot]), Color(0.15, 0.15, 0.15), 1.5)
	if _swing <= 0.0:
		draw_line(pull, c + aim * 24, Color(0.15, 0.15, 0.15), 2.5)
