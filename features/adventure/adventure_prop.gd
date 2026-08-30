class_name AdventureProp
extends StaticBody2D

enum Kind {
	TREE,
	HOUSE,
	SIGN,
	NPC,
	ROCK,
	LANTERN,
}

@export var kind: Kind = Kind.TREE
@export var interaction_title: String = ""
@export_multiline var interaction_text: String = ""


func configure(prop_kind: Kind, title: String = "", text: String = "") -> void:
	kind = prop_kind
	interaction_title = title
	interaction_text = text


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	if not interaction_text.is_empty():
		add_to_group(&"interactable")
	_add_collision()
	queue_redraw()


func get_interaction() -> Dictionary:
	return {"title": interaction_title, "text": interaction_text}


func get_prompt() -> String:
	if kind == Kind.NPC:
		return "Talk"
	if kind == Kind.SIGN:
		return "Read"
	return "Inspect"


func _add_collision() -> void:
	var collision := CollisionShape2D.new()
	var shape: Shape2D
	match kind:
		Kind.HOUSE:
			var rectangle := RectangleShape2D.new()
			rectangle.size = Vector2(330.0, 105.0)
			shape = rectangle
			collision.position = Vector2(0.0, -38.0)
		Kind.TREE:
			var circle := CircleShape2D.new()
			circle.radius = 25.0
			shape = circle
			collision.position = Vector2(0.0, -8.0)
		Kind.ROCK:
			var circle := CircleShape2D.new()
			circle.radius = 24.0
			shape = circle
			collision.position = Vector2(0.0, -5.0)
		_:
			var circle := CircleShape2D.new()
			circle.radius = 14.0
			shape = circle
			collision.position = Vector2(0.0, -5.0)
	collision.shape = shape
	add_child(collision)


func _draw() -> void:
	match kind:
		Kind.HOUSE:
			_draw_house()
		Kind.SIGN:
			_draw_sign()
		Kind.NPC:
			_draw_npc()
		Kind.ROCK:
			_draw_rock()
		Kind.LANTERN:
			_draw_lantern()
		_:
			_draw_tree()


func _draw_tree() -> void:
	draw_ellipse(Vector2(0.0, 5.0), Vector2(42.0, 15.0), Color(0.05, 0.09, 0.05, 0.3))
	draw_rect(Rect2(-15.0, -104.0, 30.0, 105.0), Color("6f4e34"))
	draw_circle(Vector2(-25.0, -115.0), 55.0, Color("3f7546"))
	draw_circle(Vector2(31.0, -126.0), 62.0, Color("4e8950"))
	draw_circle(Vector2(0.0, -164.0), 65.0, Color("578f54"))
	draw_circle(Vector2(-5.0, -150.0), 28.0, Color("68a35c"))


func _draw_house() -> void:
	draw_ellipse(Vector2(0.0, 8.0), Vector2(205.0, 35.0), Color(0.05, 0.08, 0.05, 0.28))
	draw_rect(Rect2(-165.0, -205.0, 330.0, 178.0), Color("e1c58f"))
	draw_polygon(PackedVector2Array([Vector2(-195.0, -200.0), Vector2(0.0, -318.0), Vector2(195.0, -200.0)]), PackedColorArray([Color("a54f35")]))
	draw_polygon(PackedVector2Array([Vector2(-174.0, -198.0), Vector2(0.0, -292.0), Vector2(174.0, -198.0)]), PackedColorArray([Color("c9693d")]))
	draw_rect(Rect2(-38.0, -117.0, 76.0, 91.0), Color("6b4935"))
	draw_circle(Vector2(20.0, -70.0), 5.0, Color("f4d15f"))
	draw_rect(Rect2(-125.0, -158.0, 58.0, 48.0), Color("72a5a5"))
	draw_rect(Rect2(68.0, -158.0, 58.0, 48.0), Color("72a5a5"))
	draw_line(Vector2(-96.0, -158.0), Vector2(-96.0, -110.0), Color("f0e0b7"), 5.0)
	draw_line(Vector2(97.0, -158.0), Vector2(97.0, -110.0), Color("f0e0b7"), 5.0)


func _draw_sign() -> void:
	draw_ellipse(Vector2(0.0, 5.0), Vector2(26.0, 9.0), Color(0.05, 0.08, 0.05, 0.28))
	draw_rect(Rect2(-6.0, -66.0, 12.0, 70.0), Color("68472f"))
	draw_polygon(PackedVector2Array([Vector2(-42.0, -86.0), Vector2(36.0, -86.0), Vector2(49.0, -65.0), Vector2(36.0, -44.0), Vector2(-42.0, -44.0)]), PackedColorArray([Color("c69550")]))
	draw_line(Vector2(-28.0, -69.0), Vector2(25.0, -69.0), Color("6a4931"), 5.0)


func _draw_npc() -> void:
	draw_ellipse(Vector2(0.0, 5.0), Vector2(24.0, 9.0), Color(0.05, 0.08, 0.05, 0.28))
	draw_line(Vector2(-8.0, -8.0), Vector2(-10.0, 11.0), Color("3f372f"), 8.0, true)
	draw_line(Vector2(8.0, -8.0), Vector2(10.0, 11.0), Color("3f372f"), 8.0, true)
	draw_polygon(PackedVector2Array([Vector2(-23.0, -57.0), Vector2(23.0, -57.0), Vector2(18.0, -8.0), Vector2(-18.0, -8.0)]), PackedColorArray([Color("386d63")]))
	draw_circle(Vector2(0.0, -76.0), 20.0, Color("cf9168"))
	draw_arc(Vector2(0.0, -80.0), 19.0, PI, TAU, 18, Color("d9d2bd"), 9.0, true)
	draw_circle(Vector2(-7.0, -75.0), 2.2, Color("25302d"))
	draw_circle(Vector2(7.0, -75.0), 2.2, Color("25302d"))


func _draw_rock() -> void:
	draw_ellipse(Vector2(0.0, 5.0), Vector2(35.0, 11.0), Color(0.05, 0.08, 0.05, 0.25))
	draw_polygon(PackedVector2Array([Vector2(-35.0, 0.0), Vector2(-25.0, -39.0), Vector2(9.0, -54.0), Vector2(38.0, -19.0), Vector2(30.0, 2.0)]), PackedColorArray([Color("758178")]))
	draw_line(Vector2(-20.0, -32.0), Vector2(8.0, -45.0), Color("9ca89c"), 5.0, true)


func _draw_lantern() -> void:
	draw_ellipse(Vector2(0.0, 5.0), Vector2(18.0, 7.0), Color(0.05, 0.08, 0.05, 0.25))
	draw_rect(Rect2(-5.0, -104.0, 10.0, 108.0), Color("40362e"))
	draw_circle(Vector2(0.0, -111.0), 23.0, Color(1.0, 0.74, 0.28, 0.18))
	draw_rect(Rect2(-11.0, -126.0, 22.0, 30.0), Color("f1bd4f"))
	draw_line(Vector2(-12.0, -126.0), Vector2(12.0, -126.0), Color("40362e"), 5.0)


func draw_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for index: int in range(24):
		var angle: float = TAU * float(index) / 24.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
