extends PanelContainer
## One draggable row in the hangar inventory list.

const HangarDragPreview = preload("res://scripts/hangar_drag_preview.gd")

var module_id: String = ""

func _get_drag_data(_pos: Vector2) -> Variant:
	if module_id.is_empty() or GameData.available_count(module_id) <= 0:
		return null
	set_drag_preview(HangarDragPreview.make(module_id))
	return {"type": "module", "module_id": module_id, "from_slot": -1}
