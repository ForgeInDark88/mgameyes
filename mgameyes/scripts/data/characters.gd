extends RefCounted
## Внешность сюжетных персонажей. Рисуются кодом в катсценах, жителями на уровнях
## и «телами» побеждённых боссов. feet — точка ног, s — масштаб.
## pose: "stand" — стоит, "kneel" — на коленях, "fallen" — лежит.

const LOOKS := {
	"yavalen": {"body": Color(0.13, 0.7, 0.3), "line": Color(0.05, 0.3, 0.12), "h": 48},
	"father": {"body": Color(0.45, 0.4, 0.5), "line": Color(0.2, 0.18, 0.25), "h": 60, "beard": Color(0.9, 0.9, 0.9), "staff": true},
	"smith": {"body": Color(0.35, 0.45, 0.75), "line": Color(0.15, 0.2, 0.35), "h": 50, "apron": Color(0.45, 0.3, 0.18), "beard": Color(0.55, 0.35, 0.2)},
	"farmer": {"body": Color(0.7, 0.6, 0.35), "line": Color(0.35, 0.28, 0.12), "h": 46},
	"prisoner": {"body": Color(0.55, 0.5, 0.45), "line": Color(0.3, 0.27, 0.24), "h": 46, "chains": true},
	"old_man": {"body": Color(0.5, 0.42, 0.35), "line": Color(0.25, 0.2, 0.15), "h": 50, "beard": Color(0.92, 0.92, 0.92), "hair": Color(0.92, 0.92, 0.92), "staff": true, "chains": true},
	"parius": {"body": Color(0.28, 0.28, 0.32), "line": Color(0.1, 0.1, 0.12), "h": 54, "cape": Color(0.6, 0.08, 0.08), "helmet": Color(0.45, 0.45, 0.5)},
	"parius_demon": {"body": Color(0.16, 0.12, 0.14), "line": Color(0.05, 0.0, 0.0), "h": 54, "cape": Color(0.35, 0.02, 0.02), "helmet": Color(0.2, 0.15, 0.15), "eyes": Color(1, 0.2, 0.1), "aura": Color(0.8, 0.1, 0.05)},
	"parius_possessed": {"body": Color(0.08, 0.06, 0.1), "line": Color(0.0, 0.0, 0.0), "h": 58, "cape": Color(0.15, 0.05, 0.25), "helmet": Color(0.12, 0.1, 0.16), "eyes": Color(0.85, 0.95, 1.0), "aura": Color(0.45, 0.2, 0.9)},
	"tizhen": {"body": Color(0.3, 0.26, 0.36), "line": Color(0.12, 0.1, 0.16), "h": 54, "cape": Color(0.12, 0.3, 0.2), "ears": true, "long_hair": Color(0.1, 0.08, 0.12), "blindfold": Color(0.35, 0.95, 0.45), "glaives": true},
	"dis": {"body": Color(0.3, 0.45, 0.75), "line": Color(0.12, 0.2, 0.4), "h": 52, "cape": Color(0.85, 0.75, 0.3), "hair": Color(0.85, 0.65, 0.3)},
	"elf": {"body": Color(0.25, 0.65, 0.65), "line": Color(0.1, 0.3, 0.3), "h": 46, "ears": true},
	"elf_child": {"body": Color(0.35, 0.75, 0.7), "line": Color(0.1, 0.3, 0.3), "h": 30, "ears": true, "hair": Color(0.95, 0.9, 0.6)},
	"liael": {"body": Color(0.2, 0.55, 0.6), "line": Color(0.08, 0.25, 0.3), "h": 50, "ears": true, "long_hair": Color(0.95, 0.85, 0.45), "cape": Color(0.85, 0.85, 0.95)},
	"elf_mage": {"body": Color(0.45, 0.3, 0.65), "line": Color(0.2, 0.1, 0.3), "h": 54, "ears": true, "long_hair": Color(0.9, 0.9, 0.95), "staff": true},
}

const NAMES := {
	"yavalen": "Явален", "father": "Отец", "smith": "Кузнец", "farmer": "Крестьянин",
	"prisoner": "Пленник", "old_man": "Старик", "parius": "Париус", "parius_demon": "Париус",
	"dis": "Дис", "tizhen": "Тижен", "parius_possessed": "Пегрус", "elf": "Эльф", "elf_child": "Эльфёнок", "liael": "Лиаэль", "elf_mage": "Верховный маг",
}


static func height(id: String) -> float:
	return LOOKS.get(id, LOOKS.farmer).h


static func draw(ci: CanvasItem, id: String, feet: Vector2, s := 1.0, pose := "stand", facing := 1, t := 0.0, weapons := true) -> void:
	var L: Dictionary = LOOKS.get(id, LOOKS.farmer)
	var h: float = L.h
	var w := 26.0 if h >= 40 else 18.0
	if pose == "fallen":
		_draw_fallen(ci, L, feet, s, facing)
		return
	var squash := 0.62 if pose == "kneel" else 1.0
	var bh := h * squash
	if L.has("aura"):
		var a: Color = L.aura
		a.a = 0.25 + 0.1 * sin(t * 5.0)
		ci.draw_circle(feet + Vector2(0, -bh / 2) * s, (bh * 0.8) * s, a)
	if L.has("cape"):
		ci.draw_colored_polygon(PackedVector2Array([
			feet + Vector2(-facing * 4, -bh + 8) * s, feet + Vector2(-facing * (w / 2 + 10), -6) * s,
			feet + Vector2(-facing * (w / 2 - 2), -bh + 4) * s]), L.cape)
	if L.has("long_hair"):
		# длинные волосы ниспадают за спину
		ci.draw_rect(Rect2(feet + Vector2(-w / 2 - 7, -bh - 4) * s, Vector2(w + 14, bh * 0.85) * s), L.long_hair)
		ci.draw_colored_polygon(PackedVector2Array([
			feet + Vector2(-facing * (w / 2 + 6), -bh) * s,
			feet + Vector2(-facing * (w / 2 + 20), -bh * 0.1) * s,
			feet + Vector2(-facing * (w / 2 - 2), -bh * 0.2) * s]), L.long_hair)
	var body := Rect2(feet + Vector2(-w / 2, -bh) * s, Vector2(w, bh) * s)
	ci.draw_rect(body, L.body)
	if L.has("apron"):
		ci.draw_rect(Rect2(feet + Vector2(-w / 2 + 2, -bh * 0.6) * s, Vector2(w - 4, bh * 0.6) * s), L.apron)
	if L.has("chains"):
		ci.draw_line(feet + Vector2(-w / 2, -bh * 0.45) * s, feet + Vector2(w / 2, -bh * 0.45) * s, Color(0.35, 0.35, 0.38), 3.0 * s)
	ci.draw_rect(body, L.line, false, 2.0)
	if L.has("helmet"):
		ci.draw_rect(Rect2(feet + Vector2(-w / 2 - 1, -bh - 4) * s, Vector2(w + 2, 14) * s), L.helmet)
		ci.draw_rect(Rect2(feet + Vector2(facing * 2 - 1, -bh + 2) * s, Vector2(facing * 9, 3) * s).abs(), Color(0.05, 0.05, 0.05))
	if L.has("hair"):
		ci.draw_rect(Rect2(feet + Vector2(-w / 2, -bh - 3) * s, Vector2(w, 7) * s), L.hair)
	if L.has("long_hair"):
		# чёлка и прядь у лица
		ci.draw_rect(Rect2(feet + Vector2(-w / 2 - 3, -bh - 5) * s, Vector2(w + 6, 9) * s), L.long_hair)
		ci.draw_rect(Rect2(feet + Vector2(facing * (w / 2 - 3) - 3, -bh + 2) * s, Vector2(6, 18) * s), L.long_hair)
	if L.has("ears"):
		ci.draw_colored_polygon(PackedVector2Array([feet + Vector2(-facing * w / 2, -bh + 12) * s,
			feet + Vector2(-facing * (w / 2 + 11), -bh + 3) * s, feet + Vector2(-facing * w / 2, -bh + 18) * s]), Color(0.95, 0.85, 0.7))
	if L.has("beard"):
		ci.draw_rect(Rect2(feet + Vector2(facing * 1 - 7, -bh + 14) * s, Vector2(14, 12) * s), L.beard)
	var eye := Color(0.05, 0.05, 0.05)
	if L.has("eyes"):
		eye = L.eyes
	if L.has("blindfold"):
		# повязка на глазах, светится зелёным
		ci.draw_rect(Rect2(feet + Vector2(-w / 2 - 1, -bh + 7) * s, Vector2(w + 2, 6) * s), L.blindfold)
		ci.draw_line(feet + Vector2(-facing * (w / 2), -bh + 10) * s, feet + Vector2(-facing * (w / 2 + 10), -bh + 16) * s, L.blindfold, 2.0 * s)
	else:
		ci.draw_rect(Rect2(feet + Vector2(facing * 6 - 2, -bh + 8) * s, Vector2(5, 5) * s), eye)
	if L.has("staff"):
		ci.draw_line(feet + Vector2(facing * (w / 2 + 6), -bh - 14) * s, feet + Vector2(facing * (w / 2 + 6), 0) * s, Color(0.4, 0.28, 0.15), 4.0 * s)
		if id == "elf_mage":
			ci.draw_circle(feet + Vector2(facing * (w / 2 + 6), -bh - 18) * s, 7 * s, Color(0.7, 0.85, 1.0))
	if L.has("glaives") and weapons and pose != "fallen":
		# два клинка-серпа в руках, лезвиями вверх-вниз
		draw_warglaive(ci, feet + Vector2(facing * (w / 2 + 4), -bh * 0.45) * s, -PI / 2 + facing * 0.35, s * 0.9, t)
		draw_warglaive(ci, feet + Vector2(-facing * (w / 2 + 2), -bh * 0.5) * s, -PI / 2 - facing * 0.35, s * 0.9, t)


## Двусторонний клинок-серп (как боевые глефы охотника на демонов):
## рукоять посередине, два изогнутых лезвия на концах, зелёное свечение.
static func draw_warglaive(ci: CanvasItem, c: Vector2, angle: float, s := 1.0, t := 0.0) -> void:
	var u := Vector2.from_angle(angle)
	var v := u.orthogonal()
	var glow := Color(0.35, 1.0, 0.45, 0.35 + 0.15 * sin(t * 6.0))
	for side in [1, -1]:
		var su: Vector2 = u * side
		var sv: Vector2 = v * side
		var pts := PackedVector2Array([
			c + (su * 7 + sv * 3) * s, c + (su * 16 + sv * 11) * s, c + (su * 30 + sv * 10) * s,
			c + (su * 40 - sv * 2) * s, c + (su * 27 + sv * 1) * s, c + (su * 15 - sv * 3) * s, c + (su * 7 - sv * 3) * s])
		ci.draw_colored_polygon(pts, Color(0.8, 0.85, 0.9))
		var outline := pts.duplicate()
		outline.append(pts[0])
		ci.draw_polyline(outline, glow, 2.5 * s)
		# шип на внутренней стороне лезвия
		ci.draw_colored_polygon(PackedVector2Array([c + (su * 13 - sv * 3) * s, c + (su * 18 - sv * 10) * s, c + (su * 20 - sv * 3) * s]), Color(0.7, 0.75, 0.8))
	# рукоять с обмоткой
	ci.draw_line(c - u * 8 * s, c + u * 8 * s, Color(0.25, 0.15, 0.1), 5.0 * s)
	ci.draw_line(c - u * 3 * s, c + u * 3 * s, Color(0.35, 0.95, 0.45), 2.0 * s)


static func _draw_fallen(ci: CanvasItem, L: Dictionary, feet: Vector2, s: float, facing: int) -> void:
	var h: float = L.h
	var body := Rect2(feet + Vector2(-h / 2, -20) * s, Vector2(h, 20) * s)
	if L.has("long_hair"):
		ci.draw_colored_polygon(PackedVector2Array([feet + Vector2(-facing * h / 2, -20) * s,
			feet + Vector2(-facing * (h / 2 + 26), -2) * s, feet + Vector2(-facing * h / 2, 0) * s]), L.long_hair)
	ci.draw_rect(body, L.body)
	ci.draw_rect(body, L.line, false, 2.0)
	if L.has("long_hair"):
		ci.draw_rect(Rect2(feet + Vector2(-facing * h / 2 - (8 if facing > 0 else 0), -20) * s, Vector2(8, 20) * s), L.long_hair)
	if L.has("ears"):
		ci.draw_colored_polygon(PackedVector2Array([feet + Vector2(-facing * (h / 2 - 6), -20) * s,
			feet + Vector2(-facing * (h / 2 - 2), -32) * s, feet + Vector2(-facing * (h / 2 - 12), -20) * s]), Color(0.95, 0.85, 0.7))
