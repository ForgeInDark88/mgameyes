extends Node2D
## Житель. Когда игрок подходит, говорит свои реплики (один раз).

const Characters := preload("res://scripts/data/characters.gd")

var lines: Array = []
var look := "smith"
var _talked := false
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()
	if _talked or lines.is_empty():
		return
	var p := get_tree().get_first_node_in_group("player")
	if p and p.global_position.distance_to(global_position) < 90.0:
		_talked = true
		var lvl := get_parent()
		if lvl.has_method("goal_text"):
			lvl.hud.dialog.show_lines(lines)


func _draw() -> void:
	if look == "smith_wounded":
		# раненый кузнец лежит на земле
		draw_rect(Rect2(-26, -16, 52, 16), Color(0.35, 0.45, 0.75))
		draw_rect(Rect2(-6, -16, 22, 16), Color(0.45, 0.3, 0.18))
		draw_rect(Rect2(-34, -14, 10, 10), Color(0.75, 0.75, 0.75))
		draw_rect(Rect2(-26, -16, 52, 16), Color(0.15, 0.2, 0.35), false, 2.0)
		draw_circle(Vector2(10, -2), 6, Color(0.7, 0.05, 0.05, 0.7))
	else:
		Characters.draw(self, look, Vector2.ZERO, 1.0, "stand", -1, _t)
	if not _talked and not lines.is_empty():
		var y := -70 + sin(_t * 4.0) * 3.0
		draw_string(ThemeDB.fallback_font, Vector2(-6, y), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, Color(0.9, 0.6, 0.0))
