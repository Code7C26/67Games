extends Node
func _ready() -> void:
	var builder:RefCounted=load("res://tools/part5_builder.gd").new()
	var map:Node2D=load("res://splash/scenes/PatoSplash.tscn").instantiate()
	builder.apply(map)
	var scene:=PackedScene.new();assert(scene.pack(map)==OK);assert(ResourceSaver.save(scene,"res://splash/scenes/PatoSplash.tscn")==OK);map.free()
	builder.showcase();print("PART5_BUILD_OK: life layer, reusable actors, complete asset showcase");get_tree().quit()
