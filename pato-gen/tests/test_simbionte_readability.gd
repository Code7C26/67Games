extends "res://tests/test_simbionte.gd"
## The larger presentation must not enlarge physical contact, the host or its economy.
const TEAMS = preload("res://scripts/equipos_infeccion.gd")
const ORIGINAL_FUSED_SHADER = preload("res://shaders/simbionte.gdshader")

func run() -> void:
	for team in [1, 2]:
		await fresh()
		var prefix := "blue " if team == 1 else "magenta "
		var eggs: Array[Node2D] = [host.capullos[0], host.capullos[1]]
		var egg_transforms: Array[Transform2D] = []
		var egg_offsets: Array[Vector2] = []
		for egg in eggs:
			egg_transforms.append(egg.aspecto.global_transform)
			egg_offsets.append(egg.aspecto.offset)
			check(egg.scale == Vector2.ONE and egg.aspecto.scale == Vector2(1.5, 1.5), prefix + "egg enlarges only its painted body")
			check(egg.aspecto.offset == Vector2(0, -5), prefix + "egg enlargement preserves its ground anchor")
			check(egg.find_children("*", "CollisionObject2D", true, false).is_empty(), prefix + "egg presentation adds no blocking body")
			check(egg.aspecto.sprite_frames.get_meta("outline_padding", false), prefix + "egg outline has transparent space around its frames")
		check(eggs[0].aspecto.material != eggs[1].aspecto.material, prefix + "both egg teams retain independent materials")
		host.adn_cian = 60
		host.adn_magenta = 60
		var hatch_point: Vector2 = eggs[team - 1].global_position
		var accepted := 0
		for payment in 12:
			if host.invertir_simbionte(team): accepted += 1
			if payment == 0:
				check(host.obtener_adn(team) == 55 and host.inversion_simbionte[team - 1] == 5, prefix + "larger egg still charges exactly five ADN per investment")
				check(not host.invertir_simbionte(team) and host.obtener_adn(team) == 55 and is_equal_approx(host.cooldown_simbionte[team - 1], 1.5), prefix + "egg feedback cannot bypass its existing investment cooldown")
			host._physics_process(host.COOLDOWN_SIMBIONTE)
		check(accepted == 12 and host.obtener_adn(team) == 0 and host.obtener_adn(3 - team) == 60 and host.ganador_simbionte == team, prefix + "the real hatch still costs sixty ADN and preserves the rival balance")
		var traveler = host.simbionte
		traveler.set_physics_process(false)
		check(traveler.global_position == hatch_point, prefix + "larger traveler hatches at the actual egg location")
		check(traveler.scale == Vector2.ONE and traveler.aspecto.scale == Vector2(1.5, 1.5), prefix + "only the free traveler artwork becomes larger")
		check(traveler.aspecto.offset == Vector2(0, -5), prefix + "traveler feet retain the original ground anchor")
		check(traveler.get_node("CollisionShape2D").shape.radius == 8.0 and traveler.get_node("Contacto/CollisionShape2D").shape.radius == 10.0 and traveler.contacto.scale == Vector2.ONE, prefix + "larger traveler keeps its eight-pixel body and ten-pixel fusion contact")
		check(traveler.velocidad == 100.0 and traveler.collision_mask == 1, prefix + "traveler speed and wall collisions remain intact")
		check(traveler.aspecto.sprite_frames.get_meta("outline_padding", false) and traveler.aspecto.material.shader != ORIGINAL_FUSED_SHADER, prefix + "free traveler has its own padded outline material")
		var remnants := get_nodes_in_group("restos_capullo")
		check(remnants.size() == 2, prefix + "both original egg endings remain present")
		var endings_match := remnants.size() == 2
		for index in remnants.size():
			endings_match = endings_match and remnants[index].global_transform.is_equal_approx(egg_transforms[index]) and remnants[index].offset == egg_offsets[index]
		check(endings_match, prefix + "hatching and withering preserve the larger egg transform and offset")
		var target := bot_at(Vector2(816, 568), team)
		var previous_scale: Vector2 = target.animated_sprite.scale
		var previous_position: Vector2 = target.animated_sprite.position
		var economy_before := [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta]
		traveler.objetivo = target
		traveler.global_position = target.global_position + Vector2(55, 0)
		await physics_frame
		await physics_frame
		check(not traveler.intentar_fusion() and target.efecto_simbionte == null, prefix + "the larger silhouette cannot fuse from outside physical contact")
		traveler.global_position = target.global_position
		await physics_frame
		await physics_frame
		check(traveler.intentar_fusion() and not traveler.intentar_fusion(), prefix + "real overlap still commits fusion exactly once")
		var effect = target.efecto_simbionte
		effect.set_physics_process(false)
		check(effect.aspecto.scale == previous_scale and effect.aspecto.position == previous_position and target.animated_sprite.scale == previous_scale, prefix + "fusion preserves the existing host scale and position")
		check(effect.aspecto.material.shader == ORIGINAL_FUSED_SHADER and not effect.aspecto.sprite_frames.get_meta("outline_padding", false), prefix + "fused artwork keeps the original shader and frames")
		check(effect.restante == 20.0 and effect.radio_aura == 140.0 and effect.chance_aura == 0.5 and effect.factor_velocidad == 1.35, prefix + "fusion duration and gameplay bonuses remain intact")
		check(economy_before == [host.adn_cian, host.adn_magenta, host.contagios_cian, host.contagios_magenta], prefix + "larger travel and fusion neither award nor spend extra ADN")
		effect.avanzar(20.0)
		check(target.efecto_simbionte == null and target.animated_sprite.visible and target.animated_sprite.scale == previous_scale, prefix + "fusion expiry restores the same original host artwork")
	print("SIMBIONTE READABILITY RESULT ", passed, " passed; ", failures, " failed")
	if is_instance_valid(host): host.queue_free()
	await process_frame
	await process_frame
	for player in root.get_node("AudioManager").get_children():
		if player is AudioStreamPlayer: player.stop()
	await create_timer(0.15).timeout
	quit(0 if failures == 0 else 1)
