extends Button
## One interactive slot in the hangar grid.
## Supports drag (to move an installed module) and drop (from inventory or another slot).

const ModuleIcon = preload("res://scripts/module_icon.gd")

const DRAG_PREVIEW_SIZE := Vector2(54.0, 54.0)
const DRAG_PREVIEW_OPACITY: float = 0.72
const DRAG_ICON_INSET: float = 5.0

var slot_index: int    = 0
var module_id:  String = ""   # "" = empty slot
var refresh_cb: Callable      # hangar.gd passes _refresh here

func _get_drag_data(_pos: Vector2) -> Variant:
	if module_id.is_empty():
		return null
	set_drag_preview(_make_drag_preview(module_id))
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

func _make_drag_preview(mid: String) -> Control:
	var mdata: Dictionary = GameData.MODULE_DATA.get(mid, {})
	var cat: String = mdata.get("category", "")
	var cc: Color = GameData.CAT_COLORS.get(cat, Color.GRAY)

	var preview := Control.new()
	preview.custom_minimum_size = DRAG_PREVIEW_SIZE
	preview.size = DRAG_PREVIEW_SIZE
	preview.position = -DRAG_PREVIEW_SIZE * 0.5
	preview.modulate = Color(1.0, 1.0, 1.0, DRAG_PREVIEW_OPACITY)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(cc.r * 0.16, cc.g * 0.16, cc.b * 0.16, 0.86)
	style.border_color = Color(cc.r, cc.g, cc.b, 0.90)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.set_corner_radius_all(6)

	var panel := PanelContainer.new()
	panel.size = DRAG_PREVIEW_SIZE
	panel.add_theme_stylebox_override("panel", style)
	preview.add_child(panel)

	var icon: Control = ModuleIcon.new()
	icon.set("module_id", mid)
	icon.set("icon_scale", 2.25)
	icon.position = Vector2(DRAG_ICON_INSET, DRAG_ICON_INSET)
	icon.size = DRAG_PREVIEW_SIZE - Vector2(DRAG_ICON_INSET * 2.0, DRAG_ICON_INSET * 2.0)
	preview.add_child(icon)
	return preview
