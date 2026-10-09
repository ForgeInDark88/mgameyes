extends Control
## Окно диалога. Пока оно открыто, игрок не двигается.
## Листать: Enter / Пробел / E / клик. Выбор: 1–2, стрелки + Enter или клик.
## Реплика — [кто, текст] или словарь (см. campaigns.gd): с условиями "if"/"unless"
## и вариантами выбора "choices".

signal finished
signal line_shown(index: int)

const UI := preload("res://scripts/ui/ui_util.gd")
const BOX_SIZE := Vector2(760, 130)
const CHARS_PER_SEC := 60.0
const CHOICE_H := 34.0

var _lines: Array = []
var _index := 0
var _shown := 0.0
var _choice := 0
## true — пока открыт диалог, игра стоит на паузе (враги не атакуют)
var pause_tree := false


func _ready() -> void:
	custom_minimum_size = BOX_SIZE
	size = BOX_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return visible


func show_lines(lines: Array) -> void:
	if lines.is_empty():
		return
	if visible:
		# уже идёт диалог — дописываем в конец очереди
		_lines = _lines + lines
		return
	_lines = lines
	_index = -1
	visible = true
	if pause_tree:
		get_tree().paused = true
	add_to_group("dialog_open")
	_next()


static func normalize(line) -> Dictionary:
	if line is Dictionary:
		return line
	return {"who": line[0], "text": line[1]}


static func line_visible(line: Dictionary) -> bool:
	if line.has("if") and not GameState.flag(line["if"]):
		return false
	if line.has("unless") and GameState.flag(line["unless"]):
		return false
	return true


func _current() -> Dictionary:
	return normalize(_lines[_index])


func _next() -> void:
	_index += 1
	while _index < _lines.size() and not line_visible(normalize(_lines[_index])):
		_index += 1
	_shown = 0.0
	_choice = 0
	if _index >= _lines.size():
		_close()
		return
	line_shown.emit(_index)
	queue_redraw()


func _close() -> void:
	visible = false
	if pause_tree and is_inside_tree():
		get_tree().paused = false
	finished.emit()
	if not is_inside_tree():
		return
	# небольшая задержка, чтобы нажатие не превратилось в прыжок или удар
	await get_tree().create_timer(0.15, true, false, true).timeout
	if not visible:
		remove_from_group("dialog_open")


func _process(delta: float) -> void:
	if visible:
		_shown += delta * CHARS_PER_SEC
		queue_redraw()


func _choices() -> Array:
	return _current().get("choices", [])


func _input(event: InputEvent) -> void:
	if not visible or _index >= _lines.size():
		return
	var choices := _choices()
	var full: String = _current().text
	var typing := _shown < full.length()
	if not choices.is_empty() and not typing:
		for i in choices.size():
			if event.is_action_pressed("slot_%d" % (i + 1)):
				_choice = i
				_pick()
				get_viewport().set_input_as_handled()
				return
		if event.is_action_pressed("ui_up"):
			_choice = wrapi(_choice - 1, 0, choices.size())
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("ui_down"):
			_choice = wrapi(_choice + 1, 0, choices.size())
			get_viewport().set_input_as_handled()
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
			for i in choices.size():
				if _choice_rect(i).has_point(local):
					_choice = i
					_pick()
			get_viewport().set_input_as_handled()
			return
	var advance: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not advance:
		return
	get_viewport().set_input_as_handled()
	if typing:
		_shown = full.length()
	elif not choices.is_empty():
		_pick()
	else:
		_next()


func _pick() -> void:
	var opt: Array = _choices()[_choice]
	GameState.set_flag(opt[1])
	_next()


func _choice_rect(i: int) -> Rect2:
	return Rect2(18, size.y + 6 + i * (CHOICE_H + 6), size.x - 36, CHOICE_H)


func _draw() -> void:
	if _index < 0 or _index >= _lines.size():
		return
	var line := _current()
	UI.panel(self, Rect2(Vector2.ZERO, size), Color(1, 1, 0.96, 0.96))
	UI.text(self, Vector2(18, 30), line.who, 18, Color(0.1, 0.45, 0.2))
	var full: String = line.text
	var part := full.substr(0, int(_shown))
	draw_multiline_string(UI.font(), Vector2(18, 60), part, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 20, -1, Color(0.1, 0.1, 0.1))
	if _shown < full.length():
		return
	var choices := _choices()
	if choices.is_empty():
		UI.text(self, Vector2(size.x - 150, size.y - 12), "Enter — далее ▸", 14, Color(0.4, 0.4, 0.4))
		return
	for i in choices.size():
		var r := _choice_rect(i)
		var sel := i == _choice
		UI.panel(self, r, Color(1, 0.93, 0.7) if sel else Color(1, 1, 1, 0.95), Color(0.85, 0.5, 0.0) if sel else Color.BLACK)
		UI.text(self, r.position + Vector2(12, 23), "%d. %s" % [i + 1, choices[i][0]], 18, Color(0.1, 0.1, 0.1))
