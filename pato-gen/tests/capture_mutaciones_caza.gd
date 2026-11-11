extends "res://tests/test_garfio_mutaciones.gd"
## Capturas renderizadas de las habilidades reales, sin alterar sprites.
var output := "res://../work/garfio-rastreador-mutaciones-nov07/capturas"

func shot(label: String) -> void:
	for _i in 3: await process_frame
	await RenderingServer.frame_post_draw
	var picture := root.get_texture().get_image()
	if root.use_hdr_2d:
		picture.convert(Image.FORMAT_RGBA8)
		picture.linear_to_srgb()
	check(picture.save_png(output.path_join(label + ".png")) == OK, "rendered " + label)

func focus(point: Vector2) -> void:
	host.interfaz.visible = false
	for duck in get_nodes_in_group("patos"): duck.visible = false
	for cocoon in host.get_node("Simbiontes").get_children(): cocoon.visible = false
	var camera: Camera2D = host.get_node("Camera2D")
	camera.position_smoothing_enabled = false
	camera.global_position = point
	camera.zoom = Vector2(3.0, 3.0)
	camera.force_update_scroll()

func apply(bot: Node2D, names: Array, strain: String) -> void:
	var mutations: Array[String] = []
	mutations.assign(names)
	bot.aplicar_mutaciones(mutations, strain)
	bot.actualizar_sprite_segun_infeccion()
	bot.feedback_restante = 0.0
	bot.queue_redraw()

func run() -> void:
	output = ProjectSettings.globalize_path(output)
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await preparar()
	var origin := zona_doble()
	var source := actor(origin)
	apply(source, ["tendon_reforzado", "arrastre_brutal", "gancho_virulento"], "garfio")
	var prey := actor(origin + Vector2(100, -60), 0)
	var other := actor(origin + Vector2(100, 60), 0)
	await physics_frame
	focus(origin + Vector2(50, 0))
	check(source.garfio.intentar_enganche(prey), "capture launches")
	source.garfio.actualizar(0.35)
	source.garfio.actualizar(0.18)
	source.actualizar_animacion(Vector2.ZERO)
	check(is_instance_valid(other.captor_garfio), "independent second appendage")
	await shot("01_doble_tendon")
	# Complete a physical single pull and deliberately select a failing random roll.
	source.garfio.cancelar()
	other.queue_free()
	await physics_frame
	apply(source, ["tendon_reforzado", "gancho_virulento"], "garfio")
	ready_again(source.garfio)
	prey.global_position = origin + Vector2(110, 0)
	source.probabilidad_contagio = 0.0
	await physics_frame
	check(hook(source.garfio, prey), "physical pull reaches prey")
	var chosen := 1
	for candidate in 100:
		seed(candidate)
		if randf() > 0.9:
			chosen = candidate
			break
	seed(chosen)
	source.garfio.arrastrar_objetivo(prey, 0.65)
	check(prey.has_node("PresaVulnerable"), "arrival adds visible vulnerability")
	if prey.has_node("PresaVulnerable"): prey.get_node("PresaVulnerable").set_physics_process(false)
	await shot("02_presa_vulnerable")
	ready_again(source.garfio)
	source.garfio.cadencia_restante = 0.0
	source.espera_contacto_garfio = 0.0
	source.probabilidad_contagio = 0.95
	prey.global_position = origin + Vector2(110, 0)
	await physics_frame
	check(hook(source.garfio, prey), "fresh physical pull for rehook")
	seed(semilla_entre(0.0, 0.1))
	source.garfio.arrastrar_objetivo(prey, 0.65)
	check(prey.is_infected and source.garfio.reenganche_restante > 0.0, "successful capture emits rehook signal")
	await shot("05_reenganche")
	await limpiar()
	var nav: Node2D = host.navegacion_simbionte
	var previous_radius: float = nav.circulo.radius
	nav.circulo.radius = 19.0
	for point in nav.posiciones_transitables(ORIGIN, 24.0):
		var clear := true
		for offset in [Vector2(-48, 0), Vector2(-36, -55), Vector2(-36, 55), Vector2(80, 0)]:
			if not nav.segmento_libre(point, point + offset): clear = false; break
		if clear:
			origin = point
			break
	nav.circulo.radius = previous_radius
	source = actor(origin, 2)
	apply(source, ["olfato_reforzado", "fijacion_presa", "instinto_manada"], "rastreador")
	prey = actor(origin + Vector2(80, 0), 0)
	for offset in [Vector2(-48, 0), Vector2(-36, -55), Vector2(-36, 55)]:
		var ally := actor(origin + offset, 2)
		apply(ally, [], "atletico")
	while not source.rastreador.navegacion.lista: await physics_frame
	source.rastreador.revision_restante = 0.0
	source.rastreador.actualizar(0.01)
	check(source.rastreador.miembros.size() == 3, "visible call recruits three allies")
	focus(origin + Vector2(25, 0))
	await shot("03_llamado_manada_compartido")
	# Production is a shared screen; this isolated view explicitly selects the owner.
	host.set_meta("equipo_visible", 2)
	source.rastreador.actualizar(0.01)
	await shot("04_marca_vista_equipo")
	print("HUNT CAPTURE RESULT ", passed, " passed; ", failures, " failed")
	host.queue_free()
	await process_frame
	await process_frame
	READABILITY.textures.clear()
	load("res://scripts/Bot.gd").frames_infectados_cache.clear()
	load("res://scripts/rastreador_arte.gd").limpiar_cache()
	root.get_node("AudioManager").detener_musica()
	quit(0 if failures == 0 else 1)
