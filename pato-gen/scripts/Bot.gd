extends CharacterBody2D

# PatoGen: cepas elegidas antes de la partida, evolución por rama.
# Se conservan posesión, evasión de obstáculos, temperatura y robots curadores.

@export var speed: float = 75.0
@export var skins: Array[SpriteFrames] = []

const CONTAGIO_BASE: float = 0.35
const CURACION_BASE: float = 0.01 # Probabilidad POR SEGUNDO

# ===== BALANCE DE EXPONENCIAL =====
const CONTAGIO_EXPONENCIAL_INICIAL: float = 0.28
const ADAPTACION_POR_INFECCION: float = 0.002
const ADAPTACION_MAXIMA: float = 0.06
const EVOLUCION_RAPIDA_POR_INFECCION: float = 0.004
const EVOLUCION_RAPIDA_MAXIMA: float = 0.12
const SUPERCEPA_BONO_CONTAGIO: float = 0.025
const SUPERCEPA_BONO_VELOCIDAD: float = 0.05
const INTERVALO_DIVISION: float = 28.0
const INTERVALO_REPLICACION: float = 23.0
const INTERVALO_BROTE: float = 20.0

# Las replicas no se reproducen: frena la multiplicacion en cascada.
var es_replica: bool = false

var velocidad_base: float = 75.0
var is_infected: bool = false
var color_infeccion: Color = Color.WHITE
var player_duenio: int = 0
var cepa: String = ""
var move_direction: Vector2 = Vector2.ZERO
var controlado_por_jugador: bool = false
var jugador_controlador: int = 0
var direccion_control_jugador: Vector2 = Vector2.ZERO
var direccion_movimiento_real: Vector2 = Vector2.ZERO
var direccion_evasion: Vector2 = Vector2.ZERO
var tiempo_evasion: float = 0.0
var tiempo_ultimo_obstaculo: float = 0.0
var tiempo_contacto_obstaculo: float = 0.0

var probabilidad_contagio: float = CONTAGIO_BASE
var multiplicador_velocidad_temp: float = 1.0
var multiplicador_contagio_temp: float = 1.0
var probabilidad_curacion: float = CURACION_BASE
var tiempo_escudo: float = 0.0
var mutaciones: Array[String] = []

# Variables de comportamiento (sin modificar los scripts auxiliares).
var tiempo_persiguiendo: float = 0.0
var tiempo_sin_infectar: float = 0.0
var en_rabia: bool = false
var bonus_contagio_temporal: float = 0.0
var tiempo_bonus_contagio: float = 0.0
var blindaje_restante: float = 0.0
var cooldown_inmortal: float = 0.0
var tiempo_sobrecarga: float = 0.0
var recarga_sobrecarga: float = 0.0
var pulsos_pendientes: int = 0
var espera_siguiente_pulso: float = 0.0
var tiempo_nube: float = 0.0
var tiempo_replicacion: float = 0.0

@onready var timer_direccion: Timer = $TimerCambioRumbo
@onready var area_infeccion: Area2D = $AreaInfeccion
@onready var area_vision: Area2D = $AreaVision
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Indicadores de posesión originales (independientes de AreaInfeccion).
var indicador_area_infeccion: Polygon2D = null
var indicador_aura_posesion: Polygon2D = null
var tween_indicador_posesion: Tween = null
const RADIO_INDICADOR_INFECCION: float = 68.88396
const RADIO_INDICADOR_AURA: float = 80.0
const SEGMENTOS_INDICADOR: int = 64

var timer_contagio: Timer
var timer_curacion: Timer


func _ready() -> void:
	crear_indicador_posesion()
	if skins.size() > 0 and animated_sprite:
		animated_sprite.sprite_frames = skins.pick_random()
	add_to_group("bots")
	velocidad_base = speed
	cambiar_direccion_aleatoria()
	if timer_direccion:
		timer_direccion.timeout.connect(_on_timer_timeout)
		timer_direccion.wait_time = randf_range(1.5, 3.0)
		timer_direccion.start()
	timer_contagio = Timer.new()
	timer_contagio.wait_time = 0.5
	timer_contagio.timeout.connect(_intentar_contagio_area)
	add_child(timer_contagio)
	timer_curacion = Timer.new()
	timer_curacion.wait_time = 1.0
	timer_curacion.timeout.connect(_intentar_curacion)
	add_child(timer_curacion)


func _physics_process(delta: float) -> void:
	tiempo_escudo = maxf(0.0, tiempo_escudo - delta)
	blindaje_restante = maxf(0.0, blindaje_restante - delta)
	cooldown_inmortal = maxf(0.0, cooldown_inmortal - delta)
	tiempo_evasion = maxf(0.0, tiempo_evasion - delta)
	tiempo_ultimo_obstaculo = maxf(0.0, tiempo_ultimo_obstaculo - delta)

	if tiempo_bonus_contagio > 0.0:
		tiempo_bonus_contagio -= delta
		if tiempo_bonus_contagio <= 0.0:
			bonus_contagio_temporal = 0.0

	if is_infected:
		tiempo_sin_infectar += delta
		en_rabia = tiene_mutacion("rabia") and tiempo_sin_infectar >= 8.0
		_actualizar_mutaciones_tiempo(delta)

	if not controlado_por_jugador:
		if tiempo_evasion <= 0.0 and area_vision:
			if is_infected:
				var presa: Node2D = obtener_humano_cercano()
				if presa == null and tiene_mutacion("mente_colmena"):
					presa = _objetivo_compartido()
				if presa:
					perseguir_a(presa.global_position)
					tiempo_persiguiendo += delta
				else:
					tiempo_persiguiendo = 0.0
			else:
				var amenaza: Node2D = obtener_amenaza_cercana()
				if amenaza:
					huir_de(amenaza.global_position)

	var mult: float = obtener_multiplicador_velocidad()
	if controlado_por_jugador:
		direccion_movimiento_real = direccion_control_jugador
	else:
		direccion_movimiento_real = move_direction
	velocity = direccion_movimiento_real * speed * multiplicador_velocidad_temp * mult
	move_and_slide()
	if get_slide_collision_count() > 0:
		reaccionar_a_obstaculo()
	else:
		tiempo_contacto_obstaculo = 0.0
	actualizar_animacion(direccion_movimiento_real)


func _actualizar_mutaciones_tiempo(delta: float) -> void:
	# Sobrecarga: impulso y, en sus evoluciones, pulsos infecciosos.
	if tiene_mutacion("sobrecarga"):
		recarga_sobrecarga += delta
		if recarga_sobrecarga >= 12.0:
			recarga_sobrecarga = 0.0
			tiempo_sobrecarga = 2.5
			if tiene_mutacion("pulso_viral"):
				_liberar_pulso()
			if tiene_mutacion("tormenta_infecciosa"):
				pulsos_pendientes = 2
				espera_siguiente_pulso = 0.75
	if tiempo_sobrecarga > 0.0:
		tiempo_sobrecarga = maxf(0.0, tiempo_sobrecarga - delta)
	if pulsos_pendientes > 0:
		espera_siguiente_pulso -= delta
		if espera_siguiente_pulso <= 0.0:
			_liberar_pulso()
			pulsos_pendientes -= 1
			espera_siguiente_pulso = 0.75

	# Epidemia: deja áreas visibles, temporales y limitadas por jugador.
	if tiene_mutacion("epidemia_ambiental"):
		tiempo_nube += delta
		if tiempo_nube >= 12.0:
			tiempo_nube = 0.0
			var mapa: Node = get_tree().current_scene
			if mapa and mapa.has_method("crear_nube_persistente"):
				mapa.crear_nube_persistente(global_position, player_duenio, color_infeccion)

	# División: tope de réplicas por jugador y global gestionado por el mapa.
	if tiene_mutacion("division_celular") and not es_replica:
		tiempo_replicacion += delta
		var intervalo: float = INTERVALO_DIVISION
		if tiene_mutacion("replicacion"):
			intervalo = INTERVALO_REPLICACION
		if tiene_mutacion("brote_masivo"):
			intervalo = INTERVALO_BROTE
		if tiempo_replicacion >= intervalo:
			tiempo_replicacion = 0.0
			var mapa: Node = get_tree().current_scene
			if mapa and mapa.has_method("crear_replicado"):
				mapa.crear_replicado(self)
				if tiene_mutacion("brote_masivo"):
					mapa.crear_replicado(self)


func cambiar_direccion_aleatoria() -> void:
	move_direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()


func _on_timer_timeout() -> void:
	if controlado_por_jugador:
		return
	cambiar_direccion_aleatoria()
	if timer_direccion:
		timer_direccion.wait_time = randf_range(1.5, 3.5)
		timer_direccion.start()


func obtener_amenaza_cercana() -> Node2D:
	for nodo in area_vision.get_overlapping_bodies():
		if nodo != self and nodo.is_in_group("bots") and nodo.is_infected:
			return nodo
	return null


func obtener_humano_cercano() -> Node2D:
	var mas_cercano: Node2D = null
	var distancia_minima: float = INF
	for nodo in area_vision.get_overlapping_bodies():
		if nodo == self or not nodo.is_in_group("bots") or nodo.is_infected:
			continue
		var d: float = global_position.distance_squared_to(nodo.global_position)
		if d < distancia_minima:
			distancia_minima = d
			mas_cercano = nodo
	return mas_cercano


func _objetivo_compartido() -> Node2D:
	# Mente colmena: detecta presas vistas por compañeros del mismo color.
	for aliado in area_vision.get_overlapping_bodies():
		if aliado == self or not aliado.is_in_group("bots"):
			continue
		if not aliado.is_infected or aliado.player_duenio != player_duenio:
			continue
		var vision_aliada: Area2D = aliado.get_node_or_null("AreaVision") as Area2D
		if vision_aliada:
			for candidato in vision_aliada.get_overlapping_bodies():
				if candidato != self and candidato.is_in_group("bots") and not candidato.is_infected:
					return candidato
	return null


func _aliados_cercanos() -> int:
	if area_vision == null:
		return 0
	var numero: int = 0
	for aliado in area_vision.get_overlapping_bodies():
		if aliado != self and aliado.is_in_group("bots") and aliado.is_infected and aliado.player_duenio == player_duenio:
			numero += 1
	return mini(numero, 5)


func huir_de(posicion_amenaza: Vector2) -> void:
	if not is_infected:
		move_direction = (global_position - posicion_amenaza).normalized()


func perseguir_a(posicion_objetivo: Vector2) -> void:
	if is_infected:
		move_direction = (posicion_objetivo - global_position).normalized()


func infectar(color_jugador: Color, id_jugador: int) -> void:
	if is_infected or id_jugador < 1 or id_jugador > 2:
		return
	activar_infeccion(color_jugador, id_jugador)


func activar_infeccion(color_jugador: Color, id_jugador: int, otorgar_adn: bool = true) -> void:
	if is_infected:
		return
	is_infected = true
	color_infeccion = color_jugador
	player_duenio = id_jugador
	tiempo_escudo = 3.0
	tiempo_persiguiendo = 0.0
	tiempo_sin_infectar = 0.0
	bonus_contagio_temporal = 0.0
	tiempo_bonus_contagio = 0.0
	en_rabia = false
	blindaje_restante = 0.0
	cooldown_inmortal = 0.0
	tiempo_nube = 0.0
	tiempo_replicacion = 0.0
	recarga_sobrecarga = 0.0
	tiempo_sobrecarga = 0.0
	pulsos_pendientes = 0
	modulate = color_jugador

	var mapa: Node = get_tree().current_scene
	if mapa and mapa.has_method("aplicar_mutaciones_a_bot"):
		mapa.aplicar_mutaciones_a_bot(self)
	if otorgar_adn and mapa and mapa.has_method("sumar_adn"):
		mapa.sumar_adn(id_jugador)
	timer_contagio.start()
	timer_curacion.start()


func curar_por_robot() -> void:
	# Robot: cura directa sin activar la mutación Último aliento.
	if is_infected:
		curar(false)


func curar(activar_ultimo_aliento: bool = true) -> void:
	if not is_infected:
		return
	if activar_ultimo_aliento and tiene_mutacion("ultimo_aliento"):
		_liberar_ultimo_aliento()
	is_infected = false
	color_infeccion = Color.WHITE
	player_duenio = 0
	cepa = ""
	mutaciones.clear()
	probabilidad_contagio = CONTAGIO_BASE
	probabilidad_curacion = CURACION_BASE
	speed = velocidad_base
	modulate = Color.WHITE
	tiempo_escudo = 0.0
	tiempo_persiguiendo = 0.0
	tiempo_sin_infectar = 0.0
	bonus_contagio_temporal = 0.0
	tiempo_bonus_contagio = 0.0
	en_rabia = false
	blindaje_restante = 0.0
	cooldown_inmortal = 0.0
	tiempo_sobrecarga = 0.0
	pulsos_pendientes = 0
	tiempo_nube = 0.0
	tiempo_replicacion = 0.0
	timer_contagio.stop()
	timer_curacion.stop()


func _chance_contagio() -> float:
	var chance: float = probabilidad_contagio * multiplicador_contagio_temp
	chance += bonus_contagio_temporal
	if en_rabia:
		chance += 0.16
	if tiene_mutacion("parasito"):
		chance += float(_aliados_cercanos()) * 0.025
	if tiene_mutacion("mente_colmena") and _aliados_cercanos() > 0:
		chance += 0.08
	if tiempo_sobrecarga > 0.0:
		chance += 0.10
	chance += _bono_adaptacion_contagio()
	return clampf(chance, 0.0, 0.95)


func _intentar_contagio_area() -> void:
	if not is_infected or area_infeccion == null:
		return
	var chance: float = _chance_contagio()
	for objetivo in area_infeccion.get_overlapping_bodies():
		if not objetivo.is_in_group("bots") or objetivo == self or objetivo.is_infected:
			continue
		if randf() < chance:
			_contagiar_objetivo(objetivo)
	# Esporas pueden alcanzar humanos fuera del área de contacto normal.
	if tiene_mutacion("esporas"):
		_contagio_esporas()


func _contagiar_objetivo(objetivo: Node2D) -> void:
	if not is_instance_valid(objetivo) or objetivo.is_infected:
		return
	objetivo.infectar(color_infeccion, player_duenio)
	tiempo_sin_infectar = 0.0
	en_rabia = false
	# Regeneración recupera una breve protección al conseguir contagiar.
	if tiene_mutacion("regeneracion"):
		blindaje_restante = maxf(blindaje_restante, 2.0)
	if tiene_mutacion("contagio_cadena"):
		bonus_contagio_temporal = minf(bonus_contagio_temporal + 0.06, 0.24)
		tiempo_bonus_contagio = 4.5
	if tiene_mutacion("explosion_infecciosa") and randf() < 0.18:
		_contagio_radial(objetivo.global_position, 75.0, 0.20)


func _contagio_esporas() -> void:
	var alcance: float = 85.0
	var probabilidad: float = 0.10
	if tiene_mutacion("nube_toxica"):
		alcance = 115.0
		probabilidad = 0.14
	var cercanos = get_tree().get_nodes_in_group("bots")
	for objetivo in cercanos:
		if objetivo == self or not is_instance_valid(objetivo) or objetivo.is_infected:
			continue
		if global_position.distance_squared_to(objetivo.global_position) > alcance * alcance:
			continue
		# Sólo la franja exterior al área normal: no repetir el mismo intento.
		if objetivo in area_infeccion.get_overlapping_bodies():
			continue
		if randf() < probabilidad:
			_contagiar_objetivo(objetivo)
			return  # máximo un nuevo infectado por pulso de esporas


func _contagio_radial(posicion: Vector2, radio: float, probabilidad: float) -> void:
	for objetivo in get_tree().get_nodes_in_group("bots"):
		if objetivo == self or not is_instance_valid(objetivo) or objetivo.is_infected:
			continue
		if posicion.distance_squared_to(objetivo.global_position) <= radio * radio:
			if randf() < probabilidad:
				# No encadena explosiones: el efecto sólo lo activa el atacante original.
				objetivo.infectar(color_infeccion, player_duenio)


func _liberar_ultimo_aliento() -> void:
	var radio: float = 80.0
	if tiene_mutacion("explosion_infecciosa"):
		radio = 100.0
	_contagio_radial(global_position, radio, 0.22)


func _liberar_pulso() -> void:
	if not is_infected:
		return
	var radio: float = 75.0
	var chance: float = 0.18
	if tiene_mutacion("tormenta_infecciosa"):
		radio = 105.0
		chance = 0.22
	_contagio_radial(global_position, radio, chance)
	# Indicador visible breve para poder distinguir los pulsos.
	var onda := Polygon2D.new()
	onda.polygon = crear_poligono_circular(radio)
	onda.color = Color(color_infeccion.r, color_infeccion.g, color_infeccion.b, 0.18)
	onda.z_index = 3
	add_child(onda)
	var animacion: Tween = create_tween()
	animacion.tween_property(onda, "modulate:a", 0.0, 0.45)
	animacion.tween_callback(onda.queue_free)


func _intentar_curacion() -> void:
	if not is_infected or tiempo_escudo > 0.0 or blindaje_restante > 0.0:
		return
	var chance: float = probabilidad_curacion
	if tiene_mutacion("caparazon"):
		chance *= 0.80
	if tiene_mutacion("regeneracion"):
		chance *= 0.80
	if randf() >= chance:
		return
	# Infección inmortal no concede inmunidad absoluta ni protege de robots.
	if tiene_mutacion("infeccion_inmortal") and cooldown_inmortal <= 0.0 and randf() < 0.55:
		blindaje_restante = 4.0
		cooldown_inmortal = 15.0
		return
	curar()


func _bono_adaptacion_contagio() -> float:
	if not tiene_mutacion("adaptacion"):
		return 0.0
	var mapa: Node = get_tree().current_scene
	if not mapa or not mapa.has_method("obtener_contagios_jugador"):
		return 0.0
	var cantidad: int = int(mapa.obtener_contagios_jugador(player_duenio))
	var ritmo: float = ADAPTACION_POR_INFECCION
	var tope: float = ADAPTACION_MAXIMA
	if tiene_mutacion("evolucion_rapida"):
		ritmo = EVOLUCION_RAPIDA_POR_INFECCION
		tope = EVOLUCION_RAPIDA_MAXIMA
	var bono: float = minf(float(cantidad) * ritmo, tope)
	if tiene_mutacion("supercepa"):
		if cantidad >= 12:
			bono += SUPERCEPA_BONO_CONTAGIO
		if cantidad >= 25:
			bono += SUPERCEPA_BONO_CONTAGIO
	return bono


func obtener_multiplicador_velocidad() -> float:
	if not is_infected:
		return 1.0
	var mult: float = 1.0
	if tiene_mutacion("fiebre"):
		mult += minf(floorf(tiempo_persiguiendo / 2.0) * 0.05, 0.45)
	if en_rabia:
		mult += 0.25
	if tiene_mutacion("colonia"):
		mult += minf(float(_aliados_cercanos()) * 0.035, 0.18)
	if tiempo_sobrecarga > 0.0:
		mult += 0.20
	if tiene_mutacion("supercepa"):
		var mapa: Node = get_tree().current_scene
		if mapa and mapa.has_method("obtener_contagios_jugador"):
			var cantidad: int = int(mapa.obtener_contagios_jugador(player_duenio))
			if cantidad >= 12:
				mult += SUPERCEPA_BONO_VELOCIDAD
			if cantidad >= 25:
				mult += SUPERCEPA_BONO_VELOCIDAD
	return mult


func aplicar_mutaciones(nuevas_mutaciones: Array[String], nueva_cepa: String = "atletico") -> void:
	# Los humanos sanos no tienen cepa; sus stats se restauran al curarse.
	if not is_infected:
		return
	cepa = nueva_cepa
	mutaciones = nuevas_mutaciones.duplicate()
	speed = velocidad_base
	probabilidad_contagio = CONTAGIO_BASE
	probabilidad_curacion = CURACION_BASE
	match cepa:
		"atletico":
			speed *= 1.15
			probabilidad_contagio *= 0.85
			probabilidad_curacion *= 1.20  # se cura MÁS rápido
		"area":
			speed *= 0.85
			probabilidad_contagio *= 1.20
			probabilidad_curacion *= 0.80  # se cura MÁS lento
		"exponencial":
			probabilidad_contagio = CONTAGIO_EXPONENCIAL_INICIAL
			probabilidad_curacion *= 1.20  # se cura MÁS rápido
	# La temperatura sigue aplicándose por separado en tiempo real.
	probabilidad_contagio = clampf(probabilidad_contagio, 0.0, 1.0)


func tiene_mutacion(nombre: String) -> bool:
	return nombre in mutaciones


func reaccionar_a_obstaculo() -> void:

	# IMPORTANTE:
	# Si está controlado por el jugador, no modificamos
	# su dirección de movimiento mediante la IA.
	if controlado_por_jugador:
		return


	# No esquivamos en el mismo instante del primer contacto.
	if tiempo_ultimo_obstaculo > 0.0:
		return

	var normal_promedio := Vector2.ZERO
	var encontro_obstaculo_real := false
	var cantidad_obstaculos := 0

	# Los bots no cuentan como obstáculos.
	for i in get_slide_collision_count():

		var colision := get_slide_collision(i)

		if not colision:
			continue

		var objeto := colision.get_collider()

		if objeto is Node and objeto.is_in_group("bots"):
			continue

		normal_promedio += colision.get_normal()
		cantidad_obstaculos += 1
		encontro_obstaculo_real = true

	if not encontro_obstaculo_real:

		tiempo_contacto_obstaculo = 0.0
		return

	tiempo_contacto_obstaculo += (
		get_physics_process_delta_time()
	)

	# Un roce corto no cambia la dirección.
	if tiempo_contacto_obstaculo < 0.12:
		return

	tiempo_contacto_obstaculo = 0.0
	tiempo_ultimo_obstaculo = 0.12


	# Si está encerrado entre dos superficies enfrentadas.
	if (
		normal_promedio.length_squared() < 0.01
		and cantidad_obstaculos >= 2
	):

		if move_direction.length_squared() > 0.01:

			direccion_evasion = Vector2(
				-move_direction.y,
				move_direction.x
			).normalized()

			if randf() < 0.5:
				direccion_evasion *= -1.0

			move_direction = direccion_evasion
			tiempo_evasion = 0.55

		return


	if normal_promedio.length_squared() < 0.01:
		return

	normal_promedio = normal_promedio.normalized()


	# Dirección perpendicular a la pared.
	var tangente := Vector2(
		-normal_promedio.y,
		normal_promedio.x
	)


	# No cambiamos de lado constantemente.
	if randf() < 0.5:
		tangente *= -1.0


	direccion_evasion = (
		normal_promedio * 0.65
		+ tangente * 0.90
	).normalized()

	move_direction = direccion_evasion

	tiempo_evasion = 0.55


# ============================================================
# ANIMACIÓN
# ============================================================

func actualizar_animacion(
	direccion: Vector2
) -> void:

	if not animated_sprite:
		return


	if direccion.length_squared() < 0.01:

		animated_sprite.stop()

		return


	if abs(direccion.x) > abs(direccion.y):

		if direccion.x > 0:

			animated_sprite.play(
				"Derecha"
			)

		else:

			animated_sprite.play(
				"Izquierda"
			)

	else:

		if direccion.y > 0:

			animated_sprite.play(
				"Abajo"
			)

		else:

			animated_sprite.play(
				"Arriba"
			)


# ============================================================
# SEÑAL
# ============================================================

func _on_area_infeccion_body_entered(
	_body: Node2D
) -> void:

	pass


# ============================================================
# ACTIVAR CONTROL DEL JUGADOR
# ============================================================

func activar_control_jugador(
	id_jugador: int
) -> void:

	controlado_por_jugador = true
	jugador_controlador = id_jugador

	mostrar_indicador_posesion(id_jugador)

	# Limpiar completamente el movimiento anterior de la IA.
	move_direction = Vector2.ZERO

	# Limpiar cualquier input anterior.
	direccion_control_jugador = Vector2.ZERO

	# Limpiar la dirección real.
	direccion_movimiento_real = Vector2.ZERO

	# Detener inmediatamente el movimiento anterior.
	velocity = Vector2.ZERO

	# Limpiar estados de evasión.
	direccion_evasion = Vector2.ZERO
	tiempo_evasion = 0.0
	tiempo_contacto_obstaculo = 0.0
	tiempo_ultimo_obstaculo = 0.0


# ============================================================
# RECIBIR CONTROL DEL JUGADOR
# ============================================================

func recibir_control_jugador(
	direccion: Vector2
) -> void:

	if not controlado_por_jugador:
		return

	# Normalizamos para evitar que una dirección diagonal
	# sea más rápida.
	direccion_control_jugador = direccion.normalized()


# ============================================================
# DESACTIVAR CONTROL DEL JUGADOR
# ============================================================

func desactivar_control_jugador() -> void:

	controlado_por_jugador = false
	jugador_controlador = 0

	ocultar_indicador_posesion()

	# Limpiar completamente el control anterior.
	direccion_control_jugador = Vector2.ZERO
	direccion_movimiento_real = Vector2.ZERO

	# Detener el movimiento anterior.
	velocity = Vector2.ZERO

	# Limpiar estados de evasión.
	direccion_evasion = Vector2.ZERO
	tiempo_evasion = 0.0
	tiempo_contacto_obstaculo = 0.0
	tiempo_ultimo_obstaculo = 0.0

	# La IA comienza nuevamente con una dirección limpia.
	cambiar_direccion_aleatoria()


# ============================================================
# INDICADOR VISUAL DE POSESIÓN
# ============================================================

func crear_poligono_circular(
	radio: float
) -> PackedVector2Array:

	var puntos := PackedVector2Array()

	for i in SEGMENTOS_INDICADOR:

		var angulo := (
			float(i) / float(SEGMENTOS_INDICADOR)
		) * TAU

		puntos.append(
			Vector2(cos(angulo), sin(angulo)) * radio
		)

	return puntos


func crear_indicador_posesion() -> void:

	# Capa exterior: aura suave.
	indicador_aura_posesion = Polygon2D.new()
	indicador_aura_posesion.name = "AuraPosesion"
	indicador_aura_posesion.polygon = crear_poligono_circular(
		RADIO_INDICADOR_AURA
	)
	indicador_aura_posesion.color = Color(
		0.0,
		1.0,
		1.0,
		0.0
	)
	indicador_aura_posesion.z_index = 10
	indicador_aura_posesion.visible = false
	add_child(indicador_aura_posesion)

	# Capa interior: coincide con el área real de infección.
	indicador_area_infeccion = Polygon2D.new()
	indicador_area_infeccion.name = "AreaInfeccionVisual"
	indicador_area_infeccion.polygon = crear_poligono_circular(
		RADIO_INDICADOR_INFECCION
	)
	indicador_area_infeccion.color = Color(
		0.0,
		1.0,
		1.0,
		0.0
	)
	indicador_area_infeccion.z_index = 11
	indicador_area_infeccion.visible = false
	add_child(indicador_area_infeccion)


func mostrar_indicador_posesion(
	id_jugador: int
) -> void:

	if not indicador_area_infeccion or not indicador_aura_posesion:
		return

	var color_jugador := Color.CYAN

	if id_jugador == 2:
		color_jugador = Color(
			1.0,
			0.0,
			1.0,
			1.0
		)

	# Área real de infección: más visible.
	indicador_area_infeccion.color = Color(
		color_jugador.r,
		color_jugador.g,
		color_jugador.b,
		0.18
	)

	# Aura exterior: más tenue.
	indicador_aura_posesion.color = Color(
		color_jugador.r,
		color_jugador.g,
		color_jugador.b,
		0.10
	)

	indicador_area_infeccion.scale = Vector2.ONE
	indicador_aura_posesion.scale = Vector2.ONE

	indicador_area_infeccion.visible = true
	indicador_aura_posesion.visible = true

	if tween_indicador_posesion:
		tween_indicador_posesion.kill()

	tween_indicador_posesion = create_tween()
	tween_indicador_posesion.set_loops()
	tween_indicador_posesion.set_trans(Tween.TRANS_SINE)
	tween_indicador_posesion.set_ease(Tween.EASE_IN_OUT)

	tween_indicador_posesion.tween_property(
		indicador_aura_posesion,
		"scale",
		Vector2(1.10, 1.10),
		0.65
	)

	tween_indicador_posesion.parallel().tween_property(
		indicador_aura_posesion,
		"color:a",
		0.16,
		0.65
	)

	tween_indicador_posesion.tween_property(
		indicador_aura_posesion,
		"scale",
		Vector2(1.0, 1.0),
		0.65
	)

	tween_indicador_posesion.parallel().tween_property(
		indicador_aura_posesion,
		"color:a",
		0.10,
		0.65
	)


func ocultar_indicador_posesion() -> void:

	if tween_indicador_posesion:
		tween_indicador_posesion.kill()
		tween_indicador_posesion = null

	if indicador_area_infeccion:
		indicador_area_infeccion.visible = false
		indicador_area_infeccion.scale = Vector2.ONE

	if indicador_aura_posesion:
		indicador_aura_posesion.visible = false
		indicador_aura_posesion.scale = Vector2.ONE
