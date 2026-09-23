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
# COSTO DE MUTACIONES
# ============================================================

var costo_mutacion: int = 5


# ============================================================
# NOMBRES DE MUTACIONES
# ============================================================

const MUT_FIEBRE := "fiebre"
const MUT_CAZADOR := "cazador"
const MUT_CADENA := "contagio_cadena"
const MUT_ASINTOMATICO := "portador_asintomatico"
const MUT_RETARDADA := "infeccion_retardada"
const MUT_RESISTENCIA := "resistencia"
const MUT_ULTIMO_ALIENTO := "ultimo_aliento"
const MUT_NIDO := "nido"
const MUT_RABIA := "rabia"
const MUT_EXPLOSION := "explosion_infecciosa"


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	timer_inicio.timeout.connect(_on_timer_inicio_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)

	if panel_cian:
		panel_cian.hide()

	if panel_magenta:
		panel_magenta.hide()


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

	# Destaca el ADN cuando hay suficiente para comprar.
	if label_adn_cian:
		if adn_cian >= costo_mutacion:
			label_adn_cian.modulate = Color.GREEN
		else:
			label_adn_cian.modulate = Color.WHITE

	if label_adn_magenta:
		if adn_magenta >= costo_mutacion:
			label_adn_magenta.modulate = Color.GREEN
		else:
			label_adn_magenta.modulate = Color.WHITE


	# --------------------------------------------------------
	# FASE DE PATOS
	# --------------------------------------------------------

	if estado_actual == EstadoJuego.FASE_PATOS:

		var tiempo = ceil(timer_inicio.time_left)

		if label_contador:
			label_contador.text = (
				"¡A infectar!\n"
				+ str(tiempo)
			)


	# --------------------------------------------------------
	# FASE DE INFECCIÓN
	# --------------------------------------------------------

	elif estado_actual == EstadoJuego.FASE_INFECCION:

		var tiempo = ceil(timer_juego.time_left)
		var stats = contar_infecciones()

		if label_contador:
			label_contador.text = (
				"Tiempo: "
				+ str(tiempo)
				+ "s\n[Cian: "
				+ str(stats.cian)
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

	elif event.keycode == KEY_2:

		comprar_mutacion(1, MUT_CAZADOR)

	elif event.keycode == KEY_3:

		comprar_mutacion(1, MUT_CADENA)

	elif event.keycode == KEY_4:

		comprar_mutacion(1, MUT_ASINTOMATICO)

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

	elif event.keycode == KEY_7:

		comprar_mutacion(2, MUT_CAZADOR)

	elif event.keycode == KEY_8:

		comprar_mutacion(2, MUT_CADENA)

	elif event.keycode == KEY_9:

		comprar_mutacion(2, MUT_ASINTOMATICO)

	elif event.keycode == KEY_0:

		comprar_mutacion(2, MUT_RETARDADA)


# ============================================================
# COMPRAR MUTACIÓN
# ============================================================

func comprar_mutacion(
	id_jugador: int,
	tipo: String
) -> void:

	# --------------------------------------------------------
	# JUGADOR 1
	# --------------------------------------------------------

	if id_jugador == 1:

		if adn_cian < costo_mutacion:
			print("Cian no tiene suficiente ADN.")
			return

		if tipo in mutaciones_p1:
			print("Cian ya tiene la mutación: ", tipo)
			return

		adn_cian -= costo_mutacion
		mutaciones_p1.append(tipo)

		actualizar_mutaciones_existentes(1)

		print(
			"CIAN compró: ",
			tipo,
			" | ADN restante: ",
			adn_cian
		)

		return


	# --------------------------------------------------------
	# JUGADOR 2
	# --------------------------------------------------------

	if id_jugador == 2:

		if adn_magenta < costo_mutacion:
			print("Magenta no tiene suficiente ADN.")
			return

		if tipo in mutaciones_p2:
			print("Magenta ya tiene la mutación: ", tipo)
			return

		adn_magenta -= costo_mutacion
		mutaciones_p2.append(tipo)

		actualizar_mutaciones_existentes(2)

		print(
			"MAGENTA compró: ",
			tipo,
			" | ADN restante: ",
			adn_magenta
		)

		return


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


	# --------------------------------------------------------
	# CIAN
	# --------------------------------------------------------

	if bot.player_duenio == 1:

		bot.aplicar_mutaciones(
			mutaciones_p1
		)


	# --------------------------------------------------------
	# MAGENTA
	# --------------------------------------------------------

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

	get_tree().paused = true

	var stats = contar_infecciones()


	if stats.cian > stats.magenta:

		label_contador.text = (
			"¡GANÓ EL JUGADOR CIAN!\n"
			+ "(Infectados: "
			+ str(stats.cian)
			+ ")"
		)


	elif stats.magenta > stats.cian:

		label_contador.text = (
			"¡GANÓ EL JUGADOR MAGENTA!\n"
			+ "(Infectados: "
			+ str(stats.magenta)
			+ ")"
		)


	else:

		label_contador.text = "¡EMPATE TÉCNICO!"


# ============================================================
# CONTAR INFECCIONES
# ============================================================

func contar_infecciones() -> Dictionary:

	var bots = get_tree().get_nodes_in_group("bots")

	var cian := 0
	var magenta := 0


	for bot in bots:

		if not bot.is_infected:
			continue


		if bot.color_infeccion.is_equal_approx(
			Color.CYAN
		):

			cian += 1


		elif bot.color_infeccion.is_equal_approx(
			Color.MAGENTA
		):

			magenta += 1


	return {
		"cian": cian,
		"magenta": magenta
	}
