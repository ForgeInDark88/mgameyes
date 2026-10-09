extends RefCounted
## Мелкие помощники для интерфейса.

static func font() -> Font:
	return ThemeDB.fallback_font


static func text(ci: CanvasItem, pos: Vector2, s: String, size := 16, color := Color.BLACK,
		align := HORIZONTAL_ALIGNMENT_LEFT, width := -1.0) -> void:
	ci.draw_string(font(), pos, s, align, width, size, color)


static func panel(ci: CanvasItem, r: Rect2, fill := Color(1, 1, 1, 0.92), border := Color.BLACK) -> void:
	ci.draw_rect(r, fill)
	ci.draw_rect(r, border, false, 2.0)


static func make_button(label: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = label
	b.custom_minimum_size = Vector2(260, 48)
	b.add_theme_font_size_override("font_size", 22)
	b.pressed.connect(cb)
	return b
