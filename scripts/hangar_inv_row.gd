extends PanelContainer
## One draggable row in the hangar inventory list.

var module_id: String = ""

func _get_drag_data(_pos: Vector2) -> Variant:
	if module_id.is_empty() or GameData.available_count(module_id) <= 0:
		return null
	var mdata: Dictionary = GameData.MODULE_DATA.get(module_id, {})
	var cat: String = mdata.get("category", "")
	var preview := Label.new()
	preview.text = " %s " % mdata.get("name", module_id)
	preview.add_theme_font_size_override("font_size", 15)
	preview.add_theme_color_override("font_color", GameData.CAT_COLORS.get(cat, Color.WHITE))
	set_drag_preview(preview)
	return {"type": "module", "module_id": module_id, "from_slot": -1}
