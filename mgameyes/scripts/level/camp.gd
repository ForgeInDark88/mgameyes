extends Node2D
## Лагерь у точки старта — безопасная зона (см. level.safe_rect).

var _t := 0.0


func _ready() -> void:
	z_index = -1


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _draw() -> void:
	var lvl := get_parent()
	if lvl and lvl.get("safe_rect") is Rect2:
		var r: Rect2 = lvl.safe_rect
		r.position -= position
		draw_rect(r, Color(0.3, 0.8, 0.4, 0.07))
		draw_rect(r, Color(0.3, 0.7, 0.4, 0.35), false, 2.0)
	# костёр
	draw_line(Vector2(-12, 0), Vector2(12, -6), Color(0.4, 0.25, 0.1), 5.0)
	draw_line(Vector2(-12, -6), Vector2(12, 0), Color(0.4, 0.25, 0.1), 5.0)
	var f := 1.0 + sin(_t * 12.0) * 0.15
	draw_colored_polygon(PackedVector2Array([Vector2(-9, -4), Vector2(0, -26 * f), Vector2(9, -4)]), Color(1, 0.5, 0.1))
	draw_colored_polygon(PackedVector2Array([Vector2(-5, -4), Vector2(0, -16 * f), Vector2(5, -4)]), Color(1, 0.9, 0.4))
	draw_string(ThemeDB.fallback_font, Vector2(-100, -70), "Лагерь — безопасно", HORIZONTAL_ALIGNMENT_CENTER, 200, 14, Color(0.2, 0.45, 0.25))
