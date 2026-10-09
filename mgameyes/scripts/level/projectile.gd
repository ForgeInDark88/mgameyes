extends Area2D
## Снаряд: стрела (летит с небольшой гравитацией) или огненный шар демонов.

const Characters := preload("res://scripts/data/characters.gd")

var velocity := Vector2.ZERO
var damage := 10
var color := Color.BLACK
var from_player := false
var fire := false
## "arrow", "fire" (огненный шар), "truth" (волна Огня правды — пробивает врагов), "magic" (сфера мага)
var kind := "arrow"
var _hit := []
var _life := 3.0
var _t := 0.0


func setup(vel: Vector2, dmg: int, mask: int, col: Color) -> void:
	velocity = vel
	damage = dmg
	collision_layer = 0
	collision_mask = mask
	color = col


func _ready() -> void:
	if fire and kind == "arrow":
		kind = "fire"
	var cs := CollisionShape2D.new()
	if kind == "truth":
		var r := RectangleShape2D.new()
		r.size = Vector2(40, 64)
		cs.shape = r
		_life = 1.2
	elif fire or kind == "magic":
		var c := CircleShape2D.new()
		c.radius = 8
		cs.shape = c
	else:
		var shape := RectangleShape2D.new()
		shape.size = Vector2(14, 4)
		cs.shape = shape
	add_child(cs)
	body_entered.connect(_on_body_entered)
	rotation = velocity.angle() if kind != "truth" else 0.0


func _physics_process(delta: float) -> void:
	_t += delta
	if kind == "arrow":
		velocity.y += 200.0 * delta
	position += velocity * delta
	rotation = velocity.angle() if kind != "truth" else 0.0
	_life -= delta
	if _life <= 0.0:
		queue_free()
	if kind != "arrow":
		queue_redraw()


func _on_body_entered(body: Node) -> void:
	if kind == "truth" and not from_player:
		# волна Огня правды, выпущенная врагом (Париус)
		if body.is_in_group("player"):
			if not body in _hit:
				_hit.append(body)
				body.take_damage(damage, global_position - velocity.normalized() * 20)
			return
		queue_free()
		return
	if kind == "truth":
		# волна проходит сквозь врагов, но гаснет о стены
		if body.is_in_group("enemies"):
			if not body in _hit:
				_hit.append(body)
				GameState.player_hit(body, damage, global_position - velocity.normalized() * 20)
			return
		queue_free()
		return
	# стрелы не ломают блоки — для этого есть меч и бомбы
	if body.has_method("take_damage") and not body.is_in_group("breakable"):
		var from := global_position - velocity.normalized() * 20
		if from_player:
			GameState.player_hit(body, damage, from)
		else:
			body.take_damage(damage, from)
	queue_free()


func _draw() -> void:
	if kind == "truth":
		var dir := signf(velocity.x)
		for i in 5:
			var y := -28.0 + i * 14.0
			var len := 26.0 + sin(_t * 30.0 + i) * 8.0
			draw_colored_polygon(PackedVector2Array([Vector2(-dir * 10, y - 6), Vector2(dir * len, y), Vector2(-dir * 10, y + 6)]), Color(1, 0.85, 0.4, 0.85))
		draw_rect(Rect2(-6, -32, 12, 64), Color(1, 1, 0.9, 0.8))
		return
	if kind == "glaive":
		Characters.draw_warglaive(self, Vector2.ZERO, _t * 20.0, 1.0, _t)
		return
	if kind == "magic":
		draw_circle(Vector2.ZERO, 9, Color(0.6, 0.8, 1.0, 0.6))
		draw_circle(Vector2.ZERO, 5, Color.WHITE)
		return
	if fire:
		var flick := 1.0 + sin(_t * 30.0) * 0.15
		draw_circle(Vector2(-6, 0), 7 * flick, Color(1, 0.4, 0.05, 0.5))
		draw_circle(Vector2.ZERO, 8 * flick, Color(1, 0.35, 0.05))
		draw_circle(Vector2(2, 0), 4, Color(1, 0.9, 0.4))
		return
	draw_line(Vector2(-12, 0), Vector2(8, 0), color, 2.5)
	draw_colored_polygon(PackedVector2Array([Vector2(12, 0), Vector2(5, -4), Vector2(5, 4)]), color)
	draw_line(Vector2(-12, 0), Vector2(-16, -4), color, 1.5)
	draw_line(Vector2(-12, 0), Vector2(-16, 4), color, 1.5)
