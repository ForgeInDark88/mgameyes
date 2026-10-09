extends Node2D
## Уровень (локация). Строится из символьной карты в locations.gd.

const TILE := 32
const Locations := preload("res://scripts/data/locations.gd")
const Items := preload("res://scripts/data/items.gd")
const PlayerScript := preload("res://scripts/level/player.gd")
const WalkerScript := preload("res://scripts/level/enemy_walker.gd")
const ArcherScript := preload("res://scripts/level/enemy_archer.gd")
const BlockScript := preload("res://scripts/level/breakable_block.gd")
const PickupScript := preload("res://scripts/level/pickup.gd")
const SpikesScript := preload("res://scripts/level/spikes.gd")
const ExitScript := preload("res://scripts/level/exit_portal.gd")
const HudScript := preload("res://scripts/ui/hud.gd")

const COLOR_GROUND := Color(0.28, 0.27, 0.3)
const COLOR_PLATFORM := Color(0.08, 0.08, 0.08)

var location_id := ""
var location: Dictionary
var grid: Array[String] = []
var map_size := Vector2i.ZERO
var player: CharacterBody2D
var hud: CanvasLayer
var exit_portal: Area2D
var enemies_alive := 0
var is_cleared := false

var _terrain_rects: Array = []  # [Rect2, Color]


func _ready() -> void:
	location_id = GameState.current_location
	if location_id == "":
		location_id = Locations.ORDER[0]
	location = Locations.get_location(location_id)
	_load_grid(location.map)
	_build()
	hud = HudScript.new()
	add_child(hud)
	hud.setup(self)
	hud.dialog.show_lines(location.intro)


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

	var drawer := Node2D.new()
	drawer.name = "TerrainDrawer"
	drawer.z_index = -1
	add_child(drawer)
	drawer.draw.connect(func():
		# всё за пределами карты — сплошная земля
		var w := map_size.x * TILE
		var h := map_size.y * TILE
		drawer.draw_rect(Rect2(-2000, h, w + 4000, 2000), COLOR_GROUND)
		drawer.draw_rect(Rect2(-2000, -2000, 2000, h + 2000), COLOR_GROUND)
		drawer.draw_rect(Rect2(w, -2000, 2000, h + 2000), COLOR_GROUND)
		drawer.draw_rect(Rect2(0, -2000, w, 2000), COLOR_GROUND)
		for r in _terrain_rects:
			drawer.draw_rect(r[0], r[1])
	)
	move_child(drawer, 0)


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
	_terrain_rects.append([rect, COLOR_PLATFORM if one_way else COLOR_GROUND])


func _spawn_entity(ch: String, x: int, y: int) -> void:
	# точка "ног" — низ клетки
	var feet := Vector2(x * TILE + TILE / 2.0, (y + 1) * TILE)
	match ch:
		"P":
			player = PlayerScript.new()
			player.position = feet
			player.died.connect(_on_player_died)
			add_child(player)
			_setup_camera()
		"W":
			_add_enemy(WalkerScript.new(), feet)
		"A":
			_add_enemy(ArcherScript.new(), feet - Vector2(0, TILE / 2.0))
		"B":
			var b := BlockScript.new()
			b.position = Vector2(x * TILE, y * TILE) + Vector2.ONE * TILE / 2.0
			add_child(b)
		"^":
			var s := SpikesScript.new()
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
	var lines: Array = []
	if reward != "":
		hud.show_banner("Локация зачищена! Получено: %s" % Items.get_item(reward).name)
		lines = location.outro.duplicate()
		lines.append(["Новый предмет", "%s — %s" % [Items.get_item(reward).name, Items.get_item(reward).desc]])
		hud.dialog.show_lines(lines)
	else:
		hud.show_banner("Локация зачищена! Выход открыт.")
	if reward == "heart":
		player.refresh_max_hp()


func _on_exit_entered() -> void:
	if is_cleared:
		GameState.save_game()
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
