extends Control
## Окно диалога для сюжета. Пока оно открыто, игрок не двигается.
## Листать: Enter / Пробел / E / клик.

signal finished

const UI := preload("res://scripts/ui/ui_util.gd")
const BOX_SIZE := Vector2(760, 120)
const CHARS_PER_SEC := 60.0

var _lines: Array = []
var _index := 0
var _shown := 0.0


func _ready() -> void:
	custom_minimum_size = BOX_SIZE
	size = BOX_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func is_open() -> bool:
	return visible


## lines: массив пар [говорящий, текст]
func show_lines(lines: Array) -> void:
	if lines.is_empty():
		return
	_lines = lines
	_index = 0
	_shown = 0.0
	visible = true
	add_to_group("dialog_open")


func _process(delta: float) -> void:
	if visible:
		_shown += delta * CHARS_PER_SEC
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var advance: bool = event.is_action_pressed("ui_accept") or event.is_action_pressed("jump") \
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	if not advance:
		return
	get_viewport().set_input_as_handled()
	var full: String = _lines[_index][1]
	if _shown < full.length():
		_shown = full.length()
		return
	_index += 1
	_shown = 0.0
	if _index >= _lines.size():
		visible = false
		finished.emit()
		# небольшая задержка, чтобы нажатие не превратилось в прыжок или удар
		await get_tree().create_timer(0.15, true, false, true).timeout
		if not visible:
			remove_from_group("dialog_open")


func _draw() -> void:
	if _lines.is_empty() or _index >= _lines.size():
		return
	var line: Array = _lines[_index]
	UI.panel(self, Rect2(Vector2.ZERO, size), Color(1, 1, 0.96, 0.96))
	UI.text(self, Vector2(18, 30), line[0], 18, Color(0.1, 0.45, 0.2))
	var full: String = line[1]
	var part := full.substr(0, int(_shown))
	draw_multiline_string(UI.font(), Vector2(18, 60), part, HORIZONTAL_ALIGNMENT_LEFT, size.x - 36, 20, -1, Color(0.1, 0.1, 0.1))
	if _shown >= full.length():
		UI.text(self, Vector2(size.x - 150, size.y - 12), "Enter — далее ▸", 14, Color(0.4, 0.4, 0.4))
