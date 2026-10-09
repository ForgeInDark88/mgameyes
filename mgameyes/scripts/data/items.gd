extends RefCounted
## База предметов. Каждый предмет даёт что-то своё.
## Чтобы добавить новый предмет: допиши его сюда, нарисуй иконку в draw_icon()
## и обработай использование в player.gd (_use_selected_item).

const DATA := {
	"sword": {
		"name": "Меч",
		"desc": "Ближний бой, 10 урона. Ломает ящики и решётки.",
		"kind": "weapon",
	},
	"bow": {
		"name": "Лук разведчика",
		"desc": "Стрелы в сторону курсора, 8 урона.",
		"kind": "weapon",
	},
	"potion": {
		"name": "Зелье лечения",
		"desc": "Восстанавливает 40 здоровья.",
		"kind": "consumable",
	},
	"bomb": {
		"name": "Бомба",
		"desc": "Взрыв: 30 урона, ломает блоки.",
		"kind": "consumable",
	},
	"boots": {
		"name": "Эльфийские сапоги",
		"desc": "Пассивно: двойной прыжок.",
		"kind": "passive",
	},
	"amulet": {
		"name": "Амулет лекаря",
		"desc": "Пассивно: восстанавливает 2 HP в секунду.",
		"kind": "passive",
	},
	"heart": {
		"name": "Сердце Разлома",
		"desc": "Пассивно: +30 к максимальному здоровью.",
		"kind": "passive",
	},
}


static func get_item(id: String) -> Dictionary:
	return DATA.get(id, {"name": id, "desc": "", "kind": "passive"})


static func is_stackable(id: String) -> bool:
	return get_item(id).kind == "consumable"


## Рисует иконку предмета в прямоугольнике rect на любом CanvasItem.
static func draw_icon(ci: CanvasItem, id: String, rect: Rect2) -> void:
	var c := rect.get_center()
	var s := rect.size.x / 64.0
	match id:
		"sword":
			ci.draw_line(c + Vector2(-16, 16) * s, c + Vector2(18, -18) * s, Color(0.8, 0.82, 0.88), 6 * s)
			ci.draw_line(c + Vector2(-18, 4) * s, c + Vector2(-4, 18) * s, Color(0.45, 0.3, 0.15), 5 * s)
			ci.draw_line(c + Vector2(-16, 16) * s, c + Vector2(-22, 22) * s, Color(0.45, 0.3, 0.15), 5 * s)
		"bow":
			# лук как на концепте: дуга, тетива и стрела вправо
			ci.draw_arc(c + Vector2(-6, 0) * s, 16 * s, -PI / 2, PI / 2, 16, Color(0.5, 0.3, 0.12), 4 * s)
			ci.draw_line(c + Vector2(-6, -16) * s, c + Vector2(-6, 16) * s, Color(0.2, 0.2, 0.2), 1.5 * s)
			ci.draw_line(c + Vector2(-14, 0) * s, c + Vector2(20, 0) * s, Color(0.15, 0.15, 0.15), 2.5 * s)
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(22, 0) * s, c + Vector2(14, -5) * s, c + Vector2(14, 5) * s]), Color(0.15, 0.15, 0.15))
		"potion":
			ci.draw_circle(c + Vector2(0, 5) * s, 14 * s, Color(0.15, 0.55, 0.95))
			ci.draw_rect(Rect2(c + Vector2(-4, -17) * s, Vector2(8, 10) * s), Color(0.7, 0.85, 0.95))
			ci.draw_circle(c + Vector2(-5, 1) * s, 4 * s, Color(1, 1, 1, 0.6))
		"bomb":
			ci.draw_circle(c + Vector2(0, 4) * s, 14 * s, Color(0.15, 0.15, 0.18))
			ci.draw_line(c + Vector2(6, -8) * s, c + Vector2(12, -18) * s, Color(0.6, 0.45, 0.2), 3 * s)
			ci.draw_circle(c + Vector2(13, -19) * s, 4 * s, Color(1, 0.6, 0.1))
		"boots":
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-12, -18) * s, c + Vector2(2, -18) * s, c + Vector2(2, 6) * s,
				c + Vector2(18, 8) * s, c + Vector2(18, 18) * s, c + Vector2(-12, 18) * s]), Color(0.55, 0.3, 0.7))
			ci.draw_line(c + Vector2(-18, -6) * s, c + Vector2(-26, -2) * s, Color(1, 1, 1), 3 * s)
			ci.draw_line(c + Vector2(-18, 4) * s, c + Vector2(-26, 8) * s, Color(1, 1, 1), 3 * s)
		"amulet":
			ci.draw_arc(c + Vector2(0, -8) * s, 14 * s, PI, TAU, 12, Color(0.75, 0.6, 0.2), 2.5 * s)
			ci.draw_circle(c + Vector2(0, 6) * s, 12 * s, Color(0.85, 0.7, 0.25))
			ci.draw_circle(c + Vector2(0, 6) * s, 7 * s, Color(0.8, 0.1, 0.15))
			ci.draw_circle(c + Vector2(-2, 4) * s, 2.5 * s, Color(1, 0.6, 0.6))
		"heart":
			ci.draw_circle(c + Vector2(-8, -4) * s, 10 * s, Color(0.2, 0.75, 0.35))
			ci.draw_circle(c + Vector2(8, -4) * s, 10 * s, Color(0.2, 0.75, 0.35))
			ci.draw_colored_polygon(PackedVector2Array([
				c + Vector2(-17, 0) * s, c + Vector2(17, 0) * s, c + Vector2(0, 20) * s]), Color(0.2, 0.75, 0.35))
		_:
			ci.draw_rect(rect.grow(-rect.size.x * 0.3), Color(0.5, 0.5, 0.5))
