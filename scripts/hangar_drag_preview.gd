class_name HangarDragPreview extends RefCounted

const DragPreviewIcon = preload("res://scripts/hangar_drag_preview_icon.gd")

const PREVIEW_SIZE := Vector2(54.0, 54.0)
const PREVIEW_OPACITY: float = 0.72

static func make(module_id: String) -> Control:
	var mdata: Dictionary = GameData.MODULE_DATA.get(module_id, {})
	var cat: String = mdata.get("category", "")
	var cc: Color = GameData.CAT_COLORS.get(cat, Color.GRAY)
	var offset := -PREVIEW_SIZE * 0.5

	var preview := Control.new()
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	preview.custom_minimum_size = Vector2.ZERO
	preview.size = Vector2.ZERO
	preview.modulate = Color(1.0, 1.0, 1.0, PREVIEW_OPACITY)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(cc.r * 0.16, cc.g * 0.16, cc.b * 0.16, 0.86)
	style.border_color = Color(cc.r, cc.g, cc.b, 0.90)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.set_corner_radius_all(6)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.position = offset
	panel.custom_minimum_size = PREVIEW_SIZE
	panel.size = PREVIEW_SIZE
	panel.add_theme_stylebox_override("panel", style)
	preview.add_child(panel)

	var icon: Control = DragPreviewIcon.new()
	icon.set("module_id", module_id)
	icon.position = offset
	icon.custom_minimum_size = PREVIEW_SIZE
	icon.size = PREVIEW_SIZE
	preview.add_child(icon)
	return preview
