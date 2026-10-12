@tool
extends RefCounted
## Превращает символьную карту из campaigns.gd в сцену уровня для редактора.

const Campaigns := preload("res://scripts/data/campaigns.gd")
const DialogText := preload("res://scripts/data/dialog_text.gd")
const LevelScene := preload("res://scripts/level/editor/level_scene.gd")
const NpcSpot := preload("res://scripts/level/editor/npc_spot.gd")
const EchoSpot := preload("res://scripts/level/editor/echo_spot.gd")
const TILES := "res://levels/level_tiles.tres"
const TILE := 32


static func scene_path(campaign_id: String, location_id: String) -> String:
	return "res://levels/%s/%s.tscn" % [campaign_id, location_id]


## Сохранить локацию как сцену. Возвращает путь или "" при ошибке.
static func convert_location(campaign_id: String, location_id: String, overwrite := false) -> String:
	var loc: Dictionary = Campaigns.get_campaign(campaign_id).locations.get(location_id, {})
	if not loc.has("map"):
		push_error("Нет карты у локации %s/%s" % [campaign_id, location_id])
		return ""
	var path := scene_path(campaign_id, location_id)
	if not overwrite and ResourceLoader.exists(path):
		print("Пропускаю, сцена уже есть: ", path)
		return path
	var root := build_scene(location_id, loc)
	DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	var packed := PackedScene.new()
	packed.pack(root)
	var err := ResourceSaver.save(packed, path)
	root.free()
	if err != OK:
		push_error("Не удалось сохранить %s (ошибка %d)" % [path, err])
		return ""
	print("Готово: ", path)
	return path


static func build_scene(node_name: String, loc: Dictionary) -> Node2D:
	var root := Node2D.new()
	root.name = node_name
	root.set_script(LevelScene)
	root.theme = loc.get("theme", "")
	root.intro = DialogText.to_text(loc.get("intro", []))
	root.outro = DialogText.to_text(loc.get("outro", []))

	var tiles: TileSet = load(TILES)
	var map := TileMapLayer.new()
	map.name = "Map"
	map.tile_set = tiles
	root.add_child(map)
	map.owner = root
	var atlas := symbol_atlas(tiles)

	var npcs: Array = loc.get("npc", [])
	var npc_i := 0
	var rows: Array = loc.map
	for y in rows.size():
		var row: String = rows[y]
		for x in row.length():
			var ch := row[x]
			if ch == ".":
				continue
			if ch == "N":
				var n := Node2D.new()
				n.set_script(NpcSpot)
				n.name = "Npc%d" % (npc_i + 1)
				n.position = Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
				if npc_i < npcs.size():
					var e = npcs[npc_i]
					n.look = e.get("look", "smith") if e is Dictionary else "smith"
					n.dialog = DialogText.to_text(e.lines if e is Dictionary else e)
				npc_i += 1
				root.add_child(n)
				n.owner = root
			elif atlas.has(ch):
				map.set_cell(Vector2i(x, y), 0, atlas[ch])
			else:
				push_warning("Неизвестный символ '%s' в клетке %d,%d" % [ch, x, y])

	var i := 0
	for e in loc.get("echoes", []):
		i += 1
		var echo := Node2D.new()
		echo.set_script(EchoSpot)
		echo.name = "Echo%d" % i
		echo.position = Vector2(e[0] * TILE, (rows.size() - 2) * TILE)
		echo.dialog = DialogText.to_text(e[1])
		root.add_child(echo)
		echo.owner = root
	return root


## символ карты → координаты тайла в атласе
static func symbol_atlas(tiles: TileSet) -> Dictionary:
	var out := {}
	var src := tiles.get_source(0) as TileSetAtlasSource
	for i in src.get_tiles_count():
		var c := src.get_tile_id(i)
		out[src.get_tile_data(c, 0).get_custom_data("symbol")] = c
	return out
