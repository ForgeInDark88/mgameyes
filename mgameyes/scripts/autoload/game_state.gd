extends Node
## Глобальное состояние игры: кампания, инвентарь, навыки, прогресс, сохранение.
## Доступно из любого скрипта как GameState.

signal inventory_changed
signal selected_changed(slot: int)
signal skill_revealed(id: String)

const Items := preload("res://scripts/data/items.gd")
const Campaigns := preload("res://scripts/data/campaigns.gd")
const Skills := preload("res://scripts/data/skills.gd")

const SAVE_PATH := "user://save.json"
const HOTBAR_SIZE := 9
const BASE_MAX_HP := 100
const DEMON_BONUS := 2

## Слоты хотбара: null или {"id": String, "count": int}
var inventory: Array = []
var selected_slot := 0
var cleared: Array = []
var flags := {}
var current_location := ""
var campaign_id := Campaigns.DEFAULT
## Навыки героя и те, о которых он уже знает.
var skills: Array = []
var revealed_skills: Array = []
## Катсцена, которую надо показать, и куда идти после неё.
var pending_cutscene: Array = []
var pending_next := "world_map"


func _ready() -> void:
	_setup_input()
	new_game()


func new_game(campaign := Campaigns.DEFAULT) -> void:
	campaign_id = campaign
	inventory.clear()
	inventory.resize(HOTBAR_SIZE)
	selected_slot = 0
	cleared = []
	flags = {}
	current_location = ""
	skills = []
	revealed_skills = []
	for id in hero().get("skills", []):
		grant_skill(id, false)
	for it in campaign().get("start_items", []):
		add_item(it[0], it[1])


func campaign() -> Dictionary:
	return Campaigns.get_campaign(campaign_id)


func hero() -> Dictionary:
	return campaign().get("hero", {"name": "Герой", "look": "yavalen", "skills": []})


## Внешность героя (Париус меняется после артефакта Пегруса).
func hero_look() -> String:
	var h := hero()
	if flag("pegrus") and h.has("demon_look"):
		return h.demon_look
	return h.look


func get_location(id: String) -> Dictionary:
	return campaign().locations.get(id, {})


func location_order() -> Array:
	return campaign().order


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


## Заменить предмет другим в той же ячейке (например, меч → демонический клинок).
func replace_item(old_id: String, new_id: String) -> void:
	for i in HOTBAR_SIZE:
		if inventory[i] and inventory[i].id == old_id:
			inventory[i] = {"id": new_id, "count": 1}
			inventory_changed.emit()
			return
	add_item(new_id)


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
	return BASE_MAX_HP + (30 if has_item("heart") else 0)


# --- Навыки и урон героя ---------------------------------------------------

func has_skill(id: String) -> bool:
	return id in skills


func is_skill_revealed(id: String) -> bool:
	return id in revealed_skills


func grant_skill(id: String, announce := true) -> void:
	if not has_skill(id):
		skills.append(id)
	if not Skills.get_skill(id).get("hidden", false):
		if announce:
			reveal_skill(id)
		elif not is_skill_revealed(id):
			revealed_skills.append(id)


func active_skills() -> Array:
	return skills.filter(func(id): return Skills.is_active(id))


func reveal_skill(id: String) -> void:
	if has_skill(id) and not is_skill_revealed(id):
		revealed_skills.append(id)
		skill_revealed.emit(id)


## Любой урон от героя проходит здесь, чтобы учитывать навыки.
func player_hit(target: Object, base: int, from: Vector2) -> void:
	if target == null or not target.has_method("take_damage"):
		return
	if target.is_in_group("demons") and has_skill("erin_blood"):
		# Кровь рода Эрин работает с самого начала — герой просто ещё не знает об этом
		target.take_damage(base * DEMON_BONUS, from, true)
		reveal_skill("erin_blood")
	else:
		target.take_damage(base, from)


func flag(name: String) -> bool:
	return bool(flags.get(name, false))


func set_flag(name: String, value := true) -> void:
	flags[name] = value


# --- Прогресс --------------------------------------------------------------

func is_cleared(id: String) -> bool:
	return id in cleared


func is_unlocked(id: String) -> bool:
	for req in get_location(id).get("requires", []):
		if not is_cleared(req):
			return false
	return true


## Отмечает локацию зачищенной. Возвращает id награды, если она выдана впервые.
func clear_location(id: String) -> String:
	if is_cleared(id):
		return ""
	cleared.append(id)
	var loc := get_location(id)
	if loc.has("on_clear_flag"):
		set_flag(loc.on_clear_flag)
	if loc.has("on_clear_replace"):
		replace_item(loc.on_clear_replace[0], loc.on_clear_replace[1])
	if loc.has("on_clear_skill"):
		grant_skill(loc.on_clear_skill, false)
	var reward: String = loc.get("reward", "")
	if reward != "":
		add_item(reward, loc.get("reward_count", 1))
	save_game()
	return reward


func all_cleared() -> bool:
	for id in location_order():
		if not is_cleared(id):
			return false
	return true


# --- Сцены -----------------------------------------------------------------

func enter_location(id: String) -> void:
	current_location = id
	get_tree().change_scene_to_file("res://scenes/level.tscn")


## Начальная катсцена кампании.
func go_to_cutscene() -> void:
	play_cutscene(campaign().get("intro", []), "world_map")
	set_flag("intro_seen")


func play_cutscene(steps: Array, next := "world_map") -> void:
	pending_cutscene = steps
	pending_next = next
	get_tree().change_scene_to_file("res://scenes/cutscene.tscn")


func go_to(next: String) -> void:
	match next:
		"main_menu":
			go_to_main_menu()
		_:
			go_to_world_map()


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
		"campaign": campaign_id,
		"skills": skills,
		"revealed_skills": revealed_skills,
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
	new_game(str(data.get("campaign", Campaigns.DEFAULT)))
	skills = data.get("skills", skills)
	revealed_skills = data.get("revealed_skills", [])
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
	_add_keys("skill_1", [KEY_Q])
	_add_keys("skill_2", [KEY_R])
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
