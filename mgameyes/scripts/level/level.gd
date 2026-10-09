extends Node2D
## Уровень (локация). Строится из символьной карты в campaigns.gd.

const TILE := 32
const Items := preload("res://scripts/data/items.gd")
const PlayerScript := preload("res://scripts/level/player.gd")
const WalkerScript := preload("res://scripts/level/enemy_walker.gd")
const ArcherScript := preload("res://scripts/level/enemy_archer.gd")
const BossScript := preload("res://scripts/level/enemy_boss.gd")
const DuelistScript := preload("res://scripts/level/enemy_duelist.gd")
const Themes := preload("res://scripts/data/themes.gd")
const NpcScript := preload("res://scripts/level/npc.gd")
const CampScript := preload("res://scripts/level/camp.gd")
const BlockScript := preload("res://scripts/level/breakable_block.gd")
const PickupScript := preload("res://scripts/level/pickup.gd")
const SpikesScript := preload("res://scripts/level/spikes.gd")
const ExitScript := preload("res://scripts/level/exit_portal.gd")
const HudScript := preload("res://scripts/ui/hud.gd")
const Skills := preload("res://scripts/data/skills.gd")


var location_id := ""
var location: Dictionary
var grid: Array[String] = []
var map_size := Vector2i.ZERO
var player: CharacterBody2D
var hud: CanvasLayer
var exit_portal: Area2D
var enemies_alive := 0
var is_cleared := false
var goal := "enemies"
## Лагерь вокруг точки старта: враги туда не заходят и не стреляют,
## а герой не может атаковать изнутри.
var safe_rect := Rect2()
var _npc_count := 0

var _terrain_rects: Array = []  # [Rect2, платформа?]
var theme_id := "road"
var theme: Dictionary


func _ready() -> void:
	location_id = GameState.current_location
	if location_id == "":
		location_id = GameState.location_order()[0]
	location = GameState.get_location(location_id)
	goal = location.get("goal", "enemies")
	theme_id = location.get("theme", "road")
	theme = Themes.get_theme(theme_id)
	_load_grid(location.map)
	_build()
	hud = HudScript.new()
	add_child(hud)
	hud.setup(self)
	hud.dialog.show_lines(location.get("intro", []))
	GameState.skill_revealed.connect(_on_skill_revealed)
	if goal.begins_with("item:"):
		GameState.inventory_changed.connect(_check_item_goal)
		_check_item_goal.call_deferred()
	elif enemies_alive == 0:
		_on_location_cleared.call_deferred()


func goal_text() -> String:
	if is_cleared:
		return "Выход открыт →"
	if location.has("goal_text"):
		return location.goal_text
	return "Врагов осталось: %d" % get_tree().get_nodes_in_group("enemies").size()


func _check_item_goal() -> void:
	if not is_cleared and GameState.has_item(goal.trim_prefix("item:")):
		_on_location_cleared()


func _on_skill_revealed(id: String) -> void:
	hud.show_banner("Открыт навык: %s" % Skills.get_skill(id).name)
	if id == "erin_blood":
		hud.dialog.show_lines(GameState.campaign().get("blood_reveal", []))


func _load_grid(rows: Array) -> void:
	var w := 0
	for r in rows:
		w = maxi(w, r.length())
	for r in rows:
		grid.append(r.rpad(w, "."))
	map_size = Vector2i(w, grid.size())


func cell_at(x: int, y: int) -> String:
	if y < 0 or y >= map_size.y or x < 0 or x >= map_size.x:
		return "#"
	return grid[y][x]


func _build() -> void:
	var terrain := StaticBody2D.new()
	terrain.name = "Terrain"
	terrain.collision_layer = 1
	terrain.collision_mask = 0
	add_child(terrain)

	for y in map_size.y:
		var x := 0
		while x < map_size.x:
			var ch := grid[y][x]
			if ch == "#" or ch == "=":
				# склеиваем горизонтальные отрезки в одну форму, чтобы игрок не цеплялся за стыки
				var start := x
				while x < map_size.x and grid[y][x] == ch:
					x += 1
				_add_terrain_run(terrain, start, x - start, y, ch == "=")
				continue
			_spawn_entity(ch, x, y)
			x += 1

	var ground: Color = theme.ground
	var bg := Node2D.new()
	bg.name = "Background"
	bg.z_index = -2
	add_child(bg)
	bg.draw.connect(func(): Themes.draw_background(bg, theme_id, map_size.x * TILE, map_size.y * TILE))
	var drawer := Node2D.new()
	drawer.name = "TerrainDrawer"
	drawer.z_index = -1
	add_child(drawer)
	drawer.draw.connect(func():
		# всё за пределами карты — сплошная земля
		var w := map_size.x * TILE
		var h := map_size.y * TILE
		drawer.draw_rect(Rect2(-2000, h, w + 4000, 2000), ground)
		drawer.draw_rect(Rect2(-2000, -2000, 2000, h + 2000), ground)
		drawer.draw_rect(Rect2(w, -2000, 2000, h + 2000), ground)
		drawer.draw_rect(Rect2(0, -2000, w, 2000), ground)
		for r in _terrain_rects:
			drawer.draw_rect(r[0], theme.platform if r[1] else ground)
			if r[1]:
				drawer.draw_rect(Rect2(r[0].position + Vector2(0, 8), Vector2(r[0].size.x, 4)), theme.platform.darkened(0.3))
		# трава / мох / край камня сверху у открытых клеток земли
		for y in range(1, map_size.y):
			for x in map_size.x:
				if grid[y][x] == "#" and grid[y - 1][x] != "#":
					drawer.draw_rect(Rect2(x * TILE, y * TILE, TILE, 6), theme.top)
	)
	move_child(drawer, 0)
	move_child(bg, 0)


func _add_terrain_run(body: StaticBody2D, x: int, length: int, y: int, one_way: bool) -> void:
	var rect := Rect2(x * TILE, y * TILE, length * TILE, TILE)
	var shape := RectangleShape2D.new()
	var cs := CollisionShape2D.new()
	if one_way:
		rect.size.y = 10
		cs.one_way_collision = true
	shape.size = rect.size
	cs.shape = shape
	cs.position = rect.get_center()
	body.add_child(cs)
	_terrain_rects.append([rect, one_way])


func _spawn_entity(ch: String, x: int, y: int) -> void:
	# точка "ног" — низ клетки
	var feet := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
	match ch:
		"P":
			player = PlayerScript.new()
			player.position = feet
			safe_rect = Rect2(feet.x - 5.5 * TILE, feet.y - 7 * TILE, 11 * TILE, 7 * TILE)
			safe_rect = safe_rect.intersection(Rect2(TILE, TILE, (map_size.x - 2) * TILE, (map_size.y - 1) * TILE))
			var camp := CampScript.new()
			camp.position = feet + Vector2(TILE * 1.5, 0)
			add_child(camp)
			player.died.connect(_on_player_died)
			add_child(player)
			_setup_camera()
		"e", "W", "r", "G":
			var w := WalkerScript.new()
			w.variant = {"e": "elf", "W": "demon", "r": "rat", "G": "guardian"}[ch]
			_add_enemy(w, feet)
		"a", "m":
			var a := ArcherScript.new()
			a.variant = "elf" if ch == "a" else "mage"
			_add_enemy(a, feet)
		"L", "Y":
			var d := DuelistScript.new()
			d.look = "liael" if ch == "L" else "yavalen"
			d.display_name = "Лиаэль" if ch == "L" else "Явален"
			_add_enemy(d, feet)
		"A":
			var a := ArcherScript.new()
			a.variant = "demon"
			_add_enemy(a, feet - Vector2(0, TILE / 2.0))
		"M":
			_add_enemy(BossScript.new(), feet)
		"N":
			var n := NpcScript.new()
			var all_lines: Array = location.get("npc", [])
			if _npc_count < all_lines.size():
				var entry = all_lines[_npc_count]
				if entry is Dictionary:
					n.look = entry.get("look", "smith")
					n.lines = entry.lines
				else:
					n.lines = entry
			_npc_count += 1
			n.position = feet
			add_child(n)
		"s":
			_add_pickup("sword", feet)
		"B":
			var b := BlockScript.new()
			b.grate = theme_id in ["sewer", "dungeon"]
			b.position = Vector2(x * TILE, y * TILE) + Vector2.ONE * TILE / 2.0
			add_child(b)
		"^", "~":
			var s := SpikesScript.new()
			s.water = ch == "~"
			s.position = Vector2(x * TILE, y * TILE)
			add_child(s)
		"h":
			_add_pickup("potion", feet)
		"o":
			_add_pickup("bomb", feet)
		"X":
			exit_portal = ExitScript.new()
			exit_portal.position = feet
			exit_portal.entered.connect(_on_exit_entered)
			add_child(exit_portal)


func is_safe(pos: Vector2) -> bool:
	return safe_rect.has_point(pos)


## Добавить врага прямо во время боя (например, босс призывает подмогу).
func spawn_enemy(e: CharacterBody2D, pos: Vector2) -> void:
	_add_enemy.call_deferred(e, pos)


func _add_enemy(e: CharacterBody2D, pos: Vector2) -> void:
	e.position = pos
	e.died.connect(_on_enemy_died)
	enemies_alive += 1
	add_child(e)


func _add_pickup(id: String, feet: Vector2) -> void:
	var p := PickupScript.new()
	p.item_id = id
	p.position = feet - Vector2(0, 16)
	add_child(p)


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = map_size.x * TILE
	# снизу оставляем место под хотбар
	cam.limit_bottom = map_size.y * TILE + 140
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 8.0
	cam.offset = Vector2(0, 60)
	player.add_child(cam)


func _on_enemy_died() -> void:
	enemies_alive -= 1
	if enemies_alive <= 0 and not is_cleared:
		_on_location_cleared()


func _on_location_cleared() -> void:
	is_cleared = true
	if exit_portal:
		exit_portal.activate()
	var reward := GameState.clear_location(location_id)
	var lines: Array = location.get("outro", []).duplicate()
	if reward != "":
		hud.show_banner("Локация пройдена! Получено: %s" % Items.get_item(reward).name)
		lines.append(["Новый предмет", "%s — %s" % [Items.get_item(reward).name, Items.get_item(reward).desc]])
	else:
		hud.show_banner("Локация пройдена! Выход открыт.")
	# реплики показываются только при первом прохождении
	if reward != "" or not GameState.flag("outro_" + location_id):
		GameState.set_flag("outro_" + location_id)
		hud.dialog.show_lines(lines)
	if reward == "heart":
		player.refresh_max_hp()
	if location.has("on_clear_skill"):
		hud.show_banner("Новый навык: %s" % Skills.get_skill(location.on_clear_skill).name)


func _on_exit_entered() -> void:
	if is_cleared:
		GameState.save_game()
		# после некоторых локаций идёт катсцена (один раз)
		var cs: Array = location.get("cutscene_after", [])
		if not cs.is_empty() and not GameState.flag("cs_" + location_id):
			GameState.set_flag("cs_" + location_id)
			GameState.play_cutscene.call_deferred(cs, "world_map")
			return
		# менять сцену прямо в физическом колбэке нельзя
		GameState.go_to_world_map.call_deferred()


func _on_player_died() -> void:
	hud.show_banner("Вы погибли...")
	await get_tree().create_timer(1.5).timeout
	get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			GameState.select_slot(GameState.selected_slot - 1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			GameState.select_slot(GameState.selected_slot + 1)
	for i in GameState.HOTBAR_SIZE:
		if event.is_action_pressed("slot_%d" % (i + 1)):
			GameState.select_slot(i)
