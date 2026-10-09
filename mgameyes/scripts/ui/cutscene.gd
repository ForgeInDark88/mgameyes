extends Control
## Катсцена: кадры с фоном, персонажами и репликами (данные в campaigns.gd).
## Показывает GameState.pending_cutscene, затем переходит в GameState.pending_next.
## Esc — пропустить.

const UI := preload("res://scripts/ui/ui_util.gd")
const KingdomMap := preload("res://scripts/ui/kingdom_map.gd")
const DialogScript := preload("res://scripts/ui/dialog_box.gd")
const Characters := preload("res://scripts/data/characters.gd")

const GROUND_Y := 470.0
const MOVE_TIME := 1.6

var steps: Array = []
var step: Dictionary = {}
var dialog: Control
var _t := 0.0
var _step_t := 0.0
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	steps = GameState.pending_cutscene
	dialog = DialogScript.new()
	add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 30)
	dialog.line_shown.connect(func(i):
		step = steps[i]
		_step_t = 0.0)
	dialog.finished.connect(_finish)
	if steps.is_empty():
		_finish.call_deferred()
	else:
		dialog.show_lines(steps)


func _finish() -> void:
	if _done:
		return
	_done = true
	GameState.pending_cutscene = []
	GameState.save_game()
	GameState.go_to(GameState.pending_next)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_finish()


func _process(delta: float) -> void:
	_t += delta
	_step_t += delta
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	var off := (view - Vector2(1280, 720)) / 2.0
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.08, 0.08, 0.1))
	var scene: String = step.get("scene", "")
	if scene == "kingdoms":
		KingdomMap.draw_map(self, off, step.get("focus", ""), GameState.flag("demons_revealed"), _t)
		if step.get("move", false):
			_draw_travel(off)
	elif scene == "years":
		UI.text(self, Vector2(0, view.y * 0.4), "· · ·", 40, Color(0.7, 0.7, 0.7), HORIZONTAL_ALIGNMENT_CENTER, view.x)
	elif scene != "":
		_draw_backdrop(off, scene)
		_draw_fx(off, step.get("fx", ""))
		for a in step.get("actors", []):
			_draw_actor(off, a)
	UI.text(self, Vector2(0, 40), GameState.campaign().name, 30, Color(0.95, 0.9, 0.8), HORIZONTAL_ALIGNMENT_CENTER, view.x)
	UI.text(self, Vector2(16, view.y - 10), "Esc — пропустить", 14, Color(0.7, 0.7, 0.7))


func _draw_actor(off: Vector2, a: Array) -> void:
	var id: String = a[0]
	var x: float = a[1]
	var pose: String = a[2] if a.size() > 2 else "stand"
	var facing: int = a[3] if a.size() > 3 else 1
	if a.size() > 4:
		x = lerpf(x, a[4], clampf(_step_t / MOVE_TIME, 0.0, 1.0))
	var feet := off + Vector2(x, GROUND_Y)
	Characters.draw(self, id, feet, 2.0, pose, facing, _t)
	var speaker: String = step.get("who", "")
	if Characters.NAMES.get(id, "") == speaker or (id == "old_man" and speaker == "Орвин") or (id == "elf_mage" and speaker == "Верховный маг"):
		draw_string(UI.font(), feet + Vector2(-8, -Characters.height(id) * 2.0 - 30 + sin(_t * 4.0) * 3.0), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)


func _draw_backdrop(off: Vector2, scene: String) -> void:
	var sky := Rect2(off + Vector2(0, 60), Vector2(1280, GROUND_Y - 60))
	var ground := Rect2(off + Vector2(0, GROUND_Y), Vector2(1280, 720 - GROUND_Y))
	match scene:
		"home":
			draw_rect(sky, Color(0.95, 0.6, 0.35))
			draw_circle(off + Vector2(1000, 330), 60, Color(1, 0.85, 0.5))
			draw_rect(ground, Color(0.3, 0.45, 0.25))
			var house := off + Vector2(200, GROUND_Y)
			draw_rect(Rect2(house + Vector2(0, -170), Vector2(240, 170)), Color(0.55, 0.38, 0.22))
			draw_colored_polygon(PackedVector2Array([house + Vector2(-20, -170), house + Vector2(120, -260), house + Vector2(260, -170)]), Color(0.5, 0.15, 0.1))
			draw_rect(Rect2(house + Vector2(95, -90), Vector2(50, 90)), Color(0.3, 0.2, 0.1))
			draw_rect(Rect2(house + Vector2(25, -140), Vector2(40, 36)), Color(1, 0.85, 0.4))
		"war_camp":
			draw_rect(sky, Color(0.15, 0.15, 0.3))
			for i in 30:
				draw_circle(off + Vector2(fposmod(i * 137.0, 1280), 80 + fposmod(i * 71.0, 200)), 1.5, Color(1, 1, 1, 0.7))
			draw_rect(ground, Color(0.22, 0.25, 0.18))
			for x in [120, 900, 1100]:
				var b := off + Vector2(x, GROUND_Y)
				draw_colored_polygon(PackedVector2Array([b, b + Vector2(80, -120), b + Vector2(160, 0)]), Color(0.65, 0.55, 0.4))
				draw_rect(Rect2(b + Vector2(80, -170), Vector2(36, 22)), Color(0.75, 0.15, 0.15))
			_campfire(off + Vector2(620, GROUND_Y))
		"throne":
			draw_rect(sky, Color(0.85, 0.85, 0.9))
			draw_rect(ground, Color(0.7, 0.7, 0.78))
			for x in [80, 300, 980, 1180]:
				draw_rect(Rect2(off + Vector2(x, 60), Vector2(50, GROUND_Y - 60)), Color(0.95, 0.95, 1.0))
			var t := off + Vector2(1040, GROUND_Y)
			draw_rect(Rect2(t + Vector2(-40, -200), Vector2(80, 200)), Color(0.75, 0.65, 0.35))
			draw_rect(Rect2(t + Vector2(-30, -110), Vector2(60, 110)), Color(0.25, 0.5, 0.55))
		"oskal":
			draw_rect(sky, Color(0.15, 0.05, 0.05))
			draw_rect(ground, Color(0.25, 0.18, 0.15))
			var c := off + Vector2(640, 260)
			draw_circle(c, 200, Color(0.3, 0.15, 0.12))
			for sx in [-1, 1]:
				draw_circle(c + Vector2(sx * 80, -30), 40, Color(0.05, 0.0, 0.0))
				draw_circle(c + Vector2(sx * 80, -30), 10 + sin(_t * 3.0) * 3.0, Color(1, 0.25, 0.1))
			for k in 7:
				draw_colored_polygon(PackedVector2Array([c + Vector2(-140 + k * 40, 100), c + Vector2(-120 + k * 40, 170), c + Vector2(-100 + k * 40, 100)]), Color(0.8, 0.75, 0.65))
			var alt := off + Vector2(820, GROUND_Y)
			draw_rect(Rect2(alt + Vector2(-50, -60), Vector2(100, 60)), Color(0.35, 0.3, 0.28))
			draw_colored_polygon(PackedVector2Array([alt + Vector2(-8, -60), alt + Vector2(0, -100), alt + Vector2(8, -60)]), Color(0.1, 0.05, 0.05))
		"river":
			draw_rect(sky, Color(0.55, 0.75, 0.9))
			draw_rect(Rect2(off + Vector2(0, GROUND_Y), Vector2(820, 720 - GROUND_Y)), Color(0.3, 0.42, 0.25))
			draw_rect(Rect2(off + Vector2(820, GROUND_Y + 40), Vector2(460, 720 - GROUND_Y)), Color(0.3, 0.55, 0.85))
			for i in 6:
				var wx := fposmod(_t * 80.0 + i * 90.0, 460.0)
				draw_line(off + Vector2(820 + wx, GROUND_Y + 60 + i * 12), off + Vector2(850 + wx, GROUND_Y + 60 + i * 12), Color(0.8, 0.9, 1.0, 0.6), 2.0)
			for x in range(0, 800, 110):
				draw_circle(off + Vector2(x + 40, 200), 60, Color(0.25, 0.45, 0.3, 0.7))
		"dungeon":
			draw_rect(sky, Color(0.12, 0.12, 0.14))
			for y in range(60, int(GROUND_Y), 32):
				for x in range(0, 1280, 64):
					draw_rect(Rect2(off + Vector2(x + (y / 32 % 2) * 32 + 1, y + 1), Vector2(62, 30)), Color(0.18, 0.17, 0.18))
			draw_rect(ground, Color(0.25, 0.23, 0.22))
		"forest":
			draw_rect(sky, Color(0.4, 0.6, 0.5))
			draw_rect(ground, Color(0.25, 0.35, 0.2))
			for x in range(0, 1280, 120):
				draw_rect(Rect2(off + Vector2(x + 20, 60), Vector2(24, GROUND_Y - 60)), Color(0.25, 0.2, 0.15))
				draw_circle(off + Vector2(x + 32, 140), 70, Color(0.25, 0.5, 0.35))
		"pass":
			draw_rect(sky, Color(0.55, 0.6, 0.68))
			draw_rect(ground, Color(0.38, 0.36, 0.35))
			for x in range(-150, 1400, 300):
				draw_colored_polygon(PackedVector2Array([off + Vector2(x, GROUND_Y), off + Vector2(x + 150, 120 + fposmod(x * 0.41, 100.0)), off + Vector2(x + 300, GROUND_Y)]), Color(0.45, 0.45, 0.5))
				draw_colored_polygon(PackedVector2Array([off + Vector2(x + 110, 200 + fposmod(x * 0.41, 100.0)), off + Vector2(x + 150, 120 + fposmod(x * 0.41, 100.0)), off + Vector2(x + 190, 200 + fposmod(x * 0.41, 100.0))]), Color(0.95, 0.95, 0.97))
			for i in 8:
				var y := 100.0 + i * 40.0
				var x2 := fposmod(_t * 300.0 + i * 170.0, 1400.0) - 100.0
				draw_line(off + Vector2(x2, y), off + Vector2(x2 + 90, y), Color(1, 1, 1, 0.4), 2.0)
		"ice":
			draw_rect(sky, Color(0.6, 0.75, 0.9))
			draw_rect(ground, Color(0.8, 0.9, 0.97))
			for x in range(-100, 1400, 260):
				draw_colored_polygon(PackedVector2Array([off + Vector2(x, GROUND_Y), off + Vector2(x + 120, 160 + fposmod(x * 0.37, 120.0)), off + Vector2(x + 240, GROUND_Y)]), Color(0.85, 0.93, 1.0))
			var alt := off + Vector2(820, GROUND_Y)
			draw_rect(Rect2(alt + Vector2(-70, -80), Vector2(140, 80)), Color(0.55, 0.75, 0.9))
			draw_rect(Rect2(alt + Vector2(-70, -80), Vector2(140, 80)), Color(0.35, 0.5, 0.7), false, 3.0)
			for i in 50:
				var p := off + Vector2(fposmod(i * 131.0 + _t * 30.0, 1280.0), fposmod(i * 53.0 + _t * 60.0, GROUND_Y - 60.0) + 60.0)
				draw_circle(p, 2.5, Color(1, 1, 1, 0.9))
		"burned":
			draw_rect(sky, Color(0.45, 0.28, 0.22))
			draw_rect(ground, Color(0.15, 0.12, 0.11))
			for x in range(0, 1280, 140):
				draw_rect(Rect2(off + Vector2(x + 30, 120), Vector2(18, GROUND_Y - 120)), Color(0.1, 0.08, 0.08))
			for i in 40:
				var p := off + Vector2(fposmod(i * 97.0 + _t * 20.0, 1280.0), fposmod(GROUND_Y - i * 31.0 - _t * 40.0, GROUND_Y - 60.0) + 60.0)
				draw_circle(p, 2.5, Color(1, 0.5, 0.1, 0.8))
		_:
			draw_rect(sky, Color(0.3, 0.3, 0.35))
			draw_rect(ground, Color(0.2, 0.2, 0.2))


func _campfire(p: Vector2) -> void:
	draw_line(p + Vector2(-20, 0), p + Vector2(20, -8), Color(0.4, 0.25, 0.1), 7.0)
	draw_line(p + Vector2(-20, -8), p + Vector2(20, 0), Color(0.4, 0.25, 0.1), 7.0)
	var f := 1.0 + sin(_t * 12.0) * 0.15
	draw_colored_polygon(PackedVector2Array([p + Vector2(-16, -6), p + Vector2(0, -50 * f), p + Vector2(16, -6)]), Color(1, 0.5, 0.1))
	draw_colored_polygon(PackedVector2Array([p + Vector2(-8, -6), p + Vector2(0, -30 * f), p + Vector2(8, -6)]), Color(1, 0.9, 0.4))
	draw_circle(p + Vector2(0, -20), 120, Color(1, 0.6, 0.2, 0.08))


func _draw_fx(off: Vector2, fx: String) -> void:
	match fx:
		"artifact":
			# сияющий артефакт (Слеза Луны / клык Пегруса)
			var c := off + Vector2(860 if step.get("scene", "") == "throne" else 820, 300)
			var col := Color(0.6, 0.85, 1.0) if step.get("scene", "") == "throne" else Color(1, 0.2, 0.1)
			for i in 4:
				draw_circle(c, 20.0 + i * 18.0 + sin(_t * 4.0 + i) * 6.0, Color(col.r, col.g, col.b, 0.25 - i * 0.05))
			draw_circle(c, 14, col)
		"rocks":
			var k := clampf(_step_t / MOVE_TIME, 0.0, 1.0)
			for i in 14:
				var x := 200.0 + fposmod(i * 67.0, 500.0)
				var y := lerpf(80.0 + fposmod(i * 29.0, 120.0), GROUND_Y - 10.0, minf(k * (1.0 + i * 0.05), 1.0))
				draw_rect(Rect2(off + Vector2(x, y), Vector2(18 + i % 3 * 8, 14 + i % 2 * 8)), Color(0.4, 0.38, 0.36))
			draw_rect(Rect2(off + Vector2(0, 60), Vector2(1280, GROUND_Y - 60)), Color(0.8, 0.78, 0.75, 0.5 * k))
		"shield":
			var c := off + Vector2(700, GROUND_Y - 50)
			draw_circle(c, 80 + sin(_t * 4.0) * 4.0, Color(0.45, 0.85, 1.0, 0.25))
			draw_arc(c, 80 + sin(_t * 4.0) * 4.0, 0, TAU, 40, Color(0.7, 0.95, 1.0, 0.9), 4.0)
		"blade":
			var c := off + Vector2(680, 300)
			for i in 4:
				draw_circle(c, 30.0 + i * 22.0 + sin(_t * 5.0 + i) * 6.0, Color(0.6, 0.85, 1.0, 0.18 - i * 0.03))
			draw_line(c + Vector2(-90, 90), c + Vector2(90, -90), Color(0.3, 0.04, 0.08), 16.0)
			draw_line(c + Vector2(-90, 90), c + Vector2(90, -90), Color(0.6, 0.85, 1.0), 4.0)
			draw_line(c + Vector2(-110, 70), c + Vector2(-70, 110), Color(0.15, 0.1, 0.12), 10.0)
		"possess":
			var c := off + Vector2(560, GROUND_Y - 60)
			for i in 6:
				var r := 60.0 + i * 40.0 + fposmod(_t * 60.0, 40.0)
				draw_arc(c, r, 0, TAU, 40, Color(0.45, 0.2, 0.9, 0.5 - i * 0.07), 5.0)
			draw_rect(Rect2(off + Vector2(0, 60), Vector2(1280, 660)), Color(0.1, 0.0, 0.2, 0.25 + 0.1 * sin(_t * 3.0)))
		"beam":
			var a := off + Vector2(880, 330)
			var b := off + Vector2(600, GROUND_Y - 40)
			draw_line(a, b, Color(0.7, 0.9, 1.0, 0.9), 14.0)
			draw_line(a, b, Color.WHITE, 5.0)
			draw_circle(b, 40, Color(0.7, 0.9, 1.0, 0.5))
		"fire":
			for i in 12:
				var x := fposmod(i * 113.0, 1280.0)
				var hgt := 40.0 + fposmod(i * 37.0, 60.0) + sin(_t * 8.0 + i) * 10.0
				var p := off + Vector2(x, GROUND_Y)
				draw_colored_polygon(PackedVector2Array([p + Vector2(-20, 0), p + Vector2(0, -hgt), p + Vector2(20, 0)]), Color(1, 0.4, 0.05, 0.7))
		"splash":
			var k := clampf(_step_t / MOVE_TIME, 0.0, 1.0)
			if k > 0.6:
				var p := off + Vector2(1000, GROUND_Y + 50)
				for i in 8:
					var ang := PI + i * PI / 7.0
					draw_circle(p + Vector2.from_angle(ang) * 40.0 * (k - 0.5), 6, Color(0.8, 0.9, 1.0, 1.0 - k * 0.5))


func _draw_travel(off: Vector2) -> void:
	var loc: Dictionary = GameState.get_location(GameState.location_order()[0])
	var a := off + KingdomMap.HOME_POS
	var b: Vector2 = off + loc.map_pos
	var k := clampf(_step_t / 2.0, 0.0, 1.0)
	var n := 12
	for i in n:
		if i % 2 == 0 and float(i) / n < k:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), Color(0.45, 0.3, 0.15), 4.0)
	Characters.draw(self, GameState.hero_look(), a.lerp(b, k), 0.6)
