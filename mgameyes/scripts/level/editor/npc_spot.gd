@tool
extends Node2D
## Житель на уровне-сцене. Ставь узел ногами на землю; реплики пиши в Инспекторе.
## Формат реплик — см. scripts/data/dialog_text.gd.

const Characters := preload("res://scripts/data/characters.gd")

## Внешность (список — в scripts/data/characters.gd)
@export var look := "smith":
	set(v):
		look = v
		queue_redraw()
## Что житель скажет, когда герой подойдёт. Каждая строка: «Имя: текст».
@export_multiline var dialog := "":
	set(v):
		dialog = v
		queue_redraw()


func _validate_property(property: Dictionary) -> void:
	if property.name == "look":
		var looks: Array = Characters.LOOKS.keys()
		looks.append("smith_wounded")
		property.hint = PROPERTY_HINT_ENUM_SUGGESTION
		property.hint_string = ",".join(looks)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	Characters.draw_npc(self, look)
	var font := ThemeDB.fallback_font
	var first := dialog.strip_edges().get_slice("\n", 0)
	var label := first.left(28) + ("…" if first.length() > 28 else "") if first != "" else "(нет реплик)"
	draw_string(font, Vector2(-80, -72), label, HORIZONTAL_ALIGNMENT_CENTER, 160, 12, Color(0.1, 0.1, 0.1))
