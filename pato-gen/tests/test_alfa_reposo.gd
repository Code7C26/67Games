extends "res://tests/test_parasito_alfa.gd"
## Rest is visual only: the approved release poses still own every real birth.

func run() -> void:
	var boot := root.get_node("PatogenOnboarding")
	var previous_reduced: bool = boot.profile.data.reduced_motion
	boot.profile.data.reduced_motion = false
	await preparar()
	await aparecer()
	var actor: Node2D = alfa_evento.alfa
	var artwork: Sprite2D = actor.aspecto
	var original_transform: Transform2D = actor.global_transform
	var artwork_transform: Transform2D = artwork.transform
	var material: ShaderMaterial = artwork.material
	check(material != null and material.shader.resource_path == "res://shaders/alfa_reposo.gdshader", "the real Alfa owns the continuous-rest material")
	check(artwork.frame == 3 and material.get_shader_parameter("fotograma") == 3 and material.get_shader_parameter("intensidad_reposo") == 0.0, "the initial birth opens its actual release frame with rest deformation disabled")
	alfa_evento.avanzar(0.7)
	check(actor.tiempo_animacion < 0.0 and artwork.frame == 0 and material.get_shader_parameter("intensidad_reposo") == 1.0, "release recovery enables continuous visible rest on the approved resting frame")
	var before: float = material.get_shader_parameter("tiempo_reposo")
	for i in 20: alfa_evento.avanzar(0.2)
	check(float(material.get_shader_parameter("tiempo_reposo")) > before + 3.9, "continuous rest advances between births instead of holding a static picture")
	check(alfa_evento.generados == 3 and host.contar_infecciones().total == 3, "four seconds of breathing create no demonstration or extra gameplay bots")
	check(actor.global_transform == original_transform and artwork.transform == artwork_transform, "breathing does not move the anchored organism, scale or roots")
	var phase: float = material.get_shader_parameter("tiempo_reposo")
	var active: float = alfa_evento.tiempo_activo
	host.timer_juego.paused = true
	alfa_evento.avanzar(2.0)
	check(material.get_shader_parameter("tiempo_reposo") == phase and alfa_evento.tiempo_activo == active, "tutorial clock hold freezes rest and generation together")
	host.timer_juego.paused = false
	paused = true
	alfa_evento.avanzar(2.0)
	check(material.get_shader_parameter("tiempo_reposo") == phase and alfa_evento.tiempo_activo == active, "global pause also freezes continuous rest during direct scheduler calls")
	paused = false
	boot.profile.data.reduced_motion = true
	alfa_evento.avanzar(0.2)
	check(material.get_shader_parameter("intensidad_reposo") == 0.0 and artwork.frame == 0, "reduced motion removes idle deformation while retaining the actual resting artwork")
	boot.profile.data.reduced_motion = false
	alfa_evento.avanzar(0.2)
	check(material.get_shader_parameter("intensidad_reposo") == 1.0, "the live reduced-motion preference resumes the visible breathing")
	check(not material.shader.code.contains("TIME"), "the material uses the held gameplay clock rather than an independent shader clock")
	alfa_evento.avanzar(9.66 - alfa_evento.tiempo_activo)
	check(artwork.frame == 1 and material.get_shader_parameter("intensidad_reposo") == 0.0 and alfa_evento.generados == 3, "the exact anticipation tick suppresses rest without creating an early guest")
	alfa_evento.avanzar(0.34)
	check(artwork.frame == 3 and material.get_shader_parameter("fotograma") == 3 and alfa_evento.generados == 4 and host.contar_infecciones().total == 4, "the next real birth and open torso remain synchronized at ten seconds")
	alfa_evento.avanzar(0.7)
	check(actor.tiempo_animacion < 0.0 and material.get_shader_parameter("intensidad_reposo") == 1.0, "the second release recovers back to continuous rest")
	check(host.adn_cian == 0 and host.adn_magenta == 0 and actor.global_transform == original_transform, "idle animation awards no ADN and leaves the rooted position unchanged")
	boot.profile.data.reduced_motion = previous_reduced
	host.queue_free()
	await process_frame
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await create_timer(0.15).timeout
	print("ALFA REST RESULT ", passed, " passed; ", failures, " failed")
	quit(0 if failures == 0 else 1)
