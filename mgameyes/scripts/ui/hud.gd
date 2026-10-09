extends CanvasLayer
## Интерфейс уровня: здоровье, хотбар, миникарта, диалоги, пауза.

const UI := preload("res://scripts/ui/ui_util.gd")
const HotbarScript := preload("res://scripts/ui/hotbar.gd")
const MinimapScript := preload("res://scripts/ui/minimap.gd")
const DialogScript := preload("res://scripts/ui/dialog_box.gd")

var level: Node2D
var dialog: Control
var hotbar: Control
var minimap: Control
var _top: Control
var _banner: Label
var _pause_menu: Control


func setup(lvl: Node2D) -> void:
	level = lvl
	process_mode = Node.PROCESS_MODE_ALWAYS
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_top = Control.new()
	_top.set_anchors_preset(Control.PRESET_FULL_RECT)
	_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top.draw.connect(_draw_top)
	root.add_child(_top)

	minimap = MinimapScript.new()
	minimap.level = level
	root.add_child(minimap)
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT, Control.PRESET_MODE_KEEP_SIZE, 16)

	hotbar = HotbarScript.new()
	root.add_child(hotbar)
	hotbar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 16)

	dialog = DialogScript.new()
	root.add_child(dialog)
	dialog.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM, Control.PRESET_MODE_KEEP_SIZE, 130)

	_banner = Label.new()
	_banner.add_theme_font_size_override("font_size", 30)
	_banner.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	_banner.add_theme_color_override("font_outline_color", Color.WHITE)
	_banner.add_theme_constant_override("outline_size", 8)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP, Control.PRESET_MODE_MINSIZE, 70)
	_banner.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_banner.modulate.a = 0.0
	root.add_child(_banner)

	_build_pause_menu(root)

	if level.player:
		level.player.hp_changed.connect(func(_a, _b): _top.queue_redraw())


func show_banner(text: String) -> void:
	_banner.text = text
	_banner.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(2.5)
	tw.tween_property(_banner, "modulate:a", 0.0, 0.8)


func _draw_top() -> void:
	var p = level.player
	if p == null:
		return
	# сердца
	for i in p.max_hp:
		var c := Vector2(30 + i * 34, 30)
		var full: bool = i < p.hp
		var col := Color(0.9, 0.15, 0.2) if full else Color(0.75, 0.75, 0.75)
		_top.draw_circle(c + Vector2(-6, -3), 8, col)
		_top.draw_circle(c + Vector2(6, -3), 8, col)
		_top.draw_colored_polygon(PackedVector2Array([c + Vector2(-14, 0), c + Vector2(14, 0), c + Vector2(0, 15)]), col)
	var enemies := get_tree().get_nodes_in_group("enemies").size()
	var info := "Врагов осталось: %d" % enemies if not level.is_cleared else "Зачищено! Иди к выходу →"
	UI.text(_top, Vector2(0, 36), info, 20, Color(0.15, 0.15, 0.15), HORIZONTAL_ALIGNMENT_RIGHT, _top.size.x - 20)
	UI.text(_top, Vector2(0, 36), level.location.name, 24, Color(0.1, 0.1, 0.1), HORIZONTAL_ALIGNMENT_CENTER, _top.size.x)


func _process(_delta: float) -> void:
	_top.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle_pause()
		get_viewport().set_input_as_handled()


func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	_pause_menu.visible = paused


func _build_pause_menu(root: Control) -> void:
	_pause_menu = ColorRect.new()
	_pause_menu.color = Color(0, 0, 0, 0.5)
	_pause_menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_pause_menu.visible = false
	root.add_child(_pause_menu)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	_pause_menu.add_child(box)
	var title := Label.new()
	title.text = "Пауза"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	box.add_child(title)
	box.add_child(UI.make_button("Продолжить", toggle_pause))
	box.add_child(UI.make_button("Начать локацию заново", func():
		get_tree().paused = false
		get_tree().reload_current_scene()))
	box.add_child(UI.make_button("Выйти на карту мира", func():
		get_tree().paused = false
		GameState.go_to_world_map()))
