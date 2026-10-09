extends Control
## Начальная катсцена кампании: кадры с репликами (данные в campaigns.gd → "intro").
## Esc — пропустить.

const UI := preload("res://scripts/ui/ui_util.gd")
const KingdomMap := preload("res://scripts/ui/kingdom_map.gd")
const DialogScript := preload("res://scripts/ui/dialog_box.gd")

var steps: Array = []
var step: Dictionary = {}
var dialog: Control
var _t := 0.0
var _move_t := 0.0
var _done := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	steps = GameState.campaign().get("intro", [])
	dialog = DialogScript.new()
	add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 30)
	dialog.line_shown.connect(func(i):
		step = steps[i]
		_move_t = 0.0)
	dialog.finished.connect(_finish)
	if steps.is_empty():
		_finish.call_deferred()
	else:
		dialog.show_lines(steps)


func _finish() -> void:
	if _done:
		return
	_done = true
	GameState.set_flag("intro_seen")
	GameState.save_game()
	GameState.go_to_world_map()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		_finish()


func _process(delta: float) -> void:
	_t += delta
	_move_t += delta
	queue_redraw()


func _draw() -> void:
	var view := get_viewport_rect().size
	var off := (view - Vector2(1280, 720)) / 2.0
	draw_rect(Rect2(Vector2.ZERO, view), Color(0.1, 0.1, 0.12))
	match step.get("scene", ""):
		"home":
			_draw_home(off)
		"kingdoms":
			KingdomMap.draw_map(self, off, step.get("focus", ""), false, _t)
			if step.get("move", false):
				_draw_travel(off)
	UI.text(self, Vector2(0, 40), GameState.campaign().name, 30, Color(0.95, 0.9, 0.8), HORIZONTAL_ALIGNMENT_CENTER, view.x)
	UI.text(self, Vector2(16, view.y - 10), "Esc — пропустить", 14, Color(0.7, 0.7, 0.7))


func _draw_home(off: Vector2) -> void:
	# вечер у отчего дома
	draw_rect(Rect2(off + Vector2(0, 60), Vector2(1280, 400)), Color(0.95, 0.6, 0.35))
	draw_circle(off + Vector2(1000, 330), 60, Color(1, 0.85, 0.5))
	draw_rect(Rect2(off + Vector2(0, 460), Vector2(1280, 260)), Color(0.3, 0.45, 0.25))
	var house := off + Vector2(280, 460)
	draw_rect(Rect2(house + Vector2(0, -170), Vector2(240, 170)), Color(0.55, 0.38, 0.22))
	draw_colored_polygon(PackedVector2Array([house + Vector2(-20, -170), house + Vector2(120, -260), house + Vector2(260, -170)]), Color(0.5, 0.15, 0.1))
	draw_rect(Rect2(house + Vector2(95, -90), Vector2(50, 90)), Color(0.3, 0.2, 0.1))
	draw_rect(Rect2(house + Vector2(25, -140), Vector2(40, 36)), Color(1, 0.85, 0.4))
	# отец: выше, седой, с посохом
	var f := off + Vector2(640, 460)
	draw_rect(Rect2(f + Vector2(-17, -78), Vector2(34, 78)), Color(0.45, 0.4, 0.5))
	draw_rect(Rect2(f + Vector2(-17, -78), Vector2(34, 78)), Color(0.2, 0.18, 0.25), false, 2.0)
	draw_rect(Rect2(f + Vector2(-2, -62), Vector2(16, 14)), Color(0.9, 0.9, 0.9))  # борода
	draw_rect(Rect2(f + Vector2(4, -70), Vector2(5, 5)), Color(0.1, 0.1, 0.1))
	draw_line(f + Vector2(26, -96), f + Vector2(26, 0), Color(0.4, 0.28, 0.15), 5.0)
	# сын — Явален (зелёный, как в игре)
	var s := off + Vector2(740, 460)
	draw_rect(Rect2(s + Vector2(-12, -48) * 1.3, Vector2(24, 48) * 1.3), Color(0.13, 0.7, 0.3))
	draw_rect(Rect2(s + Vector2(-12, -48) * 1.3, Vector2(24, 48) * 1.3), Color(0.05, 0.3, 0.12), false, 2.0)
	draw_rect(Rect2(s + Vector2(-12, -54), Vector2(6, 7)), Color(0.05, 0.15, 0.08))
	var speaker: String = step.get("who", "")
	var who_pos := f if speaker == "Отец" else s
	draw_string(UI.font(), who_pos + Vector2(-10, -110 + sin(_t * 4.0) * 3.0), "▼", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color.WHITE)


func _draw_travel(off: Vector2) -> void:
	# путь от отчего дома в Царство людей
	var loc: Dictionary = GameState.get_location(GameState.location_order()[0])
	var a := off + KingdomMap.HOME_POS
	var b: Vector2 = off + loc.map_pos
	var k := clampf(_move_t / 2.0, 0.0, 1.0)
	var n := 12
	for i in n:
		if i % 2 == 0 and float(i) / n < k:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), Color(0.45, 0.3, 0.15), 4.0)
	var p := a.lerp(b, k)
	draw_rect(Rect2(p - Vector2(9, 26), Vector2(18, 26)), Color(0.13, 0.7, 0.3))
	draw_rect(Rect2(p - Vector2(9, 26), Vector2(18, 26)), Color(0.05, 0.3, 0.12), false, 2.0)
