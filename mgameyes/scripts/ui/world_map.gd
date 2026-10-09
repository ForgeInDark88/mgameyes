extends Control
## Общая карта мира: локации открываются по мере прохождения сюжета.

const UI := preload("res://scripts/ui/ui_util.gd")
const Items := preload("res://scripts/data/items.gd")
const Locations := preload("res://scripts/data/locations.gd")
const DialogScript := preload("res://scripts/ui/dialog_box.gd")
const HotbarScript := preload("res://scripts/ui/hotbar.gd")
const NODE_R := 34.0

var selected := 0
var dialog: Control
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# по умолчанию выбираем первую незачищенную открытую локацию
	for i in Locations.ORDER.size():
		var id: String = Locations.ORDER[i]
		if GameState.is_unlocked(id) and not GameState.is_cleared(id):
			selected = i
			break

	var hotbar := HotbarScript.new()
	add_child(hotbar)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 16)

	dialog = DialogScript.new()
	add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 130)

	if not GameState.flags.get("intro_seen", false):
		GameState.flags["intro_seen"] = true
		dialog.show_lines(Locations.WORLD_INTRO)
	elif GameState.all_cleared() and not GameState.flags.get("ending_seen", false):
		GameState.flags["ending_seen"] = true
		dialog.show_lines(Locations.WORLD_ENDING)
	GameState.save_game()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _loc_id(i: int) -> String:
	return Locations.ORDER[i]


func _unhandled_input(event: InputEvent) -> void:
	if dialog.is_open():
		return
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		selected = mini(selected + 1, Locations.ORDER.size() - 1)
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		selected = maxi(selected - 1, 0)
	elif event.is_action_pressed("ui_accept"):
		_enter(selected)
	elif event.is_action_pressed("pause"):
		GameState.save_game()
		GameState.go_to_main_menu()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in Locations.ORDER.size():
			if event.position.distance_to(_node_pos(i)) < NODE_R:
				if selected == i:
					_enter(i)
				selected = i


func _enter(i: int) -> void:
	var id := _loc_id(i)
	if GameState.is_unlocked(id):
		GameState.enter_location(id)


func _node_pos(i: int) -> Vector2:
	var p: Vector2 = Locations.get_location(_loc_id(i)).map_pos
	# карта нарисована под 1280x720 — центрируем при другом размере окна
	return p + (size - Vector2(1280, 720)) / 2.0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.86, 0.74))
	var off := (size - Vector2(1280, 720)) / 2.0
	# декорации карты: горы, лес, река
	for x in [700, 760, 820, 1060, 1120]:
		var b := off + Vector2(x, 230)
		draw_colored_polygon(PackedVector2Array([b, b + Vector2(40, -70), b + Vector2(80, 0)]), Color(0.6, 0.55, 0.5))
	for i in 12:
		var tpos := off + Vector2(110 + (i % 6) * 34, 560 + (i / 6) * 30)
		draw_circle(tpos, 14, Color(0.35, 0.6, 0.3))
	draw_polyline(PackedVector2Array([off + Vector2(0, 640), off + Vector2(400, 600), off + Vector2(700, 650), off + Vector2(1280, 590)]),
		Color(0.45, 0.65, 0.85), 10.0)
	UI.text(self, Vector2(0, 50), "Карта долины", 34, Color(0.25, 0.2, 0.15), HORIZONTAL_ALIGNMENT_CENTER, size.x)

	# дороги между локациями
	for i in Locations.ORDER.size():
		var loc := Locations.get_location(_loc_id(i))
		for req in loc.requires:
			var j := Locations.ORDER.find(req)
			var col := Color(0.45, 0.33, 0.2) if GameState.is_unlocked(_loc_id(i)) else Color(0.6, 0.55, 0.5)
			_dashed(_node_pos(j), _node_pos(i), col)

	for i in Locations.ORDER.size():
		var id := _loc_id(i)
		var loc := Locations.get_location(id)
		var p := _node_pos(i)
		var unlocked := GameState.is_unlocked(id)
		var done := GameState.is_cleared(id)
		var fill := Color(0.55, 0.55, 0.55)
		if done:
			fill = Color(0.2, 0.7, 0.35)
		elif unlocked:
			fill = Color(0.9, 0.25, 0.2)
		if i == selected:
			draw_circle(p, NODE_R + 8 + sin(_t * 4.0) * 3.0, Color(1, 0.85, 0.2, 0.7))
		draw_circle(p, NODE_R, fill)
		draw_arc(p, NODE_R, 0, TAU, 32, Color.BLACK, 3.0)
		var mark := "✓" if done else ("!" if unlocked else "?")
		UI.text(self, p + Vector2(-NODE_R, 11), mark, 30, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, NODE_R * 2)
		UI.text(self, p + Vector2(-120, NODE_R + 24), loc.name, 18, Color(0.2, 0.15, 0.1), HORIZONTAL_ALIGNMENT_CENTER, 240)

	# информация о выбранной локации
	var sel := Locations.get_location(_loc_id(selected))
	var r := Rect2(off + Vector2(860, 90), Vector2(390, 120))
	UI.panel(self, r, Color(1, 1, 0.95, 0.95))
	UI.text(self, r.position + Vector2(14, 30), sel.name, 22, Color(0.1, 0.1, 0.1))
	draw_multiline_string(UI.font(), r.position + Vector2(14, 58), sel.desc, HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28, 16, -1, Color(0.25, 0.25, 0.25))
	var status := ""
	if GameState.is_cleared(_loc_id(selected)):
		status = "Зачищено. Награда: %s" % Items.get_item(sel.reward).name
	elif GameState.is_unlocked(_loc_id(selected)):
		status = "Enter / клик — войти"
	else:
		status = "Закрыто: сначала пройди предыдущую локацию"
	UI.text(self, r.position + Vector2(14, r.size.y - 14), status, 15, Color(0.5, 0.3, 0.1))
	UI.text(self, Vector2(16, 28), "Esc — главное меню", 14, Color(0.4, 0.35, 0.3))


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b) / 18.0)
	for k in n:
		if k % 2 == 0:
			draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), col, 5.0)
