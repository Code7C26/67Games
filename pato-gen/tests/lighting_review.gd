extends Node
## Bounded in-engine review for Godot MCP, using the real production maps.
func _ready() -> void:
	run.call_deferred()
func run() -> void:
	var tree := get_tree()
	get_window().size = Vector2i(1920,1080)
	for map_name in ["Shopping","Laboratorio","PatoSplash"]:
		tree.root.get_node("PatogenOnboarding").requested_mode = "direct"
		tree.root.get_node("PatogenOnboarding").profile.data.reduced_motion = false
		seed(20261028)
		var host = load("res://scenes/"+map_name+".tscn").instantiate()
		tree.root.add_child(host)
		tree.current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		if map_name=="Laboratorio": host.get_node("Environment").clock_time=23.7
		for i in 150: await tree.physics_frame
		print("MCP_LIGHTING_REVIEW ",map_name," bots=",tree.get_nodes_in_group("bots").size())
		if map_name!="PatoSplash":
			host.queue_free()
			for i in 3: await tree.process_frame
	print("MCP_LIGHTING_REVIEW_COMPLETE")
	# Keep the final view alive until the MCP reads output and explicitly stops it.
