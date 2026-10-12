@tool
extends Node2D
## «Помеха»: голос, который герой слышит, дойдя до этого места (по горизонтали).

## Реплики. Каждая строка: «Имя: текст».
@export_multiline var dialog := "":
	set(v):
		dialog = v
		queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var col := Color(0.55, 0.2, 0.85)
	for i in 12:
		draw_line(Vector2(0, -i * 32), Vector2(0, -i * 32 - 18), col, 3.0)
	var first := dialog.strip_edges().get_slice("\n", 0)
	draw_string(ThemeDB.fallback_font, Vector2(6, -20), "голос: " + first.left(30), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, col)
