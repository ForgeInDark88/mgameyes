extends CharacterBody2D
## Игрок (Явален) — зелёный прямоугольник с концепта.

signal hp_changed(hp: int, max_hp: int)
signal died

const Items := preload("res://scripts/data/items.gd")
const ProjectileScript := preload("res://scripts/level/projectile.gd")
const BombScript := preload("res://scripts/level/bomb.gd")

const SIZE := Vector2(24, 48)
const SPEED := 260.0
const JUMP_VELOCITY := -600.0
const GRAVITY := 1500.0
const MAX_FALL := 900.0
const COYOTE_TIME := 0.1

const SWORD_DAMAGE := 10
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
	if id in ["sword", "bow", "bomb"] and in_camp():
		_camp_hint = 1.5
		return
	match id:
		"sword":
			_sword_attack(aim)
			_cooldown = 0.3
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


func _sword_attack(aim: Vector2) -> void:
	_swing_dir = 1 if aim.x >= 0.0 else -1
	facing = _swing_dir
	_swing = SWING_TIME
	var shape := RectangleShape2D.new()
	shape.size = Vector2(64, 72)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, center() + Vector2(_swing_dir * 42, -4))
	q.collision_mask = 1 | 4
	q.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 16):
		var c = hit.collider
		if c:
			GameState.player_hit(c, SWORD_DAMAGE, center())


func in_camp() -> bool:
	var lvl := get_parent()
	return lvl.has_method("is_safe") and lvl.is_safe(center())


func take_damage(amount: int, from: Vector2) -> void:
	if _invuln > 0.0 or dead:
		return
	if in_camp() and amount < 999:
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
	if dead:
		draw_rect(Rect2(-SIZE.y / 2, -SIZE.x, SIZE.y, SIZE.x), Color(0.13, 0.55, 0.25, 0.6))
		return
	if _invuln > 0.0 and int(_invuln * 12) % 2 == 0:
		return
	var body := Rect2(-SIZE.x / 2, -SIZE.y, SIZE.x, SIZE.y)
	draw_rect(body, Color(0.13, 0.7, 0.3))
	draw_rect(body, Color(0.05, 0.3, 0.12), false, 2.0)
	# глаз смотрит в сторону движения
	draw_rect(Rect2(facing * 5 - 2, -40, 5, 6), Color(0.05, 0.15, 0.08))
	if _camp_hint > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-90, -64), "В лагере не сражаются", HORIZONTAL_ALIGNMENT_CENTER, 180, 14, Color(0.2, 0.45, 0.25))
	# оружие в руке — крупнее, чтобы его было хорошо видно
	var id := GameState.selected_item_id()
	if id == "sword":
		_draw_sword()
	elif id == "bow":
		_draw_bow()
	elif id != "":
		Items.draw_icon(self, id, Rect2(Vector2(facing * 16 - 15, -34), Vector2(30, 30)))


func _draw_sword() -> void:
	var hand := Vector2(facing * 10, -24)
	var angle: float
	if _swing > 0.0:
		var t := 1.0 - _swing / SWING_TIME
		angle = lerpf(-1.4, 1.1, t)
		if facing > 0:
			draw_arc(hand, SWORD_LEN, -1.4, angle, 16, Color(1, 1, 1, 0.55), 3.0)
		else:
			draw_arc(hand, SWORD_LEN, PI - angle, PI + 1.4, 16, Color(1, 1, 1, 0.55), 3.0)
	else:
		angle = -1.0
	var d := Vector2(cos(angle) * facing, sin(angle))
	var guard := hand + d * 10
	draw_line(hand - d * 6, guard, Color(0.4, 0.26, 0.12), 6.0)  # рукоять
	draw_line(guard - d.orthogonal() * 9, guard + d.orthogonal() * 9, Color(0.55, 0.45, 0.2), 5.0)  # гарда
	draw_line(guard, hand + d * SWORD_LEN, Color(0.82, 0.84, 0.9), 7.0)  # клинок
	draw_line(guard, hand + d * SWORD_LEN, Color(1, 1, 1, 0.6), 2.0)


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
