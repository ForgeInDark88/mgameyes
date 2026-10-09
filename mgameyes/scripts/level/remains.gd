extends Node2D
## Фигура побеждённого персонажа: остаётся на уровне после боя.

const Characters := preload("res://scripts/data/characters.gd")

var look := "liael"
var pose := "kneel"
var label := ""
var facing := 1


func _ready() -> void:
	z_index = -1
	# опустить фигуру на землю (если враг погиб в воздухе)
	var q := PhysicsRayQueryParameters2D.create(global_position + Vector2(0, -4), global_position + Vector2(0, 1200), 1)
	var hit := get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		global_position = hit.position


func _draw() -> void:
	Characters.draw(self, look, Vector2.ZERO, 1.4, pose, facing)
	if label != "":
		draw_string(ThemeDB.fallback_font, Vector2(-80, -Characters.height(look) * 1.4 - 12), label, HORIZONTAL_ALIGNMENT_CENTER, 160, 14, Color(0.15, 0.15, 0.15))
