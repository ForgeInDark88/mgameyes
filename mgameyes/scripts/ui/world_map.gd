extends Control
## Общая карта трёх царств. Локации кампании открываются по мере прохождения сюжета.

const UI := preload("res://scripts/ui/ui_util.gd")
const Items := preload("res://scripts/data/items.gd")
const KingdomMap := preload("res://scripts/ui/kingdom_map.gd")
const DialogScript := preload("res://scripts/ui/dialog_box.gd")
const HotbarScript := preload("res://scripts/ui/hotbar.gd")
const NODE_R := 30.0

var order: Array = []
var selected := 0
var dialog: Control
var _t := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	order = GameState.location_order()
	# по умолчанию выбираем первую незачищенную открытую локацию
	for i in order.size():
		if GameState.is_unlocked(order[i]) and not GameState.is_cleared(order[i]):
			selected = i
			break

	var hotbar := HotbarScript.new()
	add_child(hotbar)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 16)

	dialog = DialogScript.new()
	add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 130)

	if GameState.all_cleared() and not GameState.flag("ending_seen"):
		GameState.set_flag("ending_seen")
		dialog.show_lines(GameState.campaign().get("ending", []))
	GameState.save_game()


func _process(delta: float) -> void:
	_t += delta
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if dialog.is_open():
		return
	if event.is_action_pressed("move_right") or event.is_action_pressed("ui_right"):
		selected = mini(selected + 1, order.size() - 1)
	elif event.is_action_pressed("move_left") or event.is_action_pressed("ui_left"):
		selected = maxi(selected - 1, 0)
	elif event.is_action_pressed("ui_accept"):
		_enter(selected)
	elif event.is_action_pressed("pause"):
		GameState.save_game()
		GameState.go_to_main_menu()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in order.size():
			if event.position.distance_to(_node_pos(i)) < NODE_R:
				if selected == i:
					_enter(i)
				selected = i


func _enter(i: int) -> void:
	if GameState.is_unlocked(order[i]):
		GameState.enter_location(order[i])


func _offset() -> Vector2:
	# карта нарисована под 1280x720 — центрируем при другом размере окна
	return (size - Vector2(1280, 720)) / 2.0


func _node_pos(i: int) -> Vector2:
	return GameState.get_location(order[i]).map_pos + _offset()


func _draw() -> void:
	var off := _offset()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.9, 0.86, 0.74))
	KingdomMap.draw_map(self, off, "", GameState.flag("demons_revealed"), _t)
	UI.text(self, Vector2(0, 50), "Карта трёх царств", 32, Color(0.25, 0.2, 0.15), HORIZONTAL_ALIGNMENT_CENTER, size.x)

	# вечные льды на севере — вокруг северных локаций
	for i in order.size():
		if GameState.get_location(order[i]).get("kingdom", "") == "north":
			var c := _node_pos(i)
			draw_circle(c, 85, Color(0.88, 0.95, 1.0, 0.9))
			draw_circle(c + Vector2(40, -20), 50, Color(0.95, 0.98, 1.0, 0.9))
	# дороги между локациями
	for i in order.size():
		if _hidden(order[i]):
			continue
		for req in GameState.get_location(order[i]).get("requires", []):
			var j := order.find(req)
			var col := Color(0.45, 0.3, 0.15) if GameState.is_unlocked(order[i]) else Color(0.55, 0.5, 0.45)
			_dashed(_node_pos(j), _node_pos(i), col)

	for i in order.size():
		var id: String = order[i]
		var loc := GameState.get_location(id)
		var unlocked := GameState.is_unlocked(id)
		if _hidden(id):
			continue
		var p := _node_pos(i)
		var fill := Color(0.55, 0.55, 0.55)
		if GameState.is_cleared(id):
			fill = Color(0.2, 0.7, 0.35)
		elif unlocked:
			fill = Color(0.9, 0.25, 0.2)
		if i == selected:
			draw_circle(p, NODE_R + 8 + sin(_t * 4.0) * 3.0, Color(1, 0.85, 0.2, 0.8))
		draw_circle(p, NODE_R, fill)
		draw_arc(p, NODE_R, 0, TAU, 32, Color.BLACK, 3.0)
		var mark := "✓" if GameState.is_cleared(id) else ("!" if unlocked else "?")
		UI.text(self, p + Vector2(-NODE_R, 10), mark, 28, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER, NODE_R * 2)
		var lw := UI.font().get_string_size(loc.name, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 14
		var lx := clampf(p.x - lw / 2, 4, size.x - lw - 4)
		draw_rect(Rect2(lx, p.y + NODE_R + 6, lw, 22), Color(1, 1, 0.95, 0.85))
		UI.text(self, Vector2(lx, p.y + NODE_R + 23), loc.name, 15, Color(0.2, 0.15, 0.1), HORIZONTAL_ALIGNMENT_CENTER, lw)

	# информация о выбранной локации
	var sel_id: String = order[selected]
	var sel := GameState.get_location(sel_id)
	var hidden := _hidden(sel_id)
	var r := Rect2(Vector2(size.x - 321, size.y - 136), Vector2(305, 120))
	UI.panel(self, r, Color(1, 1, 0.95, 0.95))
	UI.text(self, r.position + Vector2(14, 28), "???" if hidden else sel.name, 20, Color(0.1, 0.1, 0.1))
	draw_multiline_string(UI.font(), r.position + Vector2(14, 54), "Скрыто пеленой." if hidden else sel.desc,
		HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 28, 15, -1, Color(0.25, 0.25, 0.25))
	var status := ""
	if GameState.is_cleared(sel_id):
		var reward: String = sel.get("reward", "")
		status = "Пройдено" + (". Награда: %s" % Items.get_item(reward).name if reward != "" else "")
	elif GameState.is_unlocked(sel_id):
		status = "Enter / клик — войти"
	else:
		status = "Закрыто: сначала пройди предыдущую локацию"
	UI.text(self, r.position + Vector2(14, r.size.y - 12), status, 14, Color(0.5, 0.3, 0.1))
	UI.text(self, Vector2(size.x - 200, 28), "Esc — главное меню", 14, Color(0.3, 0.25, 0.2))


## Локации в скрытом царстве не видны, пока пелена не спала.
func _hidden(id: String) -> bool:
	return GameState.get_location(id).get("kingdom", "") == "demons" and not GameState.flag("demons_revealed")


func _dashed(a: Vector2, b: Vector2, col: Color) -> void:
	var n := int(a.distance_to(b) / 18.0)
	for k in n:
		if k % 2 == 0:
			draw_line(a.lerp(b, float(k) / n), a.lerp(b, float(k + 1) / n), col, 5.0)
