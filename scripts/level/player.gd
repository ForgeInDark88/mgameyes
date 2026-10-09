extends CharacterBody2D
## Игрок — зелёный прямоугольник с концепта.

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

var max_hp := 6
var hp := 6
var facing := 1
var dead := false

var _air_jumps := 0
var _coyote := 0.0
var _invuln := 0.0
var _cooldown := 0.0
var _knock_x := 0.0
var _swing := 0.0
var _swing_dir := 1


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
	queue_redraw()
	if dead:
		return

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
	match id:
		"sword":
			_sword_attack(aim)
			_cooldown = 0.3
		"bow":
			var p := ProjectileScript.new()
			p.setup(aim * 750.0, 1, 1 | 4, Color(0.15, 0.15, 0.15))
			p.global_position = center() + aim * 20
			get_parent().add_child(p)
			_cooldown = 0.35
		"potion":
			if just_pressed and hp < max_hp:
				hp = mini(hp + 3, max_hp)
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
	_swing = 0.18
	var shape := RectangleShape2D.new()
	shape.size = Vector2(48, 56)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, center() + Vector2(_swing_dir * 34, 0))
	q.collision_mask = 1 | 4
	q.exclude = [get_rid()]
	for hit in get_world_2d().direct_space_state.intersect_shape(q, 16):
		var c = hit.collider
		if c and c.has_method("take_damage"):
			c.take_damage(1, center())


func take_damage(amount: int, from: Vector2) -> void:
	if _invuln > 0.0 or dead:
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
	# предмет в руке
	var id := GameState.selected_item_id()
	if id != "" and _swing <= 0.0:
		Items.draw_icon(self, id, Rect2(Vector2(facing * 14 - 10, -30), Vector2(20, 20)))
	if _swing > 0.0:
		var t := 1.0 - _swing / 0.18
		var a := lerpf(-1.2, 1.2, t)
		var base := Vector2(_swing_dir * 10, -24)
		var tip := base + Vector2(_swing_dir * cos(a), sin(a)) * 40
		draw_line(base, tip, Color(0.85, 0.87, 0.92), 5.0)
		draw_arc(base, 40, -1.2 if _swing_dir > 0 else PI - 1.2, (1.2 if _swing_dir > 0 else PI + 1.2), 12, Color(1, 1, 1, 0.5), 2.0)
