extends Node2D
## Estado del huésped. La posesión no reinicia ni acelera su recarga.
const Arte = preload("res://scripts/camaleon_arte.gd")
const Preferencias = preload("res://scripts/visual_preferences.gd")
var anfitrion: CharacterBody2D
var parametros: Resource = preload("res://resources/camaleon_config.tres")
var camuflado := false
var recarga_restante := 0.0
var mezcla_visual := 0.0
var direccion_visual := "Abajo"
var ultima_causa := ""

func _ready() -> void:
	# The alternate shader skin follows AnimatedSprite2D's actual render frame.
	anfitrion.animated_sprite.frame_changed.connect(_sincronizar_visual)
	anfitrion.animated_sprite.animation_changed.connect(_sincronizar_visual)

func _nivel(rama: Array) -> int:
	for i in range(rama.size() - 1, -1, -1):
		if anfitrion.tiene_mutacion(rama[i]): return i + 1
	return 0

func factor_deteccion() -> float:
	var nivel := _nivel(["pigmentacion_avanzada", "mimetismo", "cromatoforos"])
	var factor: float = parametros.factor_deteccion
	if nivel > 0 and not parametros.factores_pigmentacion.is_empty():
		factor = parametros.factores_pigmentacion[mini(nivel - 1, parametros.factores_pigmentacion.size() - 1)]
	return clampf(factor, 0.10, 1.0)

func recarga() -> float:
	# Desvanecimiento no beneficia los fallos ni reduce la recuperación general.
	return maxf(0.1, parametros.recuperacion)

func tiempo_desvanecimiento() -> float:
	var nivel := _nivel(["desvanecimiento", "retorno_sigiloso", "adaptacion_fugaz"])
	if nivel <= 0 or parametros.tiempos_desvanecimiento.is_empty(): return 0.0
	var segundos: float = parametros.tiempos_desvanecimiento[mini(nivel - 1, parametros.tiempos_desvanecimiento.size() - 1)]
	return maxf(maxf(0.1, parametros.recuperacion_minima), segundos)

func bono_ataque_sorpresa() -> float:
	var nivel := _nivel(["ataque_sorpresa", "emboscada_viral", "golpe_furtivo"])
	if nivel <= 0 or parametros.bonos_ataque_sorpresa.is_empty(): return 0.0
	return clampf(parametros.bonos_ataque_sorpresa[mini(nivel - 1, parametros.bonos_ataque_sorpresa.size() - 1)], 0.0, 0.90)

func preparar_intento(probabilidad_base: float) -> float:
	if not _partida_activa(): return probabilidad_base
	# Snapshot y consumo antes del azar: ni un fallo ni otra presa reutilizan el bono.
	var bono := bono_ataque_sorpresa() if camuflado else 0.0
	revelar("contagio")
	if bono <= 0.0: return probabilidad_base
	return clampf(probabilidad_base + bono, 0.0, clampf(parametros.probabilidad_maxima_ataque, 0.0, 0.90))

func registrar_contagio_exitoso() -> void:
	# El único llamador es la ruta normal, después de verificar una infección nueva.
	if not _partida_activa(): return
	var restante := tiempo_desvanecimiento()
	if restante <= 0.0: return
	recarga_restante = minf(recarga_restante, restante)
	queue_redraw()

func _valido() -> bool:
	return is_instance_valid(anfitrion) and anfitrion.is_inside_tree() and not anfitrion.is_queued_for_deletion() and anfitrion.is_infected and anfitrion.cepa == "camaleon"

func _partida_activa() -> bool:
	return _valido() and is_instance_valid(anfitrion.map_host) and anfitrion.map_host.has_method("simbionte_en_juego") and anfitrion.map_host.simbionte_en_juego()

func humano_demasiado_cerca() -> bool:
	if not _valido(): return false
	var radio: float = parametros.distancia_revelacion
	# Exact centres avoid a one-physics-frame overlap delay after movement/spawn.
	for otro in get_tree().get_nodes_in_group("bots"):
		if not is_instance_valid(otro) or otro == anfitrion or not otro.is_in_group("bots") or otro.is_infected: continue
		if otro.map_host != anfitrion.map_host: continue
		if anfitrion.global_position.distance_squared_to(otro.global_position) <= radio * radio: return true
	return false

func motivo_bloqueo() -> String:
	if not _partida_activa(): return "Partida detenida"
	if anfitrion.incubacion_contagio > 0.0: return "Incubación"
	if is_instance_valid(anfitrion.efecto_simbionte) and anfitrion.efecto_simbionte.es_valido(): return "Aura visible"
	if humano_demasiado_cerca(): return "Cerca de humano"
	if recarga_restante > 0.0: return "Recargando"
	return ""

func puede_camuflarse() -> bool:
	return not camuflado and motivo_bloqueo().is_empty()

func activar_manual() -> bool:
	if not _valido() or not anfitrion.controlado_por_jugador or not puede_camuflarse(): return false
	camuflado = true
	return true

func revelar(motivo: String = "acción") -> void:
	if not _partida_activa(): return
	# Estar cerca bloquea ocultarse, pero no borra la reducción ganada con un éxito.
	# Una acción nueva (incluido otro contagio fallido) sí reinicia la recuperación.
	if not camuflado and motivo == "proximidad": return
	camuflado = false
	recarga_restante = recarga()
	ultima_causa = motivo
	queue_redraw()

func actualizar(delta: float) -> void:
	if not _valido():
		cancelar()
		return
	if is_instance_valid(anfitrion.map_host) and anfitrion.map_host.estado_actual == anfitrion.map_host.EstadoJuego.FIN:
		cancelar()
		return
	if not _partida_activa(): return
	recarga_restante = maxf(0.0, recarga_restante - delta)
	if is_instance_valid(anfitrion.efecto_simbionte) and anfitrion.efecto_simbionte.es_valido():
		revelar("aura del Simbionte")
	elif humano_demasiado_cerca():
		revelar("proximidad")
	elif not anfitrion.controlado_por_jugador and puede_camuflarse():
		camuflado = true
	var destino := 1.0 if camuflado else 0.0
	mezcla_visual = destino if Preferencias.reduced_motion(self) else move_toward(mezcla_visual, destino, delta / maxf(0.05, parametros.transicion_visual))
	_sincronizar_visual()
	if anfitrion.controlado_por_jugador: queue_redraw()

func animar(direccion: Vector2) -> void:
	var caminando := direccion.length_squared() > 0.01
	if caminando:
		if absf(direccion.x) > absf(direccion.y): direccion_visual = "Derecha" if direccion.x > 0.0 else "Izquierda"
		else: direccion_visual = "Abajo" if direccion.y > 0.0 else "Arriba"
	var sprite: AnimatedSprite2D = anfitrion.animated_sprite
	if caminando:
		sprite.play(direccion_visual)
	else:
		sprite.animation = "idle_" + direccion_visual.to_lower()
		sprite.stop()
	_sincronizar_visual()

func _sincronizar_visual() -> void:
	if is_queued_for_deletion() or not _valido() or not is_instance_valid(anfitrion.material_borde_infeccion): return
	var sprite: AnimatedSprite2D = anfitrion.animated_sprite
	var cuadro := -1 if String(sprite.animation).begins_with("idle_") else sprite.frame
	anfitrion.material_borde_infeccion.set_shader_parameter("piel_camuflada", Arte.piel_camuflada(direccion_visual, cuadro))
	anfitrion.material_borde_infeccion.set_shader_parameter("camuflaje", mezcla_visual)

func cancelar() -> void:
	camuflado = false
	recarga_restante = 0.0
	mezcla_visual = 0.0
	if is_instance_valid(anfitrion) and is_instance_valid(anfitrion.material_borde_infeccion):
		anfitrion.material_borde_infeccion.set_shader_parameter("camuflaje", 0.0)
	queue_redraw()

func _draw() -> void:
	if not _valido() or not anfitrion.controlado_por_jugador: return
	var color: Color = anfitrion.color_infeccion
	var fraccion := 1.0 - clampf(recarga_restante / recarga(), 0.0, 1.0)
	draw_arc(Vector2(0, 17), 8.0, -PI, -PI + maxf(0.01, PI * fraccion), 16, color, 2.0, false)
