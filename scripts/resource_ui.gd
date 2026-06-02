extends RefCounted

const METAL := "metal"
const CRYSTAL := "crystal"
const METAL_TEXTURE: Texture2D = preload("res://assets/pickups/pickup_metal.png")
const CRYSTAL_TEXTURE: Texture2D = preload("res://assets/pickups/pickup_crystal.png")
const METAL_COLOR := Color(0.90, 0.92, 0.96)
const CRYSTAL_COLOR := Color(0.25, 0.92, 1.00)

static func get_texture(resource_id: String) -> Texture2D:
	match resource_id:
		METAL:
			return METAL_TEXTURE
		CRYSTAL:
			return CRYSTAL_TEXTURE
		_:
			return null

static func get_color(resource_id: String) -> Color:
	return CRYSTAL_COLOR if resource_id == CRYSTAL else METAL_COLOR

static func make_icon(resource_id: String, size: int = 24) -> TextureRect:
	var icon := TextureRect.new()
	icon.texture = get_texture(resource_id)
	icon.custom_minimum_size = Vector2(size, size)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon

static func make_amount_label(text: String, resource_id: String, font_size: int = 17) -> Label:
	var label := Label.new()
	label.text = text
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", get_color(resource_id))
	return label

static func make_amount_row(
		resource_id: String,
		text: String,
		font_size: int = 17,
		icon_size: int = 24,
		separation: int = 5) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", separation)
	row.add_child(make_icon(resource_id, icon_size))
	row.add_child(make_amount_label(text, resource_id, font_size))
	return row

static func make_counter(
		resource_id: String,
		amount: int,
		font_size: int = 17,
		icon_size: int = 24,
		separation: int = 5) -> Dictionary:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", separation)
	row.add_child(make_icon(resource_id, icon_size))

	var label := make_amount_label("%d" % amount, resource_id, font_size)
	row.add_child(label)
	return {"row": row, "label": label}

static func apply_button_icon(button: Button, resource_id: String) -> void:
	button.icon = get_texture(resource_id)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
