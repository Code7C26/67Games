extends Node2D
## Visual API: 0 healthy, 1 P1/cyan, 2 P2/magenta. No gameplay ownership changes.
@export_enum("Sano", "P1", "P2") var infection_owner: int = 0:
	set(value):
		infection_owner = clampi(value,0,2)
		if is_node_ready(): _update_infection()
var outline: ShaderMaterial
func _ready() -> void:
	var sprite := $AnimatedSprite2D as AnimatedSprite2D
	outline = ShaderMaterial.new()
	outline.shader = preload("res://lab/shaders/npc_outline.gdshader")
	sprite.material = outline
	sprite.light_mask = 0
	var shadow := Polygon2D.new()
	shadow.name = "SombraContacto"
	var points := PackedVector2Array()
	for i in range(20):
		var a := TAU*i/20.0
		points.append(Vector2(round(cos(a)*10.0),round(sin(a)*3.0)+13.0))
	shadow.polygon = points
	shadow.color = Color(0.025,0.04,0.065,0.38)
	shadow.show_behind_parent = true
	var unlit := CanvasItemMaterial.new()
	unlit.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	shadow.material = unlit
	add_child(shadow)
	move_child(shadow,0)
	_update_infection()
func _update_infection() -> void:
	outline.set_shader_parameter("outline_color",[Color("0a0f1a"),Color("44e1ed"),Color("ee70d8")][infection_owner])
	outline.set_shader_parameter("infected",infection_owner != 0)
func set_infection_owner(owner_id: int) -> void:
	infection_owner = owner_id
