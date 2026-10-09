extends Node2D
## Всплывающая цифра урона.

var text := ""
var color := Color.WHITE
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	position.y -= 40.0 * delta
	modulate.a = 1.0 - _t / 0.8
	if _t >= 0.8:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_string_outline(f, Vector2(-20, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 40, 18, 4, Color(0, 0, 0, 0.8))
	draw_string(f, Vector2(-20, 0), text, HORIZONTAL_ALIGNMENT_CENTER, 40, 18, color)
