extends RefCounted
## Навыки героев.
##   passive — работает всегда. hidden — виден как «???», пока сюжет его не раскроет.
##   active  — применяется клавишей (первый активный навык — Q, второй — R), есть перезарядка.

const DATA := {
	"erin_blood": {
		"name": "Кровь рода Эрин",
		"desc": "Двойной урон по порождениям огня.",
		"kind": "passive",
		"hidden": true,
		"color": Color(0.85, 0.1, 0.15),
	},
	"erin_shield": {
		"name": "Щит рода",
		"desc": "Купол света на 2.5 с: блокирует любой урон.",
		"kind": "active",
		"duration": 2.5,
		"cooldown": 10.0,
		"color": Color(0.45, 0.85, 1.0),
	},
	"blade_vortex": {
		"name": "Вихрь клинков",
		"desc": "Серпы кружат вокруг Тижена: 25 урона всем рядом.",
		"kind": "active",
		"damage": 25,
		"cooldown": 5.0,
		"color": Color(0.35, 1.0, 0.45),
	},
	"hunter_dash": {
		"name": "Рывок охотника",
		"desc": "Рывок вперёд сквозь врагов: 20 урона, неуязвимость в рывке.",
		"kind": "active",
		"damage": 20,
		"cooldown": 6.0,
		"color": Color(0.5, 0.95, 0.6),
	},
	"hunter_mark": {
		"name": "Взгляд охотника",
		"desc": "Урон по порождениям огня +50%.",
		"kind": "passive",
		"color": Color(0.35, 0.95, 0.45),
	},
	"truth_fire": {
		"name": "Огонь правды",
		"desc": "Волна белого огня: 30 урона всем на пути.",
		"kind": "active",
		"damage": 30,
		"cooldown": 6.0,
		"color": Color(1.0, 0.85, 0.4),
	},
	"demon_burn": {
		"name": "Демонический ожог",
		"desc": "Взрыв тьмы вокруг героя: 30 урона.",
		"kind": "active",
		"damage": 30,
		"cooldown": 8.0,
		"color": Color(0.75, 0.05, 0.1),
	},
}

const KEYS := ["Q", "R"]


static func get_skill(id: String) -> Dictionary:
	return DATA.get(id, {"name": id, "desc": "", "kind": "passive", "color": Color.GRAY})


static func is_active(id: String) -> bool:
	return get_skill(id).kind == "active"


static func draw_icon(ci: CanvasItem, id: String, rect: Rect2, revealed: bool) -> void:
	var c := rect.get_center()
	var s := rect.size.x / 32.0
	var col: Color = get_skill(id).color if revealed else Color(0.55, 0.55, 0.55)
	match id:
		"truth_fire":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 11) * s, c + Vector2(0, -13) * s, c + Vector2(9, 11) * s]), col)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 11) * s, c + Vector2(0, -2) * s, c + Vector2(4, 11) * s]), Color.WHITE)
		"blade_vortex":
			ci.draw_arc(c, 11 * s, 0, TAU * 0.8, 16, col, 3 * s)
			ci.draw_circle(c + Vector2(11, 0) * s, 3 * s, col)
			ci.draw_circle(c + Vector2(-8, -8) * s, 3 * s, col)
		"hunter_dash":
			for k in 3:
				ci.draw_line(c + Vector2(-12, -6 + k * 6) * s, c + Vector2(4, -6 + k * 6) * s, col, 2 * s)
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(4, -10) * s, c + Vector2(13, 0) * s, c + Vector2(4, 10) * s]), col)
		"hunter_mark":
			ci.draw_rect(Rect2(c + Vector2(-12, -3) * s, Vector2(24, 6) * s), col)
			ci.draw_circle(c, 4 * s, Color.WHITE)
		"erin_shield":
			ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-11, -12) * s, c + Vector2(11, -12) * s,
				c + Vector2(11, 2) * s, c + Vector2(0, 13) * s, c + Vector2(-11, 2) * s]), col)
			ci.draw_line(c + Vector2(0, -10) * s, c + Vector2(0, 9) * s, Color.WHITE, 2 * s)
		"demon_burn":
			ci.draw_circle(c, 12 * s, Color(0.1, 0.0, 0.0))
			ci.draw_arc(c, 12 * s, 0, TAU, 16, col, 3 * s)
			ci.draw_circle(c, 5 * s, col)
		_:
			# капля крови
			ci.draw_circle(c + Vector2(0, 4) * s, 9 * s, col)
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-8.5, 1) * s, c + Vector2(0, -13) * s, c + Vector2(8.5, 1) * s]), col)
	if not revealed:
		ci.draw_string(ThemeDB.fallback_font, c + Vector2(-4, 9) * s, "?", HORIZONTAL_ALIGNMENT_LEFT, -1, int(16 * s), Color.WHITE)
