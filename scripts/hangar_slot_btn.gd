extends Button
## One interactive slot in the hangar grid.
## Supports drag (to move an installed module) and drop (from inventory or another slot).

var slot_index: int    = 0
var module_id:  String = ""   # "" = empty slot
var refresh_cb: Callable      # hangar.gd passes _refresh here

func _get_drag_data(_pos: Vector2) -> Variant:
	if module_id.is_empty():
		return null
	var mdata: Dictionary = GameData.MODULE_DATA.get(module_id, {})
	var cat: String = mdata.get("category", "")
	var preview := Label.new()
	preview.text = " %s " % mdata.get("name", module_id)
	preview.add_theme_font_size_override("font_size", 15)
	preview.add_theme_color_override("font_color", GameData.CAT_COLORS.get(cat, Color.WHITE))
	set_drag_preview(preview)
	return {"type": "slot_module", "module_id": module_id, "from_slot": slot_index}

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not (data is Dictionary):
		return false
	return data.get("type", "") in ["module", "slot_module"]

func _drop_data(_pos: Vector2, data: Variant) -> void:
	var src_mid: String = data.get("module_id", "")
	var from_slot: int  = data.get("from_slot", -1)
	if from_slot == -1:
		# From inventory list → place at this slot (unequips any occupant)
		GameData.equip_module_at(src_mid, slot_index)
	else:
		# From another slot → swap/move
		GameData.move_module(from_slot, slot_index)
	if refresh_cb.is_valid():
		refresh_cb.call()
