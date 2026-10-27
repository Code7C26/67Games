extends Node
func _ready() -> void:
	call_deferred("build")
func build() -> void:
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://tools/layout.json"))
	var packed: PackedScene=load("res://splash/scenes/PatoSplash.tscn");var map: Node2D=packed.instantiate()
	load("res://tools/part2_builder.gd").new().apply(map,data)
	assert(packed.pack(map)==OK);assert(ResourceSaver.save(packed,"res://splash/scenes/PatoSplash.tscn")==OK);map.free()
	print("PART2_APPLIED: paths/terrain, planters, signs, park dressing and duck SpriteFrames")
	get_tree().quit()
