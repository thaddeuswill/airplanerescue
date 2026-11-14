extends SceneTree
## Builds fonts/ui_default.tres: Big Shoulders Display at weight 600, the project-wide default
## font (Project Settings > GUI > Theme > Custom Font). The .ttf alone opens at its default
## instance, Thin (100), which is unreadable at UI sizes.
##   godot --headless --path . --script tools/make_ui_font.gd
func _init() -> void:
	var f := FontVariation.new()
	f.base_font = load("res://fonts/BigShouldersDisplay.ttf")
	f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): 600}
	print(ResourceSaver.save(f, "res://fonts/ui_default.tres"))
	quit()
