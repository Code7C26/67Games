extends Node
func _ready() -> void:
	var packed: PackedScene = load("res://splash/scenes/PatoSplash.tscn")
	var map_root: Node2D = packed.instantiate()
	load("res://tools/part4_builder.gd").new().apply(map_root)
	assert(packed.pack(map_root) == OK)
	assert(ResourceSaver.save(packed,"res://splash/scenes/PatoSplash.tscn") == OK)
	map_root.free()
	print("PART4_BUILD_OK: CPU water cannon, landing area, editable exports and pixel art resources")
	get_tree().quit()
