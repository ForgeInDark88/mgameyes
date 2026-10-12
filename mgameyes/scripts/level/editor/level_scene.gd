@tool
extends Node2D
## Уровень, нарисованный в редакторе Godot (вместо символьной карты в campaigns.gd).
##
## Внутри сцены:
##   Map (TileMapLayer)  — земля, платформы, враги, предметы, старт P и выход X.
##                         Тайлы из levels/level_tiles.tres, 1 тайл = 1 символ карты.
##   NpcSpot             — житель с репликами (npc_spot.gd).
##   EchoSpot            — голос-«помеха» (echo_spot.gd).
##
## Игра ищет сцену по пути levels/<кампания>/<id локации>.tscn
## (или по полю "scene" у локации) и использует её вместо "map".
## Название, награда, "requires" и катсцены по-прежнему задаются в campaigns.gd.
##
## F6 на открытой сцене — сразу сыграть этот уровень (с наградами всех уровней до него).
## В этом режиме игра не сохраняется, а выход из уровня закрывает игру.

const Campaigns := preload("res://scripts/data/campaigns.gd")
const Themes := preload("res://scripts/data/themes.gd")
const DialogText := preload("res://scripts/data/dialog_text.gd")
const NpcSpot := preload("res://scripts/level/editor/npc_spot.gd")
const EchoSpot := preload("res://scripts/level/editor/echo_spot.gd")
const TILE := 32

## Оформление: village, fields, road, forest, camp, burned, sewer, dungeon, city,
## throne, fort, river, pass, ice, ruins. Пусто — как в campaigns.gd.
@export var theme := "":
	set(v):
		theme = v
		queue_redraw()
## Реплики в начале уровня (пусто — берутся из campaigns.gd). Строка: «Имя: текст».
@export_multiline var intro := ""
## Реплики после зачистки уровня (пусто — из campaigns.gd).
@export_multiline var outro := ""


func _validate_property(property: Dictionary) -> void:
	if property.name == "theme":
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(Themes.DATA.keys())


func _ready() -> void:
	if Engine.is_editor_hint():
		var map := _map()
		if map:
			map.changed.connect(queue_redraw)
	else:
		# игра загружает сцену уровня, не добавляя её в дерево, —
		# значит, сюда попадаем, только если сцену запустили по F6
		_play_test.call_deferred()


func _play_test() -> void:
	var parts := scene_file_path.trim_prefix("res://levels/").get_basename().split("/")
	var cid := parts[0] if parts.size() == 2 else ""
	var lid := parts[-1]
	var gs := get_node("/root/GameState")  # автозагрузка; по имени — чтобы скрипт работал и в редакторе
	var camp: Dictionary = Campaigns.CAMPAIGNS.get(cid, {})
	var known: bool = camp.get("locations", {}).has(lid)
	gs.new_game(cid if known else Campaigns.DEFAULT)
	gs.test_scene = scene_file_path
	if known:
		# пройти уровни до этого, чтобы у героя были их награды и навыки
		for id in gs.location_order():
			if id == lid:
				break
			gs.clear_location(id)
	var armed := false
	for w in ["sword", "warglaives", "demon_blade"]:
		armed = armed or gs.has_item(w)
	if not armed and not camp.get("locations", {}).get(lid, {}).get("goal", "").begins_with("item:"):
		gs.add_item("sword")
	gs.current_location = lid
	get_tree().change_scene_to_file("res://scenes/level.tscn")


func _map() -> TileMapLayer:
	for c in get_children():
		if c is TileMapLayer:
			return c
	return null


## Фон темы под картой — только в редакторе, чтобы видеть, как будет выглядеть уровень.
func _draw() -> void:
	if not Engine.is_editor_hint() or theme == "":
		return
	var map := _map()
	if map == null:
		return
	var r := map.get_used_rect()
	if r.size == Vector2i.ZERO:
		return
	draw_set_transform(Vector2(r.position * TILE))
	Themes.draw_background(self, theme, r.size.x * TILE, r.size.y * TILE)


## Собрать из сцены данные локации в том же виде, что в campaigns.gd
## ("map" — строки символов, "npc", "echoes", "intro", "outro", "theme").
## base — описание локации из campaigns.gd, его поля сцена дополняет.
## Жители берутся только из сцены. Голоса, intro и outro — из сцены, если они там есть,
## иначе из campaigns.gd.
func build_location(base: Dictionary) -> Dictionary:
	var loc := base.duplicate()
	var map := _map()
	if map == null:
		push_error("В сцене уровня нет узла TileMapLayer")
		return loc
	var r := map.get_used_rect()
	var rows: Array = []
	for y in r.size.y:
		var row := ""
		for x in r.size.x:
			var data := map.get_cell_tile_data(r.position + Vector2i(x, y))
			var ch: String = data.get_custom_data("symbol") if data else "."
			row += ch if ch != "" else "."
		rows.append(row)

	# жители и голоса: клетка — та, на которой стоят ноги узла
	var npc: Array = []
	var echoes: Array = []
	for c in get_children():
		if not c is Node2D:
			continue
		var cell := Vector2i(floori(c.position.x / TILE), floori((c.position.y - 1.0) / TILE)) - r.position
		if c.get_script() == NpcSpot:
			if cell.y < 0 or cell.y >= rows.size() or cell.x < 0 or cell.x >= r.size.x:
				push_warning("Житель %s стоит за пределами карты" % c.name)
				continue
			var row: String = rows[cell.y]
			row[cell.x] = "N"
			rows[cell.y] = row
			npc.append({"cell": cell, "look": c.look, "lines": DialogText.parse(c.dialog)})
		elif c.get_script() == EchoSpot:
			echoes.append([cell.x, DialogText.parse(c.dialog)])

	# уровень раздаёт реплики жителям по порядку символов N (слева направо, сверху вниз)
	npc.sort_custom(func(a, b): return a.cell.y < b.cell.y or (a.cell.y == b.cell.y and a.cell.x < b.cell.x))
	loc["map"] = rows
	loc["npc"] = npc
	if not echoes.is_empty():
		echoes.sort_custom(func(a, b): return a[0] < b[0])
		loc["echoes"] = echoes
	if theme != "":
		loc["theme"] = theme
	if intro.strip_edges() != "":
		loc["intro"] = DialogText.parse(intro)
	if outro.strip_edges() != "":
		loc["outro"] = DialogText.parse(outro)
	return loc
