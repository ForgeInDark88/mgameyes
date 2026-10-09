extends RefCounted
## Навыки героя. Скрытый навык работает с самого начала,
## но в интерфейсе виден как «???», пока сюжет его не раскроет.

const DATA := {
	"erin_blood": {
		"name": "Кровь рода Эрин",
		"desc": "Двойной урон по демонам.",
		"color": Color(0.85, 0.1, 0.15),
	},
}


static func get_skill(id: String) -> Dictionary:
	return DATA.get(id, {"name": id, "desc": "", "color": Color.GRAY})


static func draw_icon(ci: CanvasItem, id: String, rect: Rect2, revealed: bool) -> void:
	var c := rect.get_center()
	var s := rect.size.x / 32.0
	var col: Color = get_skill(id).color if revealed else Color(0.55, 0.55, 0.55)
	# капля крови
	ci.draw_circle(c + Vector2(0, 4) * s, 9 * s, col)
	ci.draw_colored_polygon(PackedVector2Array([
		c + Vector2(-8.5, 1) * s, c + Vector2(0, -13) * s, c + Vector2(8.5, 1) * s]), col)
	if not revealed:
		ci.draw_string(ThemeDB.fallback_font, c + Vector2(-4, 9) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * s), Color.WHITE)
