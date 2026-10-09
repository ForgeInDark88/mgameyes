extends CanvasLayer
## Интерфейс уровня: здоровье, хотбар, миникарта, диалоги, пауза.

const UI := preload("res://scripts/ui/ui_util.gd")
const HotbarScript := preload("res://scripts/ui/hotbar.gd")
const MinimapScript := preload("res://scripts/ui/minimap.gd")
const DialogScript := preload("res://scripts/ui/dialog_box.gd")
const Skills := preload("res://scripts/data/skills.gd")

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
	# полоска здоровья
	var bar := Rect2(20, 18, 300, 22)
	_top.draw_rect(bar, Color(0.2, 0.2, 0.22))
	var ratio := clampf(float(p.hp) / p.max_hp, 0.0, 1.0)
	var col := Color(0.85, 0.15, 0.2) if ratio > 0.3 else Color(1.0, 0.45, 0.1)
	_top.draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), col)
	_top.draw_rect(bar, Color.BLACK, false, 2.0)
	UI.text(_top, bar.position + Vector2(0, 17), "HP  %d / %d" % [p.hp, p.max_hp], 15, Color.WHITE,
		HORIZONTAL_ALIGNMENT_CENTER, bar.size.x)
	# навыки героя (скрытые показываются как «???»)
	var x := 20.0
	for id in GameState.skills:
		var revealed := GameState.is_skill_revealed(id)
		var r := Rect2(x, 48, 32, 32)
		UI.panel(_top, r, Color(1, 1, 1, 0.9))
		Skills.draw_icon(_top, id, r, revealed)
		var label := "%s — %s" % [Skills.get_skill(id).name, Skills.get_skill(id).desc] if revealed else "??? — скрытый навык"
		UI.text(_top, Vector2(x + 40, 70), label, 15, Color(0.15, 0.15, 0.15))
		x += 300.0
	UI.text(_top, Vector2(0, 36), level.goal_text(), 20, Color(0.15, 0.15, 0.15), HORIZONTAL_ALIGNMENT_RIGHT, _top.size.x - 20)
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
