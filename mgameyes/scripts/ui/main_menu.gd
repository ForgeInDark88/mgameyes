extends Control
## Главное меню: выбор кампании, продолжение, правила игры.

const UI := preload("res://scripts/ui/ui_util.gd")
const Campaigns := preload("res://scripts/data/campaigns.gd")

const HOW_TO_PLAY := """[b]Управление[/b]
A / D, ← / →   ходьба
Пробел / W   прыжок
ЛКМ / J   использовать выбранный предмет (целься мышью)
Q / R   активные навыки героя (у каждого есть перезарядка):
   Явален — Щит рода; Париус — Огонь правды и Демонический ожог
1–9, колёсико   выбор ячейки хотбара
Enter / E / клик   листать диалог
Esc   пауза, пропустить катсцену

[b]Как играть[/b]
• Проходи локации на карте трёх царств по порядку.
• Побеждай всех врагов, чтобы открыть выход.
• За локации даются предметы, и у каждого своя сила:
   меч ломает ящики и решётки, лук бьёт издалека,
   бомбы рушат завалы, сапоги дают двойной прыжок.
• Зелья лечат — выбери зелье и нажми ЛКМ.
• Слева сверху — здоровье и навыки героя. Некоторые
  навыки скрыты, пока герой о них не узнает.
• Пока идёт диалог, игра на паузе.
• У точки старта — лагерь: там безопасно, но и сражаться нельзя.
• Не падай в шипы и нечистоты.

[b]Кампании[/b]
1. «Одинокий странник» — Явален идёт в Царство эльфов.
2. «Чёрная участь» — история Париуса, десятью годами раньше."""

var _main_box: VBoxContainer
var _campaign_box: VBoxContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.93, 0.93, 0.9)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 60)
	row.set_anchors_and_offsets_preset(Control.PRESET_CENTER, Control.PRESET_MODE_MINSIZE)
	row.grow_horizontal = Control.GROW_DIRECTION_BOTH
	row.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(row)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 14)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_child(left)

	var title := Label.new()
	title.text = "Три царства"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 56)
	title.add_theme_color_override("font_color", Color(0.1, 0.5, 0.22))
	left.add_child(title)
	var sub := Label.new()
	sub.text = "сюжетный платформер"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 20)
	sub.add_theme_color_override("font_color", Color(0.35, 0.35, 0.35))
	left.add_child(sub)

	_main_box = VBoxContainer.new()
	_main_box.add_theme_constant_override("separation", 12)
	left.add_child(_main_box)
	var cont := UI.make_button("Продолжить", _on_continue)
	cont.disabled = not GameState.has_save()
	_main_box.add_child(cont)
	var start := UI.make_button("Выбор кампании", _show_campaigns.bind(true))
	_main_box.add_child(start)
	_main_box.add_child(UI.make_button("Выход", func(): get_tree().quit()))

	_campaign_box = VBoxContainer.new()
	_campaign_box.add_theme_constant_override("separation", 10)
	_campaign_box.visible = false
	left.add_child(_campaign_box)
	var head := Label.new()
	head.text = "Выбери кампанию"
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 24)
	head.add_theme_color_override("font_color", Color(0.2, 0.2, 0.2))
	_campaign_box.add_child(head)
	for id in Campaigns.CAMPAIGN_ORDER:
		var c: Dictionary = Campaigns.CAMPAIGNS[id]
		var b := Button.new()
		b.custom_minimum_size = Vector2(420, 78)
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 16)
		if c.available:
			b.text = "%s\n%s" % [c.name, c.desc]
			b.pressed.connect(_start_campaign.bind(id))
		else:
			b.text = "%s — скоро\n%s" % [c.name, c.desc]
			b.disabled = true
		_campaign_box.add_child(b)
	_campaign_box.add_child(UI.make_button("Назад", _show_campaigns.bind(false)))

	var help_panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 0.97)
	style.border_color = Color(0.2, 0.2, 0.2)
	style.set_border_width_all(2)
	style.set_content_margin_all(18)
	help_panel.add_theme_stylebox_override("panel", style)
	row.add_child(help_panel)
	var help := RichTextLabel.new()
	help.bbcode_enabled = true
	help.fit_content = true
	help.custom_minimum_size = Vector2(500, 0)
	help.add_theme_color_override("default_color", Color(0.15, 0.15, 0.15))
	help.add_theme_font_size_override("normal_font_size", 15)
	help.add_theme_font_size_override("bold_font_size", 18)
	help.text = HOW_TO_PLAY
	help_panel.add_child(help)

	(cont if not cont.disabled else start).grab_focus()


func _show_campaigns(show: bool) -> void:
	_main_box.visible = not show
	_campaign_box.visible = show
	var first: Control = (_campaign_box.get_child(1) if show else _main_box.get_child(1))
	first.grab_focus()


func _on_continue() -> void:
	if GameState.load_game():
		if GameState.flag("intro_seen"):
			GameState.go_to_world_map()
		else:
			GameState.go_to_cutscene()


func _start_campaign(id: String) -> void:
	GameState.new_game(id)
	GameState.save_game()
	GameState.go_to_cutscene()
