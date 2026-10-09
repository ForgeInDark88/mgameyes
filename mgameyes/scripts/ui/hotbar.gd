extends Control
## Хотбар снизу экрана: 9 ячеек, выбор клавишами 1–9 или колёсиком.

const Items := preload("res://scripts/data/items.gd")
const UI := preload("res://scripts/ui/ui_util.gd")
const SLOT := 64.0
const GAP := 4.0


func _ready() -> void:
	var n := GameState.HOTBAR_SIZE
	custom_minimum_size = Vector2(n * SLOT + (n - 1) * GAP, SLOT + 28)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	GameState.inventory_changed.connect(queue_redraw)
	GameState.selected_changed.connect(func(_i): queue_redraw())


func _draw() -> void:
	var sel := GameState.selected_slot
	for i in GameState.HOTBAR_SIZE:
		var r := Rect2(i * (SLOT + GAP), 28, SLOT, SLOT)
		UI.panel(self, r, Color(1, 1, 1, 0.9) if i != sel else Color(1, 0.95, 0.7, 0.95),
			Color.BLACK if i != sel else Color(0.9, 0.55, 0.0))
		if i == sel:
			draw_rect(r.grow(-3), Color(0.9, 0.55, 0.0), false, 3.0)
		UI.text(self, r.position + Vector2(5, 15), str(i + 1), 12, Color(0.4, 0.4, 0.4))
		var slot = GameState.inventory[i]
		if slot:
			Items.draw_icon(self, slot.id, r.grow(-8))
			if slot.count > 1:
				UI.text(self, r.end - Vector2(20, 6), str(slot.count), 16, Color.BLACK)
	var id := GameState.selected_item_id()
	if id != "":
		var it := Items.get_item(id)
		var label := "%s — %s" % [it.name, it.desc]
		var w := UI.font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 16).x + 20
		draw_rect(Rect2((size.x - w) / 2, 2, w, 24), Color(1, 1, 1, 0.85))
		UI.text(self, Vector2(0, 20), label, 16, Color(0.1, 0.1, 0.1), HORIZONTAL_ALIGNMENT_CENTER, size.x)
