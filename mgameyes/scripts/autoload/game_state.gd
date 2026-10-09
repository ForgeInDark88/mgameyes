extends Node
## Глобальное состояние игры: инвентарь, прогресс по локациям, сохранение.
## Доступно из любого скрипта как GameState.

signal inventory_changed
signal selected_changed(slot: int)

const Items := preload("res://scripts/data/items.gd")
const Locations := preload("res://scripts/data/locations.gd")

const SAVE_PATH := "user://save.json"
const HOTBAR_SIZE := 9
const BASE_MAX_HP := 6

## Слоты хотбара: null или {"id": String, "count": int}
var inventory: Array = []
var selected_slot := 0
var cleared: Array = []
var flags := {}
var current_location := ""


func _ready() -> void:
	_setup_input()
	new_game()


func new_game() -> void:
	inventory.clear()
	inventory.resize(HOTBAR_SIZE)
	selected_slot = 0
	cleared = []
	flags = {}
	current_location = ""
	add_item("sword")
	add_item("potion", 2)


# --- Инвентарь -------------------------------------------------------------

func add_item(id: String, count := 1) -> bool:
	if Items.is_stackable(id):
		for slot in inventory:
			if slot and slot.id == id:
				slot.count += count
				inventory_changed.emit()
				return true
	elif has_item(id):
		return true
	for i in HOTBAR_SIZE:
		if inventory[i] == null:
			inventory[i] = {"id": id, "count": count}
			inventory_changed.emit()
			return true
	return false


func has_item(id: String) -> bool:
	for slot in inventory:
		if slot and slot.id == id:
			return true
	return false


func selected_item_id() -> String:
	var slot = inventory[selected_slot]
	return slot.id if slot else ""


func consume_selected() -> void:
	var slot = inventory[selected_slot]
	if slot == null:
		return
	slot.count -= 1
	if slot.count <= 0:
		inventory[selected_slot] = null
	inventory_changed.emit()


func select_slot(i: int) -> void:
	selected_slot = wrapi(i, 0, HOTBAR_SIZE)
	selected_changed.emit(selected_slot)


func max_hp() -> int:
	return BASE_MAX_HP + (2 if has_item("heart") else 0)


# --- Прогресс --------------------------------------------------------------

func is_cleared(id: String) -> bool:
	return id in cleared


func is_unlocked(id: String) -> bool:
	for req in Locations.get_location(id).requires:
		if not is_cleared(req):
			return false
	return true


## Отмечает локацию зачищенной. Возвращает id награды, если она выдана впервые.
func clear_location(id: String) -> String:
	if is_cleared(id):
		return ""
	cleared.append(id)
	var loc := Locations.get_location(id)
	add_item(loc.reward, loc.reward_count)
	save_game()
	return loc.reward


func all_cleared() -> bool:
	for id in Locations.ORDER:
		if not is_cleared(id):
			return false
	return true


# --- Сцены -----------------------------------------------------------------

func enter_location(id: String) -> void:
	current_location = id
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func go_to_world_map() -> void:
	get_tree().change_scene_to_file("res://scenes/world_map.tscn")


func go_to_main_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


# --- Сохранение ------------------------------------------------------------

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({
		"inventory": inventory,
		"selected_slot": selected_slot,
		"cleared": cleared,
		"flags": flags,
	}))


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func load_game() -> bool:
	if not has_save():
		return false
	var data = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(data) != TYPE_DICTIONARY:
		return false
	new_game()
	var inv: Array = data.get("inventory", [])
	for i in mini(inv.size(), HOTBAR_SIZE):
		if inv[i] is Dictionary:
			inventory[i] = {"id": str(inv[i].id), "count": int(inv[i].count)}
		else:
			inventory[i] = null
	selected_slot = int(data.get("selected_slot", 0))
	cleared = data.get("cleared", [])
	flags = data.get("flags", {})
	inventory_changed.emit()
	return true


# --- Управление ------------------------------------------------------------

func _setup_input() -> void:
	_add_keys("move_left", [KEY_A, KEY_LEFT])
	_add_keys("move_right", [KEY_D, KEY_RIGHT])
	_add_keys("jump", [KEY_SPACE, KEY_W, KEY_UP])
	_add_keys("use_item", [KEY_J])
	_add_mouse("use_item", MOUSE_BUTTON_LEFT)
	_add_keys("ui_accept", [KEY_E])
	_add_keys("pause", [KEY_ESCAPE])
	for i in HOTBAR_SIZE:
		_add_keys("slot_%d" % (i + 1), [KEY_1 + i])


func _add_keys(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _add_mouse(action: String, button: MouseButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	var ev := InputEventMouseButton.new()
	ev.button_index = button
	InputMap.action_add_event(action, ev)
