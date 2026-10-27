extends Node
func _ready() -> void:
	call_deferred("build")
func build() -> void:
	var packed: PackedScene = load("res://splash/scenes/PatoSplash.tscn")
	var map_root: Node2D = packed.instantiate()
	load("res://tools/part3_builder.gd").new().apply(map_root)
	assert(packed.pack(map_root) == OK)
	assert(ResourceSaver.save(packed, "res://splash/scenes/PatoSplash.tscn") == OK)
	map_root.free()
	print("PART3_APPLIED: ambient controller, four clipped water overlays, clouds, bubbles and illuminated sign")
	get_tree().quit()
