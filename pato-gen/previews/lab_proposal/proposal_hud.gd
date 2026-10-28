extends "res://scripts/match_hud.gd"
## A console frame surrounds the sample; the map remains unobstructed.
var console_frame: Control
const Frame = preload("res://previews/lab_proposal/console_frame.gd")

func _ready() -> void:
	console_frame=Frame.new()
	console_frame.name="PreviewConsoleFrame"
	console_frame.mouse_filter=Control.MOUSE_FILTER_IGNORE
	console_frame.z_index=-20
	add_child(console_frame)
	super._ready()

func _layout() -> void:
	super._layout()
	if is_instance_valid(console_frame):
		console_frame.size=get_viewport().get_visible_rect().size/ui_scale
		console_frame.aperture=Rect2(map_screen_rect.position/ui_scale,map_screen_rect.size/ui_scale)
		console_frame.queue_redraw()
