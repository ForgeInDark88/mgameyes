extends RefCounted
## Рисует карту трёх царств (под экран 1280x720). Используется картой мира и катсценой.

const UI := preload("res://scripts/ui/ui_util.gd")

const HOME_POS := Vector2(780, 530)

const KINGDOMS := {
	"elves": {
		"name": "Царство эльфов",
		"poly": [Vector2(0, 90), Vector2(430, 90), Vector2(470, 300), Vector2(400, 470), Vector2(440, 720), Vector2(0, 720)],
		"color": Color(0.55, 0.75, 0.5),
		"label": Vector2(200, 150),
	},
	"humans": {
		"name": "Царство людей",
		"poly": [Vector2(430, 90), Vector2(820, 90), Vector2(780, 300), Vector2(840, 520), Vector2(800, 720), Vector2(440, 720), Vector2(400, 470), Vector2(470, 300)],
		"color": Color(0.9, 0.85, 0.62),
		"label": Vector2(625, 150),
	},
	"demons": {
		"name": "Царство демонов",
		"poly": [Vector2(820, 90), Vector2(1280, 90), Vector2(1280, 720), Vector2(800, 720), Vector2(840, 520), Vector2(780, 300)],
		"color": Color(0.42, 0.33, 0.33),
		"label": Vector2(1060, 150),
	},
}


static func draw_map(ci: CanvasItem, off: Vector2, focus: String, demons_revealed: bool, t: float) -> void:
	for id in KINGDOMS:
		var k: Dictionary = KINGDOMS[id]
		var pts := PackedVector2Array()
		for p in k.poly:
			pts.append(off + p)
		ci.draw_colored_polygon(pts, k.color)
	_decorations(ci, off, t)
	if not demons_revealed:
		# восток скрыт пеленой
		var fog := PackedVector2Array()
		for p in KINGDOMS.demons.poly:
			fog.append(off + p)
		ci.draw_colored_polygon(fog, Color(0.75, 0.75, 0.78, 0.92))
		for i in 6:
			var c := off + Vector2(900 + (i % 3) * 130 + sin(t + i) * 12, 260 + (i / 3) * 220)
			ci.draw_circle(c, 70, Color(0.85, 0.85, 0.88, 0.6))
	for id in KINGDOMS:
		var k: Dictionary = KINGDOMS[id]
		var pts := PackedVector2Array()
		for p in k.poly:
			pts.append(off + p)
		pts.append(pts[0])
		if focus != "" and focus != id:
			ci.draw_colored_polygon(pts.slice(0, pts.size() - 1), Color(0, 0, 0, 0.35))
		ci.draw_polyline(pts, Color(0.3, 0.22, 0.12), 3.0)
		var name: String = k.name if (id != "demons" or demons_revealed) else "???"
		var col := Color(0.2, 0.12, 0.05) if id != "demons" or not demons_revealed else Color(1, 0.85, 0.75)
		if focus == id:
			ci.draw_rect(Rect2(off + k.label - Vector2(150, 30), Vector2(300, 42)), Color(1, 1, 0.9, 0.85))
		UI.text(ci, off + k.label - Vector2(150, 0), name, 26, col, HORIZONTAL_ALIGNMENT_CENTER, 300)
	# отчий дом
	var h := off + HOME_POS
	ci.draw_rect(Rect2(h - Vector2(14, 12), Vector2(28, 20)), Color(0.6, 0.4, 0.25))
	ci.draw_colored_polygon(PackedVector2Array([h + Vector2(-18, -12), h + Vector2(0, -28), h + Vector2(18, -12)]), Color(0.6, 0.15, 0.1))


static func _decorations(ci: CanvasItem, off: Vector2, t: float) -> void:
	# эльфийский лес
	for i in 30:
		var p := off + Vector2(40 + (i % 6) * 62 + (i / 6 % 2) * 30, 220 + (i / 6) * 90)
		ci.draw_circle(p, 18, Color(0.3, 0.55, 0.3))
		ci.draw_circle(p + Vector2(-5, -5), 7, Color(0.45, 0.7, 0.45))
	# белый город Илларион
	for i in 5:
		var b := off + Vector2(70 + i * 55, 640 - (i % 2) * 30)
		var hgt := 110.0 + (i % 3) * 40.0
		ci.draw_rect(Rect2(b - Vector2(0, hgt), Vector2(30, hgt)), Color(0.93, 0.93, 1.0, 0.75))
		ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-5, -hgt), b + Vector2(15, -hgt - 30), b + Vector2(35, -hgt)]), Color(0.6, 0.75, 0.95, 0.85))
	UI.text(ci, off + Vector2(60, 700), "Илларион", 16, Color(0.95, 0.95, 1.0), HORIZONTAL_ALIGNMENT_CENTER, 300)
	# поля и домики людей
	for i in 5:
		var p := off + Vector2(520 + (i % 3) * 90, 250 + (i / 3) * 140)
		ci.draw_rect(Rect2(p, Vector2(60, 34)), Color(0.82, 0.75, 0.45))
	# вулкан демонов
	var v := off + Vector2(1080, 360)
	ci.draw_colored_polygon(PackedVector2Array([v + Vector2(-110, 120), v + Vector2(-25, -40), v + Vector2(25, -40), v + Vector2(110, 120)]), Color(0.25, 0.2, 0.2))
	ci.draw_circle(v + Vector2(0, -50), 18 + sin(t * 3.0) * 3.0, Color(1, 0.4, 0.1, 0.8))
