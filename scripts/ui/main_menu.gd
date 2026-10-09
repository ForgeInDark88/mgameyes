extends Control
## Главное меню.

const UI := preload("res://scripts/ui/ui_util.gd")


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.93, 0.93, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	box.grow_horizontal = Control.GROW_DIRECTION_BOTH
	box.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(box)

	var title := Label.new()
	title.text = "Зелёный странник"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.1, 0.5, 0.22))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "сюжетный платформер"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	box.add_child(sub)
	box.add_child(Control.new())

	var cont := UI.make_button("Продолжить", _on_continue)
	cont.disabled = not GameState.has_save()
	box.add_child(cont)
	box.add_child(UI.make_button("Новая игра", _on_new_game))
	box.add_child(UI.make_button("Выход", func(): get_tree().quit()))

	var help := Label.new()
	help.text = "A/D — ходьба   Пробел — прыжок   ЛКМ/J — использовать предмет\n1–9 / колёсико — выбор предмета   Esc — пауза"
	help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	help.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	box.add_child(help)
	(cont if not cont.disabled else box.get_child(4)).grab_focus()


func _on_continue() -> void:
	if GameState.load_game():
		GameState.go_to_world_map()


func _on_new_game() -> void:
	GameState.new_game()
	GameState.save_game()
	GameState.go_to_world_map()
