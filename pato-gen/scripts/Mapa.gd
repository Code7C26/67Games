extends Node2D


# ============================================================
# NODOS
# ============================================================

@onready var timer_inicio: Timer = $TimerInicio
@onready var timer_juego: Timer = $TimerJuego
@onready var label_contador: Label = $HUD/LabelContador

@onready var label_adn_cian: Label = $HUD_ADN/LabelADN_Cian
@onready var label_adn_magenta: Label = $HUD_ADN/LabelADN_Magenta

@onready var panel_cian: Panel = $HUD_ADN/PanelCian
@onready var panel_magenta: Panel = $HUD_ADN/PanelMagenta

# Pantalla de Game Over (Asegúrate de que el nodo en la escena se llame GameOver)
@onready var game_over_screen: CanvasLayer = $GameOver


# Escena reutilizable de las zonas de temperatura.
const ESCENA_ZONA_TEMPERATURA: PackedScene = preload("res://scenes/zona_temperatura.tscn")
const ESCENA_ROBOT: PackedScene = preload("res://scenes/robot.tscn")

# ============================================================
# ESTADOS DEL JUEGO
# ============================================================

enum EstadoJuego {
	FASE_PATOS,
	FASE_INFECCION,
	FIN
}

var estado_actual: EstadoJuego = EstadoJuego.FASE_PATOS


# ============================================================
# ADN
# ============================================================

var adn_cian: int = 0
var adn_magenta: int = 0


# ============================================================
# MUTACIONES DE CADA JUGADOR
# ============================================================

var mutaciones_p1: Array[String] = []
var mutaciones_p2: Array[String] = []


# ============================================================
# COSTOS
# ============================================================

const COSTO_BASE: int = 5
const COSTO_EVOLUCION_1: int = 10
const COSTO_EVOLUCION_2: int = 15
const COSTO_ZONA_TEMPERATURA: int = 4
const COSTO_ROBOT: int = 5


# ============================================================
# MUTACIONES
# ============================================================

const MUT_FIEBRE := "fiebre"
const MUT_RABIA := "rabia"

const MUT_CADENA := "contagio_cadena"
const MUT_ULTIMO_ALIENTO := "ultimo_aliento"
const MUT_EXPLOSION := "explosion_infecciosa"

const MUT_RETARDADA := "infeccion_retardada"
const MUT_ASINTOMATICO := "portador_asintomatico"


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	add_to_group("mapa")

	timer_inicio.timeout.connect(_on_timer_inicio_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)

	if panel_cian:
		panel_cian.hide()

	if panel_magenta:
		panel_magenta.hide()

	if game_over_screen:
		game_over_screen.hide()


# ============================================================
# PROCESS
# ============================================================

func _process(_delta: float) -> void:

	if label_adn_cian:
		label_adn_cian.text = (
			"ADN Cian: "
			+ str(adn_cian)
			+ " [E: Menú]"
		)

	if label_adn_magenta:
		label_adn_magenta.text = (
			"ADN Mag: "
			+ str(adn_magenta)
			+ " [O: Menú]"
		)

	if label_adn_cian:
		if adn_cian >= COSTO_BASE:
			label_adn_cian.modulate = Color.GREEN
		else:
			label_adn_cian.modulate = Color.WHITE

	if label_adn_magenta:
		if adn_magenta >= COSTO_BASE:
			label_adn_magenta.modulate = Color.GREEN
		else:
			label_adn_magenta.modulate = Color.WHITE


	# ========================================================
	# FASE PATOS
	# ========================================================

	if estado_actual == EstadoJuego.FASE_PATOS:

		var tiempo = ceil(timer_inicio.time_left)

		if label_contador:
			label_contador.text = (
				"¡A infectar!\n"
				+ str(tiempo)
			)


	# ========================================================
	# FASE INFECCIÓN
	# ========================================================

	elif estado_actual == EstadoJuego.FASE_INFECCION:

		var tiempo = ceil(timer_juego.time_left)
		var stats = contar_infecciones()

		if label_contador:
			label_contador.text = (
				"Tiempo: "
				+ str(tiempo)
				+ "s\n[Blue: "
				+ str(stats.blue)
				+ "]   [Magenta: "
				+ str(stats.magenta)
				+ "]"
			)


# ============================================================
# INPUT
# ============================================================

func _unhandled_input(event: InputEvent) -> void:

	if estado_actual != EstadoJuego.FASE_INFECCION:
		return

	if not event is InputEventKey:
		return

	if not event.pressed or event.echo:
		return


	# ========================================================
	# JUGADOR 1 - CIAN
	# ========================================================

	if event.keycode == KEY_E:

		if panel_cian:
			panel_cian.visible = not panel_cian.visible

	elif event.keycode == KEY_1:

		comprar_mutacion(1, MUT_FIEBRE)

	elif event.keycode == KEY_3:

		comprar_mutacion(1, MUT_CADENA)

	elif event.keycode == KEY_5:

		comprar_mutacion(1, MUT_RETARDADA)


	# ========================================================
	# JUGADOR 2 - MAGENTA
	# ========================================================

	elif event.keycode == KEY_O:

		if panel_magenta:
			panel_magenta.visible = not panel_magenta.visible

	elif event.keycode == KEY_6:

		comprar_mutacion(2, MUT_FIEBRE)

	elif event.keycode == KEY_8:

		comprar_mutacion(2, MUT_CADENA)

	elif event.keycode == KEY_0:

		comprar_mutacion(2, MUT_RETARDADA)


# ============================================================
# CREAR ZONA DE TEMPERATURA
# ============================================================

func crear_zona_temperatura(
	id_jugador: int,
	tipo: String,
	posicion: Vector2
) -> bool:

	if estado_actual != EstadoJuego.FASE_INFECCION:
		return false

	if tipo != "frio" and tipo != "calor":
		return false

	# ========================================================
	# COMPROBAR ADN
	# ========================================================

	var tiene_adn := false

	if id_jugador == 1:
		tiene_adn = adn_cian >= COSTO_ZONA_TEMPERATURA

	elif id_jugador == 2:
		tiene_adn = adn_magenta >= COSTO_ZONA_TEMPERATURA

	else:
		return false

	if not tiene_adn:
		print(
			"Jugador ",
			id_jugador,
			" no tiene suficiente ADN para crear una zona. Necesita ",
			COSTO_ZONA_TEMPERATURA,
			" ADN."
		)
		return false

	# ========================================================
	# CARGAR E INSTANCIAR ESCENA
	# ========================================================

	var zona: ZonaTemperatura = ESCENA_ZONA_TEMPERATURA.instantiate() as ZonaTemperatura

	if zona == null:
		print("No se pudo instanciar zona_temperatura.tscn")
		return false

	# ========================================================
	# CONFIGURAR ZONA
	# ========================================================

	if tipo == "frio":
		zona.tipo = ZonaTemperatura.TipoTemperatura.FRIO
	else:
		zona.tipo = ZonaTemperatura.TipoTemperatura.CALOR

	zona.global_position = posicion

	add_child(zona)

	# ========================================================
	# PAGAR LOS 4 ADN SOLO SI LA ZONA FUE CREADA
	# ========================================================

	if id_jugador == 1:
		adn_cian -= COSTO_ZONA_TEMPERATURA
	else:
		adn_magenta -= COSTO_ZONA_TEMPERATURA

	print(
		"Jugador ",
		id_jugador,
		" creó zona ",
		tipo,
		" en ",
		posicion,
		" | Costo: ",
		COSTO_ZONA_TEMPERATURA,
		" ADN"
	)

	return true


# ============================================================
# CREAR ROBOT CURADOR
# ============================================================

func crear_robot(
	id_jugador: int,
	posicion: Vector2
) -> bool:

	if estado_actual != EstadoJuego.FASE_INFECCION:
		return false

	# ========================================================
	# COMPROBAR ADN
	# ========================================================

	var tiene_adn := false

	if id_jugador == 1:
		tiene_adn = adn_cian >= COSTO_ROBOT

	elif id_jugador == 2:
		tiene_adn = adn_magenta >= COSTO_ROBOT

	else:
		return false

	if not tiene_adn:
		print(
			"Jugador ",
			id_jugador,
			" no tiene suficiente ADN para invocar el robot. Necesita ",
			COSTO_ROBOT,
			" ADN."
		)
		return false

	# ========================================================
	# INSTANCIAR ROBOT
	# ========================================================

	var robot: RobotCurador = ESCENA_ROBOT.instantiate() as RobotCurador

	if robot == null:
		print("No se pudo instanciar robot.tscn")
		return false

	robot.global_position = posicion
	robot.jugador_invocador = id_jugador

	add_child(robot)

	# ========================================================
	# PAGAR SOLO SI EL ROBOT FUE CREADO
	# ========================================================

	if id_jugador == 1:
		adn_cian -= COSTO_ROBOT
	else:
		adn_magenta -= COSTO_ROBOT

	print(
		"Jugador ",
		id_jugador,
		" invocó robot curador en ",
		posicion,
		" | Costo: ",
		COSTO_ROBOT,
		" ADN"
	)

	return true


# ============================================================
# COMPRAR MUTACIÓN / EVOLUCIÓN
# ============================================================

func comprar_mutacion(
	id_jugador: int,
	tipo_base: String
) -> void:

	var mutaciones: Array[String]
	var adn_actual: int


	# ========================================================
	# OBTENER DATOS DEL JUGADOR
	# ========================================================

	if id_jugador == 1:

		mutaciones = mutaciones_p1
		adn_actual = adn_cian

	elif id_jugador == 2:

		mutaciones = mutaciones_p2
		adn_actual = adn_magenta

	else:

		return


	# ========================================================
	# DETERMINAR QUÉ NIVEL TOCA COMPRAR
	# ========================================================

	var siguiente_mutacion := obtener_siguiente_evolucion(
		tipo_base,
		mutaciones
	)


	# Si ya completó la línea.
	if siguiente_mutacion == "":

		print(
			"El jugador ",
			id_jugador,
			" ya completó esta línea."
		)

		return


	# ========================================================
	# DETERMINAR COSTO
	# ========================================================

	var costo := obtener_costo_mutacion(
		tipo_base,
		mutaciones
	)


	# ========================================================
	# COMPROBAR ADN
	# ========================================================

	if adn_actual < costo:

		print(
			"Jugador ",
			id_jugador,
			" no tiene suficiente ADN. Necesita ",
			costo,
			". Tiene ",
			adn_actual
		)

		return


	# ========================================================
	# PAGAR
	# ========================================================

	if id_jugador == 1:

		adn_cian -= costo
		mutaciones_p1.append(siguiente_mutacion)

	else:

		adn_magenta -= costo
		mutaciones_p2.append(siguiente_mutacion)


	# ========================================================
	# ACTUALIZAR BOTS
	# ========================================================

	actualizar_mutaciones_existentes(id_jugador)


	print(
		"Jugador ",
		id_jugador,
		" evolucionó: ",
		siguiente_mutacion,
		" | Costo: ",
		costo
	)


# ============================================================
# OBTENER SIGUIENTE MUTACIÓN DE UNA LÍNEA
# ============================================================

func obtener_siguiente_evolucion(
	tipo_base: String,
	mutaciones: Array[String]
) -> String:

	# ========================================================
	# FIEBRE → RABIA
	# ========================================================

	if tipo_base == MUT_FIEBRE:

		if MUT_FIEBRE not in mutaciones:

			return MUT_FIEBRE

		if MUT_RABIA not in mutaciones:

			return MUT_RABIA

		return ""


	# ========================================================
	# CADENA → ÚLTIMO ALIENTO → EXPLOSIÓN
	# ========================================================

	if tipo_base == MUT_CADENA:

		if MUT_CADENA not in mutaciones:

			return MUT_CADENA

		if MUT_ULTIMO_ALIENTO not in mutaciones:

			return MUT_ULTIMO_ALIENTO

		if MUT_EXPLOSION not in mutaciones:

			return MUT_EXPLOSION

		return ""


	# ========================================================
	# RETARDADA → ASINTOMÁTICO
	# ========================================================

	if tipo_base == MUT_RETARDADA:

		if MUT_RETARDADA not in mutaciones:

			return MUT_RETARDADA

		if MUT_ASINTOMATICO not in mutaciones:

			return MUT_ASINTOMATICO

		return ""


	return ""


# ============================================================
# OBTENER COSTO
# ============================================================

func obtener_costo_mutacion(
	tipo_base: String,
	mutaciones: Array[String]
) -> int:

	# FIEBRE → RABIA

	if tipo_base == MUT_FIEBRE:

		if MUT_FIEBRE not in mutaciones:
			return COSTO_BASE

		return COSTO_EVOLUCION_1


	# CADENA → ÚLTIMO → EXPLOSIÓN

	if tipo_base == MUT_CADENA:

		if MUT_CADENA not in mutaciones:
			return COSTO_BASE

		if MUT_ULTIMO_ALIENTO not in mutaciones:
			return COSTO_EVOLUCION_1

		return COSTO_EVOLUCION_2


	# RETARDADA → ASINTOMÁTICO

	if tipo_base == MUT_RETARDADA:

		if MUT_RETARDADA not in mutaciones:
			return COSTO_BASE

		return COSTO_EVOLUCION_1


	return COSTO_BASE


# ============================================================
# SUMAR ADN
# ============================================================

func sumar_adn(id_jugador: int) -> void:

	if id_jugador == 1:

		adn_cian += 1

	elif id_jugador == 2:

		adn_magenta += 1


# ============================================================
# APLICAR MUTACIONES A UN BOT
# ============================================================

func aplicar_mutaciones_a_bot(bot: Node2D) -> void:

	if not is_instance_valid(bot):
		return


	if bot.player_duenio == 1:

		bot.aplicar_mutaciones(
			mutaciones_p1
		)


	elif bot.player_duenio == 2:

		bot.aplicar_mutaciones(
			mutaciones_p2
		)


# ============================================================
# ACTUALIZAR TODOS LOS BOTS INFECTADOS
# ============================================================

func actualizar_mutaciones_existentes(
	id_jugador: int
) -> void:

	var bots = get_tree().get_nodes_in_group("bots")

	for bot in bots:

		if not is_instance_valid(bot):
			continue

		if not bot.is_infected:
			continue

		if bot.player_duenio != id_jugador:
			continue

		aplicar_mutaciones_a_bot(bot)


# ============================================================
# TIMER INICIAL
# ============================================================

func _on_timer_inicio_timeout() -> void:

	var patos = get_tree().get_nodes_in_group("patos")

	for pato in patos:

		if is_instance_valid(pato):
			pato.infectar_y_desaparecer()

	estado_actual = EstadoJuego.FASE_INFECCION
	timer_juego.start()


# ============================================================
# FIN DEL JUEGO
# ============================================================

func _on_timer_juego_timeout() -> void:

	estado_actual = EstadoJuego.FIN
	timer_juego.stop()

	var stats = contar_infecciones()
	var mensaje_resultado: String = ""

	if stats.blue > stats.magenta:

		mensaje_resultado = (
			"¡GANO EL JUGADOR CIAN!\n"
			+ "(Infectados: "
			+ str(stats.blue)
			+ ")"
		)

	elif stats.magenta > stats.blue:

		mensaje_resultado = (
			"¡GANO EL JUGADOR MAGENTA!\n"
			+ "(Infectados: "
			+ str(stats.magenta)
			+ ")"
		)

	else:

		mensaje_resultado = "¡EMPATE TECNICO!"

	if label_contador:
		label_contador.text = mensaje_resultado

	# Muestra el panel de GameOver e inserta el resultado si tiene el Label correspondiente
	if game_over_screen:
		game_over_screen.visible = true

		var label_resultado = game_over_screen.get_node_or_null("MarginContainer/VBoxContainer/Label")
		if label_resultado:
			label_resultado.text = mensaje_resultado

	# Pausa el juego congelando la partida
	get_tree().paused = true


# ============================================================
# CONTAR INFECCIONES
# ============================================================

func contar_infecciones() -> Dictionary:

	var bots = get_tree().get_nodes_in_group("bots")

	var blue: int = 0
	var magenta: int = 0


	for bot in bots:

		if not bot.is_infected:
			continue


		if bot.color_infeccion.is_equal_approx(
			Color.BLUE
		):

			blue += 1


		elif bot.color_infeccion.is_equal_approx(
			Color.MAGENTA
		):

			magenta += 1


	return {
		"blue": blue,
		"magenta": magenta
	}
