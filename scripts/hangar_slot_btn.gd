extends Button
## One interactive slot in the hangar grid.
## Supports drag (to move an installed module) and drop (from inventory or another slot).

const HangarDragPreview = preload("res://scripts/hangar_drag_preview.gd")

var slot_index: int    = 0
var module_id:  String = ""   # "" = empty slot
var refresh_cb: Callable      # hangar.gd passes _refresh here
var _drag_highlighted: bool = false

func _ready() -> void:
	mouse_exited.connect(_clear_drag_highlight)
	set_process(false)

func _process(_delta: float) -> void:
	if not _drag_highlighted:
		return
	var pointer_inside := Rect2(Vector2.ZERO, size).has_point(get_local_mouse_position())
	if not pointer_inside or not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_set_drag_highlight(false)

func _draw() -> void:
	if not _drag_highlighted:
		return
	var rect := Rect2(Vector2(1.0, 1.0), size - Vector2(2.0, 2.0))
	draw_rect(rect, Color(0.30, 0.75, 1.00, 0.32), true)
	draw_rect(rect, Color(0.30, 0.85, 1.00, 0.95), false, 2.0)

func _get_drag_data(_pos: Vector2) -> Variant:
	if module_id.is_empty():
		return null
	set_drag_preview(HangarDragPreview.make(module_id))
	return {"type": "slot_module", "module_id": module_id, "from_slot": slot_index}

func _can_drop_data(_pos: Vector2, data: Variant) -> bool:
	if not (data is Dictionary):
		_set_drag_highlight(false)
		return false
	var can_drop: bool = data.get("type", "") in ["module", "slot_module"]
	_set_drag_highlight(can_drop)
	return can_drop

func _drop_data(_pos: Vector2, data: Variant) -> void:
	_set_drag_highlight(false)
	var src_mid: String = data.get("module_id", "")
	var from_slot: int  = data.get("from_slot", -1)
	if from_slot == -1:
		# From inventory list -> place at this slot (unequips any occupant)
		GameData.equip_module_at(src_mid, slot_index)
	else:
		# From another slot -> swap/move
		GameData.move_module(from_slot, slot_index)
	if refresh_cb.is_valid():
		refresh_cb.call()

func _clear_drag_highlight() -> void:
	_set_drag_highlight(false)

func _set_drag_highlight(value: bool) -> void:
	if _drag_highlighted == value:
		return
	_drag_highlighted = value
	set_process(value)
	queue_redraw()
