@tool
extends RefCounted
## Диалог в виде обычного текста — чтобы писать его в Инспекторе Godot.
##
##   Кузнец Горан: Явален? Сын Эдрана?
##   Явален: Он самый.
##   Эльф: Пощадишь меня?
##   > Пощадить -> spared         варианты выбора для реплики выше (ставят флаг)
##   > Добить -> killed
##   [spared] Эльф: Спасибо...    реплика только если флаг стоит
##   [!spared] Эльф: ...          реплика только если флага нет
##   # комментарий                пустые строки и комментарии пропускаются
##
## Строка без «Имя:» — реплика без имени (рассказчик).


static func parse(text: String) -> Array:
	var lines: Array = []
	for raw in text.split("\n"):
		var s := raw.strip_edges()
		if s == "" or s.begins_with("#"):
			continue
		if s.begins_with(">"):
			if lines.is_empty():
				continue
			var parts := s.substr(1).split("->", true, 1)
			var flag := parts[1].strip_edges() if parts.size() > 1 else ""
			var last: Dictionary = lines[-1]
			if not last.has("choices"):
				last["choices"] = []
			last["choices"].append([parts[0].strip_edges(), flag])
			continue
		var line := {}
		if s.begins_with("["):
			var close := s.find("]")
			if close > 0:
				var cond := s.substr(1, close - 1).strip_edges()
				if cond.begins_with("!"):
					line["unless"] = cond.substr(1).strip_edges()
				else:
					line["if"] = cond
				s = s.substr(close + 1).strip_edges()
		var colon := s.find(":")
		if colon > 0:
			line["who"] = s.substr(0, colon).strip_edges()
			line["text"] = s.substr(colon + 1).strip_edges()
		else:
			line["who"] = ""
			line["text"] = s
		lines.append(line)
	return lines


## Обратно: реплики из campaigns.gd ([кто, текст] или словарь) → текст.
static func to_text(lines: Array) -> String:
	var out: PackedStringArray = []
	for l in lines:
		var d: Dictionary = l if l is Dictionary else {"who": l[0], "text": l[1]}
		var prefix := ""
		if d.has("if"):
			prefix = "[%s] " % d["if"]
		elif d.has("unless"):
			prefix = "[!%s] " % d["unless"]
		var who: String = d.get("who", "")
		out.append(prefix + (who + ": " if who != "" else "") + d.get("text", ""))
		for c in d.get("choices", []):
			out.append("> %s -> %s" % [c[0], c[1]])
	return "\n".join(out)
