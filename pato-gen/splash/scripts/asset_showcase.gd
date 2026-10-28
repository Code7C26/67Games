extends Node2D
## The catalogue is packed as real editable nodes, not a runtime-only preview.
@export var content_height := 4000.0
var drag := false
var elapsed := 0.0
var page := -1
@onready var camera: Camera2D = $Camera2D
func _process(delta: float) -> void:
	elapsed+=delta
	var direction:=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	camera.position+=direction*600*delta/camera.zoom.x
	camera.position.y=clampf(camera.position.y,540,content_height-440)
	var cycle:=int(elapsed/4.0)
	if cycle!=page:
		page=cycle
		for item in $Catalogo.get_children():
			var visual:=item.get_node_or_null("Vista")
			if visual is AnimatedSprite2D:
				var animations:PackedStringArray=visual.sprite_frames.get_animation_names()
				visual.play(animations[cycle%animations.size()])
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index==MOUSE_BUTTON_MIDDLE:drag=event.pressed
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_DOWN:camera.position.y+=180/camera.zoom.x
		if event.pressed and event.button_index==MOUSE_BUTTON_WHEEL_UP:camera.position.y-=180/camera.zoom.x
	if event is InputEventMouseMotion and drag:camera.position-=event.relative/camera.zoom
	if event is InputEventKey and event.pressed:
		if event.physical_keycode==KEY_HOME:camera.position=Vector2(960,540);camera.zoom=Vector2.ONE
		if event.physical_keycode==KEY_MINUS:camera.zoom=Vector2.ONE*maxf(0.5,camera.zoom.x-0.25)
		if event.physical_keycode==KEY_EQUAL:camera.zoom=Vector2.ONE*minf(2,camera.zoom.x+0.25)
