extends RefCounted
## Оформление уровней: небо/фон, цвет земли и платформ, декорации на заднем плане.
## Тема задаётся у локации полем "theme".

const DATA := {
	"village": {"sky": [Color(0.55, 0.75, 0.95), Color(0.85, 0.92, 0.98)], "ground": Color(0.38, 0.3, 0.22), "top": Color(0.35, 0.65, 0.3), "platform": Color(0.45, 0.3, 0.18), "deco": "houses"},
	"fields": {"sky": [Color(0.95, 0.55, 0.3), Color(0.98, 0.85, 0.55)], "ground": Color(0.42, 0.32, 0.2), "top": Color(0.8, 0.7, 0.3), "platform": Color(0.45, 0.3, 0.18), "deco": "smoke_fields"},
	"road": {"sky": [Color(0.5, 0.72, 0.92), Color(0.82, 0.9, 0.95)], "ground": Color(0.4, 0.33, 0.25), "top": Color(0.45, 0.6, 0.3), "platform": Color(0.4, 0.28, 0.16), "deco": "hills"},
	"forest": {"sky": [Color(0.3, 0.5, 0.45), Color(0.65, 0.8, 0.7)], "ground": Color(0.25, 0.22, 0.16), "top": Color(0.3, 0.55, 0.3), "platform": Color(0.35, 0.25, 0.15), "deco": "trees"},
	"camp": {"sky": [Color(0.25, 0.4, 0.45), Color(0.6, 0.72, 0.7)], "ground": Color(0.25, 0.22, 0.16), "top": Color(0.3, 0.55, 0.3), "platform": Color(0.35, 0.25, 0.15), "deco": "tents"},
	"burned": {"sky": [Color(0.3, 0.25, 0.25), Color(0.75, 0.45, 0.3)], "ground": Color(0.18, 0.15, 0.14), "top": Color(0.3, 0.25, 0.22), "platform": Color(0.12, 0.1, 0.1), "deco": "burned_trees"},
	"sewer": {"sky": [Color(0.12, 0.17, 0.17), Color(0.2, 0.26, 0.24)], "ground": Color(0.24, 0.27, 0.26), "top": Color(0.3, 0.42, 0.3), "platform": Color(0.35, 0.33, 0.3), "deco": "sewer_bricks"},
	"dungeon": {"sky": [Color(0.1, 0.1, 0.12), Color(0.2, 0.18, 0.18)], "ground": Color(0.28, 0.26, 0.26), "top": Color(0.35, 0.33, 0.32), "platform": Color(0.3, 0.28, 0.27), "deco": "dungeon"},
	"city": {"sky": [Color(0.18, 0.15, 0.35), Color(0.55, 0.45, 0.7)], "ground": Color(0.75, 0.75, 0.8), "top": Color(0.85, 0.85, 0.92), "platform": Color(0.6, 0.62, 0.7), "deco": "elf_city"},
	"throne": {"sky": [Color(0.75, 0.78, 0.85), Color(0.92, 0.92, 0.95)], "ground": Color(0.65, 0.65, 0.72), "top": Color(0.85, 0.8, 0.55), "platform": Color(0.55, 0.55, 0.62), "deco": "columns"},
	"fort": {"sky": [Color(0.55, 0.65, 0.8), Color(0.85, 0.85, 0.85)], "ground": Color(0.42, 0.4, 0.38), "top": Color(0.55, 0.52, 0.48), "platform": Color(0.4, 0.28, 0.16), "deco": "fort"},
	"river": {"sky": [Color(0.5, 0.75, 0.9), Color(0.85, 0.93, 0.95)], "ground": Color(0.35, 0.3, 0.25), "top": Color(0.4, 0.6, 0.3), "platform": Color(0.4, 0.28, 0.16), "deco": "river"},
	"ruins": {"sky": [Color(0.12, 0.05, 0.05), Color(0.35, 0.15, 0.1)], "ground": Color(0.3, 0.24, 0.2), "top": Color(0.45, 0.2, 0.12), "platform": Color(0.25, 0.2, 0.18), "deco": "skull"},
}


static func get_theme(id: String) -> Dictionary:
	return DATA.get(id, DATA.road)


## Задний план уровня в мировых координатах (w, h — размер карты в пикселях).
static func draw_background(ci: CanvasItem, id: String, w: float, h: float) -> void:
	var th := get_theme(id)
	var top: Color = th.sky[0]
	var bot: Color = th.sky[1]
	ci.draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)]),
		PackedColorArray([top, top, bot, bot]))
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	match th.deco:
		"houses":
			_hills(ci, w, h, Color(0.55, 0.7, 0.5), rng)
			for x in range(60, int(w), 380):
				var b := Vector2(x + rng.randf_range(0, 120), h - 64)
				ci.draw_rect(Rect2(b + Vector2(0, -90), Vector2(110, 90)), Color(0.75, 0.65, 0.5, 0.6))
				ci.draw_colored_polygon(PackedVector2Array([b + Vector2(-10, -90), b + Vector2(55, -140), b + Vector2(120, -90)]), Color(0.6, 0.25, 0.2, 0.6))
		"smoke_fields":
			_hills(ci, w, h, Color(0.85, 0.65, 0.35), rng)
			for x in range(0, int(w), 140):
				var p := Vector2(x + rng.randf_range(0, 60), h - 120 - rng.randf_range(0, 200))
				ci.draw_circle(p, rng.randf_range(30, 60), Color(0.35, 0.3, 0.3, 0.25))
		"hills":
			_hills(ci, w, h, Color(0.55, 0.7, 0.5), rng)
			_trees(ci, w, h, Color(0.3, 0.5, 0.3, 0.5), rng, 220)
		"trees", "tents":
			for x in range(0, int(w), 70):
				var tx := x + rng.randf_range(-20, 20)
				var tw := rng.randf_range(18, 34)
				ci.draw_rect(Rect2(tx, 0, tw, h), Color(0.2, 0.32, 0.25, 0.45))
				ci.draw_circle(Vector2(tx + tw / 2, rng.randf_range(40, 160)), rng.randf_range(50, 90), Color(0.2, 0.42, 0.3, 0.45))
			if th.deco == "tents":
				for x in range(200, int(w), 420):
					var b := Vector2(x, h - 64)
					ci.draw_colored_polygon(PackedVector2Array([b, b + Vector2(70, -90), b + Vector2(140, 0)]), Color(0.85, 0.85, 0.9, 0.7))
					ci.draw_line(b + Vector2(70, -90), b + Vector2(70, -130), Color(0.4, 0.3, 0.2), 3.0)
					ci.draw_rect(Rect2(b + Vector2(70, -130), Vector2(30, 18)), Color(0.3, 0.7, 0.7))
		"burned_trees":
			for x in range(0, int(w), 90):
				var tx := x + rng.randf_range(-20, 20)
				ci.draw_rect(Rect2(tx, rng.randf_range(60, 200), rng.randf_range(10, 20), h), Color(0.1, 0.08, 0.08, 0.7))
				ci.draw_line(Vector2(tx + 6, 260), Vector2(tx + 40, 220), Color(0.1, 0.08, 0.08, 0.7), 4.0)
			for i in 60:
				ci.draw_circle(Vector2(rng.randf_range(0, w), rng.randf_range(0, h)), 2, Color(1, 0.5, 0.1, 0.6))
		"sewer_bricks":
			for y in range(0, int(h), 24):
				for x in range(-(y / 24 % 2) * 24, int(w), 48):
					ci.draw_rect(Rect2(x + 1, y + 1, 46, 22), Color(0.17, 0.22, 0.21))
			for x in range(120, int(w), 300):
				ci.draw_rect(Rect2(x, 60, 34, h), Color(0.3, 0.33, 0.3, 0.6))  # трубы
				ci.draw_rect(Rect2(x - 6, 60, 46, 12), Color(0.35, 0.38, 0.35))
				ci.draw_rect(Rect2(x + 12, 72, 8, 40), Color(0.35, 0.5, 0.3, 0.6))  # капает
		"dungeon":
			for y in range(0, int(h), 32):
				for x in range(-(y / 32 % 2) * 32, int(w), 64):
					ci.draw_rect(Rect2(x + 1, y + 1, 62, 30), Color(0.15, 0.14, 0.15))
			for x in range(100, int(w), 260):
				ci.draw_line(Vector2(x, 0), Vector2(x, 140), Color(0.35, 0.35, 0.38), 3.0)
				ci.draw_rect(Rect2(x - 8, 140, 16, 10), Color(0.35, 0.35, 0.38))
				ci.draw_circle(Vector2(x + 130, 200), 10, Color(1, 0.6, 0.2, 0.8))
				ci.draw_circle(Vector2(x + 130, 200), 30, Color(1, 0.6, 0.2, 0.12))
		"elf_city":
			for i in 40:
				ci.draw_circle(Vector2(rng.randf_range(0, w), rng.randf_range(0, h * 0.5)), 1.5, Color(1, 1, 1, 0.8))
			for x in range(0, int(w), 160):
				var tw := rng.randf_range(40, 70)
				var th2 := rng.randf_range(180, 360)
				ci.draw_rect(Rect2(x, h - th2, tw, th2), Color(0.8, 0.8, 0.95, 0.35))
				ci.draw_colored_polygon(PackedVector2Array([Vector2(x - 6, h - th2), Vector2(x + tw / 2, h - th2 - 60), Vector2(x + tw + 6, h - th2)]), Color(0.6, 0.75, 0.95, 0.4))
				ci.draw_rect(Rect2(x + tw / 2 - 4, h - th2 + 30, 8, 14), Color(1, 0.9, 0.5, 0.7))
		"columns":
			for x in range(80, int(w), 220):
				ci.draw_rect(Rect2(x, 40, 50, h), Color(0.95, 0.95, 0.98, 0.7))
				ci.draw_rect(Rect2(x - 8, 40, 66, 16), Color(0.85, 0.8, 0.6, 0.8))
				ci.draw_rect(Rect2(x + 90, 70, 40, 120), Color(0.25, 0.55, 0.55, 0.6))  # знамя
		"fort":
			for x in range(0, int(w), 64):
				ci.draw_rect(Rect2(x, h - 260, 64, 260), Color(0.55, 0.55, 0.55, 0.35))
				if x / 64 % 2 == 0:
					ci.draw_rect(Rect2(x, h - 290, 32, 30), Color(0.55, 0.55, 0.55, 0.35))
			for x in range(150, int(w), 500):
				ci.draw_rect(Rect2(x, 40, 40, 70), Color(0.75, 0.15, 0.15, 0.7))
		"river":
			_hills(ci, w, h, Color(0.5, 0.7, 0.5), rng)
			ci.draw_rect(Rect2(0, h - 120, w, 60), Color(0.35, 0.6, 0.85, 0.5))
		"skull":
			# Древний Оскал: огромная каменная челюсть на фоне
			for x in range(0, int(w), 900):
				var c := Vector2(x + 450, h * 0.45)
				ci.draw_circle(c, 260, Color(0.25, 0.12, 0.1, 0.6))
				ci.draw_circle(c + Vector2(-100, -40), 50, Color(0.08, 0.02, 0.02, 0.8))
				ci.draw_circle(c + Vector2(100, -40), 50, Color(0.08, 0.02, 0.02, 0.8))
				ci.draw_circle(c + Vector2(-100, -40), 12, Color(1, 0.3, 0.1, 0.8))
				ci.draw_circle(c + Vector2(100, -40), 12, Color(1, 0.3, 0.1, 0.8))
				for k in 7:
					ci.draw_colored_polygon(PackedVector2Array([c + Vector2(-150 + k * 50, 120), c + Vector2(-125 + k * 50, 190), c + Vector2(-100 + k * 50, 120)]), Color(0.75, 0.7, 0.6, 0.6))


static func _hills(ci: CanvasItem, w: float, h: float, col: Color, rng: RandomNumberGenerator) -> void:
	for x in range(-100, int(w) + 200, 260):
		ci.draw_circle(Vector2(x + rng.randf_range(0, 80), h - 40), rng.randf_range(140, 220), col)


static func _trees(ci: CanvasItem, w: float, h: float, col: Color, rng: RandomNumberGenerator, step: int) -> void:
	for x in range(0, int(w), step):
		var p := Vector2(x + rng.randf_range(0, 80), h - 160)
		ci.draw_rect(Rect2(p + Vector2(-5, 0), Vector2(10, 100)), Color(0.35, 0.25, 0.15, col.a))
		ci.draw_circle(p, 40, col)
