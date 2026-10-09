extends Control
## Миникарта уровня (слева снизу, как на концепте).

const UI := preload("res://scripts/ui/ui_util.gd")
const MAP_SIZE := Vector2(230, 150)
const LABEL_H := 24.0
const TILE := 32.0

var level: Node2D


func _ready() -> void:
	custom_minimum_size = MAP_SIZE + Vector2(0, LABEL_H)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	UI.panel(self, Rect2(Vector2.ZERO, size))
	draw_line(Vector2(0, MAP_SIZE.y), Vector2(size.x, MAP_SIZE.y), Color.BLACK, 2.0)
	if level == null:
		return
	UI.text(self, Vector2(0, size.y - 6), level.location.name, 14, Color.BLACK, HORIZONTAL_ALIGNMENT_CENTER, size.x)
	var world := Vector2(level.map_size) * TILE
	var pad := 8.0
	var s := minf((MAP_SIZE.x - pad * 2) / world.x, (MAP_SIZE.y - pad * 2) / world.y)
	var origin := (MAP_SIZE - world * s) / 2.0
	var cell := TILE * s
	for y in level.map_size.y:
		for x in level.map_size.x:
			var ch: String = level.grid[y][x]
			if ch == "#":
				draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, cell)), Color(0.35, 0.35, 0.38))
			elif ch == "=":
				draw_rect(Rect2(origin + Vector2(x, y) * cell, Vector2(cell, maxf(cell * 0.4, 1.0))), Color.BLACK)
	for b in get_tree().get_nodes_in_group("breakable"):
		var p: Vector2 = origin + b.global_position * s
		draw_rect(Rect2(p - Vector2(cell, cell) / 2, Vector2(cell, cell)), Color(0.72, 0.47, 0.32))
	if level.exit_portal:
		var ep: Vector2 = origin + level.exit_portal.global_position * s
		draw_rect(Rect2(ep - Vector2(cell / 2, cell * 2), Vector2(cell, cell * 2)),
			Color(0.3, 0.75, 1.0) if level.exit_portal.active else Color(0.2, 0.2, 0.2))
	for e in get_tree().get_nodes_in_group("enemies"):
		draw_circle(origin + e.global_position * s, maxf(cell * 0.6, 2.0), Color(0.9, 0.15, 0.15))
	if level.player:
		var pp: Vector2 = origin + level.player.center() * s
		draw_rect(Rect2(pp - Vector2(2, 4), Vector2(4, 8)).grow(1), Color(0.13, 0.7, 0.3))
