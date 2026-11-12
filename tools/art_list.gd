extends SceneTree
## Dumps every work-scene piece and whether its art exists, as JSON, for ART_PROMPTS.md.
##   godot --headless --path . --script tools/art_list.gd > art_list.json

const Work := preload("res://scripts/work.gd")


func _init() -> void:
	var main := load("res://scripts/main.gd")
	var out := {}
	for id in Work.scenes():
		var def: Dictionary = Work.scenes()[id]
		var art: String = def.get("art", id)
		var name: String = main.FAULTS[id].name if main.FAULTS.has(id) else (main.TESTS[id].name if main.TESTS.has(id) else id)
		var pieces := []
		for e in def.els:
			if e.type == "fastener":
				continue
			var a: String = e.get("art", e.id)
			var files: Array = ["work/%s_%s_old" % [art, a], "work/%s_%s_new" % [art, a]] if e.type == "part" else ["work/%s_%s" % [art, a]]
			if e.type == "view" or e.get("dyn", false):
				files = []  # chosen by main.view_art: listed by hand
			var r: Rect2 = e.get("art_rect", e.rect)
			pieces.append({"id": e.id, "type": e.type, "name": e.get("label", e.get("name", e.id)), "rect": [r.position.x, r.position.y, r.size.x, r.size.y],
				"files": files, "have": files.map(func(f): return ResourceLoader.exists("res://textures/%s.png" % f)),
				"trap": e.has("trap")})
		out[id] = {"title": def.title, "name": name, "art": art, "desc": def.get("desc", ""),
			"bg": ResourceLoader.exists("res://textures/work/%s_bg.png" % art), "pieces": pieces}
	print(JSON.stringify(out))
	quit()
