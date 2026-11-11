extends SceneTree
## Vista de revisión del arte articulado; no modifica la escena de partida.
var output := ""

func _initialize() -> void:
	run.call_deferred()

func shot(nombre: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	if root.use_hdr_2d:
		img.convert(Image.FORMAT_RGBA8)
		img.linear_to_srgb()
	var error := img.save_png(output.path_join(nombre + ".png"))
	if error != OK:
		push_error("Capture could not save " + nombre)
		quit(1)
		return
	print("CAPTURE ", nombre)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../work/jugabilidad-nov04/coloso").simplify_path()
	DirAccess.make_dir_recursive_absolute(output)
	root.get_node("PatogenOnboarding").requested_mode = "direct"
	var fondo := ColorRect.new()
	fondo.size = root.get_visible_rect().size
	fondo.color = Color("101b27")
	root.add_child(fondo)
	var evento: Node2D = load("res://scripts/evento_coloso_antiviral.gd").new()
	evento.activo_restante = 18.0
	root.add_child(evento)
	evento.set_physics_process(false)
	var actor: Node2D = load("res://scenes/coloso_antiviral.tscn").instantiate()
	actor.evento = evento
	actor.position = fondo.size * 0.5
	actor.scale = Vector2.ONE * 2.5
	root.add_child(actor)
	actor.velocity = Vector2(75, 0)
	actor._animar(0.10)
	actor.queue_redraw()
	await shot("01_marcha_izquierda")
	actor._animar(0.22)
	actor.queue_redraw()
	await shot("02_marcha_derecha")
	var receptor := Node2D.new()
	receptor.position = actor.position + Vector2(280, 90)
	root.add_child(receptor)
	actor.objetivo_visual = receptor
	actor.pulso_visual = 0.7
	actor.curaciones = 3
	actor.queue_redraw()
	await shot("03_curacion")
	receptor.queue_free()
	actor.queue_free()
	evento.queue_free()
	fondo.queue_free()
	await process_frame
	quit()
