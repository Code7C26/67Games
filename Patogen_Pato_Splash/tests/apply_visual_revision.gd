extends Node
func _ready() -> void:
	var packed: PackedScene = load("res://splash/scenes/PatoSplash.tscn")
	var map_root: Node2D = packed.instantiate()
	load("res://tools/visual_revision.gd").new().apply(map_root)
	assert(packed.pack(map_root) == OK)
	assert(ResourceSaver.save(packed, "res://splash/scenes/PatoSplash.tscn") == OK)
	map_root.free()
	print("VISUAL_REVISION_APPLIED: supplied Press Start 2P on all map labels")
	get_tree().quit()
