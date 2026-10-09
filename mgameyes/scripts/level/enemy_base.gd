extends CharacterBody2D
## Общая логика врагов: здоровье, урон, смерть.
## variant: "elf" — эльфы, "demon" — демоны (по ним бьёт Кровь рода Эрин).

signal died

const DamageNumber := preload("res://scripts/level/damage_number.gd")

var variant := "demon"
var max_hp := 30
var hp := 30
var touch_damage := 15
var _flash := 0.0
var _knock := Vector2.ZERO
var _dying := false
var _blood_glow := 0.0


func _ready() -> void:
	add_to_group("enemies")
	if variant == "demon":
		add_to_group("demons")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func can_see(target: Vector2, from: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(from, target, 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


## Игрок в лагере у точки старта — его не трогаем.
func player_safe(player: Node2D) -> bool:
	var lvl := get_parent()
	return lvl.has_method("is_safe") and lvl.is_safe(player.center())


func in_safe_zone(pos: Vector2) -> bool:
	var lvl := get_parent()
	return lvl.has_method("is_safe") and lvl.is_safe(pos)


func take_damage(amount: int, from: Vector2, blood := false) -> void:
	if _dying:
		return
	hp -= amount
	_flash = 0.15
	if blood:
		_blood_glow = 0.4
	_knock = (global_position - from).normalized() * 260.0
	var n := DamageNumber.new()
	n.text = str(amount)
	n.color = Color(1, 0.25, 0.2) if blood else Color.WHITE
	n.position = global_position + Vector2(randf_range(-10, 10), -50)
	get_parent().add_child(n)
	if hp <= 0:
		_dying = true
		died.emit()
		queue_free()


func tick_effects(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_blood_glow = maxf(_blood_glow - delta, 0.0)
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
	queue_redraw()


func body_color(base: Color) -> Color:
	return Color.WHITE if _flash > 0.0 else base


func draw_blood_glow(radius: float, center := Vector2.ZERO) -> void:
	if _blood_glow > 0.0:
		draw_circle(center, radius, Color(0.9, 0.05, 0.1, _blood_glow))


func draw_hp_bar(y: float, w := 36.0) -> void:
	if hp >= max_hp:
		return
	draw_rect(Rect2(-w / 2, y, w, 5), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-w / 2, y, w * hp / max_hp, 5), Color(0.9, 0.2, 0.2))


func touch_player(player: Node2D, my_rect: Rect2) -> void:
	if player_safe(player):
		return
	var them := Rect2(player.global_position - Vector2(12, 48), Vector2(24, 48))
	if my_rect.intersects(them):
		player.take_damage(touch_damage, global_position)
