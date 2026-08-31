class_name GroundingShadow
extends RefCounted

const SHADOW_COLOR := Color(0.025, 0.055, 0.04, 1.0)


static func draw(
	canvas: CanvasItem,
	contact_radii: Vector2,
	grounding_offset: Vector2 = Vector2(0.0, -1.0),
	strength: float = 1.0
) -> void:
	canvas.draw_colored_polygon(
		_shadow_polygon(
			grounding_offset + Vector2(0.0, 0.75),
			contact_radii * Vector2(1.12, 1.24)
		),
		_with_alpha(0.055 * strength)
	)
	canvas.draw_colored_polygon(
		_shadow_polygon(grounding_offset, contact_radii),
		_with_alpha(0.19 * strength)
	)
	canvas.draw_colored_polygon(
		_shadow_polygon(
			grounding_offset + Vector2(0.0, -0.5),
			contact_radii * Vector2(0.66, 0.40)
		),
		_with_alpha(0.27 * strength)
	)


static func _shadow_polygon(center: Vector2, radii: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		center + Vector2(-radii.x, -radii.y * 0.08),
		center + Vector2(-radii.x * 0.68, -radii.y * 0.68),
		center + Vector2(-radii.x * 0.24, -radii.y),
		center + Vector2(radii.x * 0.38, -radii.y),
		center + Vector2(radii.x, -radii.y * 0.08),
		center + Vector2(radii.x * 0.70, radii.y * 0.66),
		center + Vector2(radii.x * 0.26, radii.y),
		center + Vector2(-radii.x * 0.42, radii.y * 0.84),
	])


static func _with_alpha(alpha: float) -> Color:
	return Color(SHADOW_COLOR.r, SHADOW_COLOR.g, SHADOW_COLOR.b, alpha)
