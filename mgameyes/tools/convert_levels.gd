@tool
extends EditorScript
## Переносит уровни из campaigns.gd в сцены levels/<кампания>/<id>.tscn,
## чтобы рисовать их в редакторе.
##
## Как запустить: открой этот файл во вкладке Script и нажми
## File → Run (Ctrl+Shift+X). Готовые сцены не перезаписываются.
## После переноса игра берёт карту, жителей и реплики уровня из сцены.

## Какие уровни перенести: ["village", "fields"]. Пусто — все уровни кампании.
const LOCATIONS := []
## Кампания: lone_wanderer, black_fate, exile_blades. Пусто — все кампании.
const CAMPAIGN := ""

const Campaigns := preload("res://scripts/data/campaigns.gd")
const Converter := preload("res://scripts/level/editor/level_converter.gd")


func _run() -> void:
	for cid in Campaigns.CAMPAIGNS:
		if CAMPAIGN != "" and cid != CAMPAIGN:
			continue
		for lid in Campaigns.CAMPAIGNS[cid].get("locations", {}):
			if LOCATIONS.is_empty() or lid in LOCATIONS:
				Converter.convert_location(cid, lid)
	EditorInterface.get_resource_filesystem().scan()
