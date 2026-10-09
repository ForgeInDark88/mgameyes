extends CharacterBody2D
## Общая логика врагов: здоровье, получение урона, смерть.

signal died

var max_hp := 3
var hp := 3
var _flash := 0.0
var _knock := Vector2.ZERO
var _dying := false


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1
	hp = max_hp


func get_player() -> Node2D:
	return get_tree().get_first_node_in_group("player")


func can_see(target: Vector2, from: Vector2) -> bool:
	var q := PhysicsRayQueryParameters2D.create(from, target, 1)
	return get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func take_damage(amount: int, from: Vector2) -> void:
	if _dying:
		return
	hp -= amount
	_flash = 0.15
	_knock = (global_position - from).normalized() * 260.0
	if hp <= 0:
		_dying = true
		died.emit()
		queue_free()


func tick_effects(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_knock = _knock.move_toward(Vector2.ZERO, 900.0 * delta)
	queue_redraw()


func body_color(base: Color) -> Color:
	return Color.WHITE if _flash > 0.0 else base


func draw_hp_bar(y: float) -> void:
	if hp >= max_hp:
		return
	draw_rect(Rect2(-16, y, 32, 4), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-16, y, 32.0 * hp / max_hp, 4), Color(0.9, 0.2, 0.2))
