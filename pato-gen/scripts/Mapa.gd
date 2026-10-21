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

# Teclas visuales de habilidades - Cian
@onready var tecla_g_cian: Label = $HUD_ADN/PanelCian/Label
@onready var tecla_c_cian: Label = $HUD_ADN/PanelCian/Label2
@onready var tecla_x_cian: Label = $HUD_ADN/PanelCian/Label3

# Teclas visuales de mutaciones - Cian
@onready var tecla_1_cian: Label = $HUD_ADN/PanelCian/Label4
@onready var tecla_5_cian: Label = $HUD_ADN/PanelCian/Label5
@onready var tecla_3_cian: Label = $HUD_ADN/PanelCian/Label6

# Tecla visual de posesión - Cian
@onready var tecla_q_cian: Label = $HUD_ADN/PanelCian/Label7

# Teclas visuales de habilidades - Magenta
@onready var tecla_h_magenta: Label = $HUD_ADN/PanelMagenta/Label
@onready var tecla_n_magenta: Label = $HUD_ADN/PanelMagenta/Label2
@onready var tecla_b_magenta: Label = $HUD_ADN/PanelMagenta/Label3

# Teclas visuales de mutaciones - Magenta
@onready var tecla_6_magenta: Label = $HUD_ADN/PanelMagenta/Label4
@onready var tecla_0_magenta: Label = $HUD_ADN/PanelMagenta/Label5
@onready var tecla_8_magenta: Label = $HUD_ADN/PanelMagenta/Label6

# Tecla visual de posesión - Magenta
@onready var tecla_q_magenta: Label = $HUD_ADN/PanelMagenta/Label7

# Botones de mutaciones
@onready var btn_fiebre_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnFiebre
@onready var btn_cadena_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnCadena
@onready var btn_retardada_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnInfeccion

@onready var btn_fiebre_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnFiebre
@onready var btn_cadena_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnCadena
@onready var btn_retardada_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnInfeccion

# Botones de habilidades (para mantener las teclas visuales alineadas
# aunque cambie el alto de los botones en tiempo de ejecución).
@onready var btn_robot_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnInfeccion2
@onready var btn_zona_frio_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnInfeccion3
@onready var btn_zona_calor_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnInfeccion4
@onready var btn_posesion_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnInfeccion5

@onready var btn_robot_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnInfeccion2
@onready var btn_zona_frio_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnInfeccion3
@onready var btn_zona_calor_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnInfeccion4
@onready var btn_posesion_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnInfeccion5

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

# ADN de remontada: se entrega al equipo que tenga 5+ infectados menos.
@export var diferencia_minima_remontada: int = 5
@export var adn_por_segundo_remontada: int = 1
var tiempo_remontada: float = 0.0
var equipo_remontada: int = 0

# Balance de late game. Los multiplicadores solo afectan la curacion natural.
@export_group("Balance de remontada")
@export var diferencia_inestabilidad_1: int = 5
@export var diferencia_inestabilidad_2: int = 10
@export var diferencia_inestabilidad_3: int = 20
@export var multiplicador_inestabilidad_1: float = 1.15
@export var multiplicador_inestabilidad_2: float = 1.35
@export var multiplicador_inestabilidad_3: float = 1.60
@export var diferencia_activar_curacion_ofensiva: int = 20
@export var diferencia_desactivar_curacion_ofensiva: int = 15
@export_range(0.0, 1.0, 0.001) var chance_curacion_ofensiva: float = 0.02
@export var intervalo_curacion_ofensiva: float = 2.0
@export var proteccion_sano_tras_curacion_ofensiva: float = 2.0
@export_group("")

var equipo_curacion_ofensiva: int = 0
var multiplicador_curacion_cian: float = 1.0
var multiplicador_curacion_magenta: float = 1.0


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
const COSTO_ROBOT: int = 10


# ============================================================
# CEPAS, RAMAS Y EVOLUCIONES (una cepa fija por jugador)
# ============================================================

const TIPOS: Array[String] = ["atletico", "area", "exponencial"]
const RAMAS: Dictionary = {
	"atletico": [
		["fiebre", "rabia"],
		["parasito", "colonia", "mente_colmena"],
		["caparazon", "regeneracion", "infeccion_inmortal"]
	],
	"area": [
		["contagio_cadena", "ultimo_aliento", "explosion_infecciosa"],
		["esporas", "nube_toxica", "epidemia_ambiental"],
		["sobrecarga", "pulso_viral", "tormenta_infecciosa"]
	],
	"exponencial": [
		["adaptacion", "evolucion_rapida", "supercepa"],
		["division_celular", "replicacion", "brote_masivo"]
	]
}

var cepa_cian: String = "atletico"
var cepa_magenta: String = "atletico"
var contagios_cian: int = 0
var contagios_magenta: int = 0
var replicas_cian: int = 0
var replicas_magenta: int = 0

const MAX_REPLICAS_POR_JUGADOR: int = 8
const MAX_BOTS_TOTALES: int = 100
const MAX_NUBES_POR_JUGADOR: int = 6
# ===== BALANCE DE EPIDEMIA AMBIENTAL =====
const RADIO_NUBE_AMBIENTAL: float = 100.0
const DURACION_NUBE_AMBIENTAL: float = 9.0
const CHANCE_NUBE_AMBIENTAL: float = 0.10
const ESCENA_BOT: PackedScene = preload("res://scenes/Bot.tscn")
var nubes_activas: Array[Dictionary] = []
var reloj_nubes: float = 0.0

# Panel temporal para consultar mutaciones con Shift + tecla.
var panel_descripcion_mutacion: PanelContainer
var label_descripcion_mutacion: Label
var tiempo_descripcion_mutacion: float = 0.0

func _nombre_cepa(cepa: String) -> String:
	match cepa:
		"atletico": return "ATLÉTICO"
		"area": return "DE ÁREA"
		"exponencial": return "EXPONENCIAL"
	return "ATLÉTICO"

func obtener_cepa_jugador(id_jugador: int) -> String:
	if id_jugador == 1:
		return cepa_cian
	if id_jugador == 2:
		return cepa_magenta
	return "atletico"

func obtener_ramas_jugador(id_jugador: int) -> Array:
	return RAMAS.get(obtener_cepa_jugador(id_jugador), [])

func obtener_contagios_jugador(id_jugador: int) -> int:
	return contagios_cian if id_jugador == 1 else contagios_magenta

func _comprar_rama(id_jugador: int, indice_rama: int) -> void:
	if estado_actual != EstadoJuego.FASE_INFECCION:
		return
	var ramas: Array = obtener_ramas_jugador(id_jugador)
	if indice_rama < 0 or indice_rama >= ramas.size():
		return
	comprar_mutacion(id_jugador, str(ramas[indice_rama][0]))

func _conectar_botones_mutaciones() -> void:
	var botones_cian: Array[Button] = [btn_fiebre_cian, btn_cadena_cian, btn_retardada_cian]
	var botones_magenta: Array[Button] = [btn_fiebre_magenta, btn_cadena_magenta, btn_retardada_magenta]
	for i in range(3):
		botones_cian[i].pressed.connect(_comprar_rama.bind(1, i))
		botones_magenta[i].pressed.connect(_comprar_rama.bind(2, i))


# ============================================================
# READY
# ============================================================

func _ready() -> void:
	AudioManager.reproducir_partida()
	# Selección persiste entre escenas sin requerir autoload.
	var elegidos: Dictionary = get_tree().root.get_meta("patogen_cepas", {})
	var tipo1: String = str(elegidos.get(1, "atletico"))
	var tipo2: String = str(elegidos.get(2, "atletico"))
	cepa_cian = tipo1 if tipo1 in TIPOS else "atletico"
	cepa_magenta = tipo2 if tipo2 in TIPOS else "atletico"
	add_to_group("mapa")
	_crear_panel_descripcion_mutacion()
	_conectar_botones_mutaciones()
	# Nombres de nodos antiguos; textos visibles de mutaciones actualizados.
	tecla_1_cian.text = "1"
	tecla_3_cian.text = "2"
	tecla_5_cian.text = "3"
	tecla_6_magenta.text = "8"
	tecla_8_magenta.text = "9"
	tecla_0_magenta.text = "0"
	# Exponencial aún no tiene tercera rama: ocultamos también su etiqueta 5/0.
	tecla_5_cian.visible = cepa_cian != "exponencial"
	tecla_0_magenta.visible = cepa_magenta != "exponencial"
	actualizar_menu_mutaciones()

	timer_inicio.timeout.connect(_on_timer_inicio_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)

	if panel_cian:
		panel_cian.hide()

	if panel_magenta:
		panel_magenta.hide()

	if game_over_screen:
		game_over_screen.hide()

	# Esperamos a que los Container terminen de calcular el tamaño
	# de los botones antes de colocar las teclas.
	call_deferred("alinear_teclas_habilidades")


# ============================================================
# PROCESS
# ============================================================

func _process(_delta: float) -> void:
	actualizar_adn_remontada(_delta)
	actualizar_balance_tardio()
	if tiempo_descripcion_mutacion > 0.0:
		tiempo_descripcion_mutacion -= _delta
		if tiempo_descripcion_mutacion <= 0.0 and is_instance_valid(panel_descripcion_mutacion):
			panel_descripcion_mutacion.hide()

	if label_adn_cian:
		label_adn_cian.text = (
			"ADN Cian: "
			+ str(adn_cian)
			+ " [E: Menú] - " + _nombre_cepa(cepa_cian)
		)

	if label_adn_magenta:
		label_adn_magenta.text = (
			"ADN Mag: "
			+ str(adn_magenta)
			+ " [O: Menú] - " + _nombre_cepa(cepa_magenta)
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

	actualizar_menu_mutaciones()
	actualizar_cooldowns_habilidades()
	alinear_teclas_habilidades()

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
# ACTUALIZAR MENÚ DE MUTACIONES
# ============================================================

func actualizar_menu_mutaciones() -> void:
	var botones_cian: Array[Button] = [btn_fiebre_cian, btn_cadena_cian, btn_retardada_cian]
	var botones_magenta: Array[Button] = [btn_fiebre_magenta, btn_cadena_magenta, btn_retardada_magenta]
	for i in range(3):
		_actualizar_boton_rama(botones_cian[i], 1, i)
		_actualizar_boton_rama(botones_magenta[i], 2, i)


func _actualizar_boton_rama(boton: Button, id_jugador: int, indice_rama: int) -> void:
	var ramas: Array = obtener_ramas_jugador(id_jugador)
	if indice_rama >= ramas.size():
		boton.text = "PRÓXIMAMENTE"
		boton.tooltip_text = "Esta cepa tiene dos ramas por ahora."
		boton.disabled = true
		return
	var mutaciones: Array[String] = mutaciones_p1 if id_jugador == 1 else mutaciones_p2
	var adn: int = adn_cian if id_jugador == 1 else adn_magenta
	var base: String = str(ramas[indice_rama][0])
	var siguiente: String = obtener_siguiente_evolucion(base, mutaciones)
	if siguiente == "":
		boton.text = _nombre_mutacion(str(ramas[indice_rama].back())) + " [COMPLETA]"
		boton.disabled = true
		boton.tooltip_text = "Rama completa. Ya compraste todas sus evoluciones."
		return
	var costo: int = obtener_costo_mutacion(base, mutaciones)
	boton.text = _nombre_mutacion(siguiente) + " [ " + str(costo) + " ADN ]"
	boton.tooltip_text = _descripcion_mutacion(siguiente) + "\n\nCoste: " + str(costo) + " ADN. Pasa el cursor para consultar; Shift + tecla muestra esta descripción sin comprar."
	boton.disabled = adn < costo or estado_actual != EstadoJuego.FASE_INFECCION


func _nombre_mutacion(mutacion: String) -> String:
	const NOMBRES: Dictionary = {
		"fiebre": "Fiebre", "rabia": "Rabia",
		"parasito": "Parásito", "colonia": "Colonia", "mente_colmena": "Mente colmena",
		"caparazon": "Caparazón", "regeneracion": "Regeneración", "infeccion_inmortal": "Infección inmortal",
		"contagio_cadena": "Contagio en cadena", "ultimo_aliento": "Último aliento", "explosion_infecciosa": "Explosión infecciosa",
		"esporas": "Esporas", "nube_toxica": "Nube tóxica", "epidemia_ambiental": "Epidemia ambiental",
		"sobrecarga": "Sobrecarga", "pulso_viral": "Pulso viral", "tormenta_infecciosa": "Tormenta infecciosa",
		"adaptacion": "Adaptación", "evolucion_rapida": "Evolución rápida", "supercepa": "Supercepa",
		"division_celular": "División celular", "replicacion": "Replicación", "brote_masivo": "Brote masivo"
	}
	return str(NOMBRES.get(mutacion, mutacion))


func _descripcion_mutacion(mutacion: String) -> String:
	# Descripciones basadas en los efectos implementados actualmente en Bot.gd.
	const DESCRIPCIONES: Dictionary = {
		"fiebre": "FIEBRE\nMientras persigue a un humano, gana +5% de velocidad por cada 2 segundos de persecución, hasta +45%.",
		"rabia": "RABIA\nDespués de 8 segundos sin infectar a nadie, obtiene +25% de velocidad y +16 puntos porcentuales de probabilidad de contagio. Se desactiva al infectar.",
		"parasito": "PARÁSITO\nCada aliado infectado cercano añade +2,5 puntos porcentuales a la probabilidad de contagio.",
		"colonia": "COLONIA\nCada aliado infectado cercano añade +3,5% de velocidad, hasta un máximo de +18%.",
		"mente_colmena": "MENTE COLMENA\nSi hay un aliado infectado cerca, añade +8 puntos porcentuales a la probabilidad de contagio. También puede perseguir un objetivo detectado por un compañero cuando no encuentra uno propio.",
		"caparazon": "CAPARAZÓN\nReduce un 20% la probabilidad de que este infectado se cure a sí mismo en cada intento de curación.",
		"regeneracion": "REGENERACIÓN\nReduce otro 20% la probabilidad de autocuración. Además, cuando contagia a alguien, obtiene 2 segundos de protección frente a intentos de curación.",
		"infeccion_inmortal": "INFECCIÓN INMORTAL\nCuando va a curarse, tiene un 55% de probabilidad de resistir esa curación y ganar 4 segundos de protección. Este efecto tiene 15 segundos de recarga.",
		"contagio_cadena": "CONTAGIO EN CADENA\nCada infección exitosa aumenta la probabilidad de contagio en +6 puntos porcentuales, hasta +24%. El bonus dura 4,5 segundos desde la última infección.",
		"ultimo_aliento": "ÚLTIMO ALIENTO\nCuando un infectado es curado, intenta contagiar a los humanos cercanos en un radio de 80 unidades, con un 22% de probabilidad por objetivo. No se activa al curarlo un robot.",
		"explosion_infecciosa": "EXPLOSIÓN INFECCIOSA\nCada contagio tiene un 18% de probabilidad de provocar una explosión que intenta infectar a humanos dentro de un radio de 75 unidades, con un 20% de probabilidad por objetivo. También amplía a 100 el radio de Último aliento.",
		"esporas": "ESPORAS\nCada pulso de contagio intenta infectar a un humano que esté fuera del alcance de contacto, hasta 85 unidades de distancia, con un 10% de probabilidad.",
		"nube_toxica": "NUBE TÓXICA\nMejora Esporas: aumenta el alcance de 85 a 115 unidades y la probabilidad de contagio por pulso del 10% al 14%.",
		"epidemia_ambiental": "EPIDEMIA AMBIENTAL\nCada 12 segundos deja una nube en su posición. La nube dura 9 segundos, tiene 100 unidades de radio y cada medio segundo intenta infectar a los humanos dentro con un 10% de probabilidad.",
		"sobrecarga": "SOBRECARGA\nCada 12 segundos obtiene durante 2,5 segundos +20% de velocidad y +10 puntos porcentuales de probabilidad de contagio.",
		"pulso_viral": "PULSO VIRAL\nCada vez que se activa Sobrecarga, libera un pulso que intenta infectar a humanos en un radio de 75 unidades, con un 18% de probabilidad por objetivo.",
		"tormenta_infecciosa": "TORMENTA INFECCIOSA\nMejora los pulsos a 105 unidades de radio y 22% de probabilidad por objetivo. Además, la activación libera dos pulsos adicionales, separados por 0,75 segundos.",
		"adaptacion": "ADAPTACIÓN\nContagio inicial del Exponencial: 28% (antes de temperatura y mutaciones). Cada humano infectado por tu jugador aumenta en 0,2 puntos porcentuales la probabilidad de contagio de tus bots, hasta un máximo de +6 puntos porcentuales.",
		"evolucion_rapida": "EVOLUCIÓN RÁPIDA\nMejora Adaptación: cada infección suma 0,4 puntos porcentuales en vez de 0,2 y el bonus acumulado puede llegar hasta +12 puntos porcentuales.",
		"supercepa": "SUPERCEPA\nAl llegar a 12 infecciones de tu jugador, añade +2,5 puntos porcentuales de contagio y +5% de velocidad. Al llegar a 25, añade otros +2,5 puntos porcentuales de contagio y +5% de velocidad.",
		"division_celular": "DIVISIÓN CELULAR\nCada 28 segundos intenta crear un nuevo infectado cerca de este bot. Las réplicas no otorgan ADN, no pueden reproducirse y respetan el límite de 8 réplicas por jugador.",
		"replicacion": "REPLICACIÓN\nReduce de 28 a 23 segundos el intervalo entre intentos de crear nuevos infectados.",
		"brote_masivo": "BROTE MASIVO\nReduce el intervalo de replicación a 20 segundos y hace dos intentos de creación por ciclo. Solo los infectados originales pueden reproducirse y los límites de población siguen aplicándose."
	}
	return str(DESCRIPCIONES.get(mutacion, "No hay una descripción definida para esta mutación."))


func _crear_panel_descripcion_mutacion() -> void:
	var capa := CanvasLayer.new()
	capa.name = "CapaDescripcionMutacion"
	capa.layer = 20
	add_child(capa)

	panel_descripcion_mutacion = PanelContainer.new()
	panel_descripcion_mutacion.name = "PanelDescripcionMutacion"
	panel_descripcion_mutacion.visible = false
	panel_descripcion_mutacion.anchor_left = 0.5
	panel_descripcion_mutacion.anchor_right = 0.5
	panel_descripcion_mutacion.anchor_top = 0.0
	panel_descripcion_mutacion.anchor_bottom = 0.0
	panel_descripcion_mutacion.offset_left = -300.0
	panel_descripcion_mutacion.offset_right = 300.0
	panel_descripcion_mutacion.offset_top = 35.0
	panel_descripcion_mutacion.offset_bottom = 190.0
	capa.add_child(panel_descripcion_mutacion)
	# Fondo casi opaco para facilitar la lectura.
	var estilo_descripcion: StyleBoxFlat = StyleBoxFlat.new()
	estilo_descripcion.bg_color = Color(0.02, 0.04, 0.07, 0.97)
	estilo_descripcion.set_corner_radius_all(10)
	estilo_descripcion.set_border_width_all(2)
	estilo_descripcion.border_color = Color(0.30, 0.65, 0.78, 1.0)
	panel_descripcion_mutacion.add_theme_stylebox_override("panel", estilo_descripcion)

	var margen := MarginContainer.new()
	margen.add_theme_constant_override("margin_left", 14)
	margen.add_theme_constant_override("margin_right", 14)
	margen.add_theme_constant_override("margin_top", 10)
	margen.add_theme_constant_override("margin_bottom", 10)
	panel_descripcion_mutacion.add_child(margen)

	label_descripcion_mutacion = Label.new()
	label_descripcion_mutacion.name = "TextoDescripcionMutacion"
	label_descripcion_mutacion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label_descripcion_mutacion.add_theme_font_size_override("font_size", 16)
	margen.add_child(label_descripcion_mutacion)


func _mostrar_descripcion_rama(id_jugador: int, indice_rama: int) -> void:
	var ramas: Array = obtener_ramas_jugador(id_jugador)
	if indice_rama < 0 or indice_rama >= ramas.size():
		_mostrar_descripcion("Esta cepa todavía no tiene una mutación asignada a esa tecla.")
		return

	var mutaciones: Array[String] = mutaciones_p1 if id_jugador == 1 else mutaciones_p2
	var base: String = str(ramas[indice_rama][0])
	var siguiente: String = obtener_siguiente_evolucion(base, mutaciones)
	if siguiente == "":
		_mostrar_descripcion("Esta rama ya está completa: " + _nombre_mutacion(str(ramas[indice_rama].back())) + ".")
		return

	var costo: int = obtener_costo_mutacion(base, mutaciones)
	var adn: int = adn_cian if id_jugador == 1 else adn_magenta
	var texto := _descripcion_mutacion(siguiente)
	texto += "\n\nCoste: " + str(costo) + " ADN. "
	if adn >= costo:
		texto += "Tienes suficiente ADN. Pulsa la tecla sin Shift para comprar."
	else:
		texto += "Te faltan " + str(costo - adn) + " ADN."
	_mostrar_descripcion(texto)


func _mostrar_descripcion(texto: String) -> void:
	if not is_instance_valid(panel_descripcion_mutacion):
		return
	label_descripcion_mutacion.text = texto
	panel_descripcion_mutacion.show()
	tiempo_descripcion_mutacion = 5.0


func alinear_teclas_habilidades() -> void:
	# Las teclas son Labels que están fuera del VBoxContainer.
	# Por eso no siguen automáticamente el alto real de cada Button.
	# Calculamos su posición a partir del botón correspondiente.

	# HABILIDADES
	_alinear_tecla_con_boton(tecla_g_cian, btn_robot_cian, panel_cian)
	_alinear_tecla_con_boton(tecla_x_cian, btn_zona_frio_cian, panel_cian)
	_alinear_tecla_con_boton(tecla_c_cian, btn_zona_calor_cian, panel_cian)

	_alinear_tecla_con_boton(tecla_h_magenta, btn_robot_magenta, panel_magenta)
	_alinear_tecla_con_boton(tecla_b_magenta, btn_zona_frio_magenta, panel_magenta)
	_alinear_tecla_con_boton(tecla_n_magenta, btn_zona_calor_magenta, panel_magenta)

	# MUTACIONES
	_alinear_tecla_con_boton(tecla_1_cian, btn_fiebre_cian, panel_cian)
	_alinear_tecla_con_boton(tecla_3_cian, btn_cadena_cian, panel_cian)
	_alinear_tecla_con_boton(tecla_5_cian, btn_retardada_cian, panel_cian)

	_alinear_tecla_con_boton(tecla_6_magenta, btn_fiebre_magenta, panel_magenta)
	_alinear_tecla_con_boton(tecla_8_magenta, btn_cadena_magenta, panel_magenta)
	_alinear_tecla_con_boton(tecla_0_magenta, btn_retardada_magenta, panel_magenta)

	# POSESIÓN
	_alinear_tecla_con_boton(tecla_q_cian, btn_posesion_cian, panel_cian)
	_alinear_tecla_con_boton(tecla_q_magenta, btn_posesion_magenta, panel_magenta)


func _alinear_tecla_con_boton(
	tecla: Label,
	boton: Button,
	panel: Panel
) -> void:
	if tecla == null or boton == null or panel == null:
		return
	
	# Convertimos la posición global del botón al espacio local del panel.
	var boton_pos_local: Vector2 = panel.make_canvas_position_local(boton.global_position)
	
	# La tecla queda a la derecha del botón y centrada verticalmente.
	var separacion := 10.0
	tecla.position = Vector2(
		boton_pos_local.x + boton.size.x + separacion,
		boton_pos_local.y + (boton.size.y - tecla.size.y) * 0.5
	)


# ============================================================
# ACTUALIZAR COOLDOWNS VISUALES
# ============================================================

func actualizar_cooldowns_habilidades() -> void:
	var patos := get_tree().get_nodes_in_group("patos")

	# Restaurar todos los indicadores antes de aplicar cooldowns.
	_restaurar_tecla(tecla_g_cian, "Z")
	_restaurar_tecla(tecla_c_cian, "V")
	_restaurar_tecla(tecla_x_cian, "C")
	_restaurar_tecla(tecla_q_cian, "X")
	_restaurar_tecla(tecla_h_magenta, "H")
	_restaurar_tecla(tecla_n_magenta, "L")
	_restaurar_tecla(tecla_b_magenta, "K")
	_restaurar_tecla(tecla_q_magenta, "J")

	for pato in patos:
		if not is_instance_valid(pato):
			continue

		if pato.player_id == 1:
			_actualizar_tecla_cooldown(tecla_g_cian, pato.cooldown_robot, "Z")
			_actualizar_tecla_cooldown(tecla_c_cian, pato.cooldown_zona_calor, "V")
			_actualizar_tecla_cooldown(tecla_x_cian, pato.cooldown_zona_frio, "C")
			_actualizar_tecla_cooldown(tecla_q_cian, pato.cooldown_posesion, "X")
		else:
			_actualizar_tecla_cooldown(tecla_h_magenta, pato.cooldown_robot, "H")
			_actualizar_tecla_cooldown(tecla_n_magenta, pato.cooldown_zona_calor, "L")
			_actualizar_tecla_cooldown(tecla_b_magenta, pato.cooldown_zona_frio, "K")
			_actualizar_tecla_cooldown(tecla_q_magenta, pato.cooldown_posesion, "J")


func _restaurar_tecla(label: Label, tecla: String) -> void:
	if label == null:
		return

	label.text = tecla
	label.modulate = Color.WHITE


func _actualizar_tecla_cooldown(
	label: Label,
	segundos: float,
	tecla: String
) -> void:
	if label == null or segundos <= 0.0:
		return

	label.text = str(int(ceil(segundos)))
	label.modulate = Color(0.35, 0.35, 0.35, 1.0)


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

	# SHIFT + TECLA: consultar la mutación sin comprarla.
	if event.shift_pressed:
		match event.keycode:
			KEY_1:
				_mostrar_descripcion_rama(1, 0)
				return
			KEY_2:
				_mostrar_descripcion_rama(1, 1)
				return
			KEY_3:
				_mostrar_descripcion_rama(1, 2)
				return
			KEY_8:
				_mostrar_descripcion_rama(2, 0)
				return
			KEY_9:
				_mostrar_descripcion_rama(2, 1)
				return
			KEY_0:
				_mostrar_descripcion_rama(2, 2)
				return

	# TECLA SOLA: comprar la mutación.
	match event.keycode:
		KEY_E:
			panel_cian.visible = not panel_cian.visible
		KEY_O:
			panel_magenta.visible = not panel_magenta.visible

		KEY_1:
			_comprar_rama(1, 0)
		KEY_2:
			_comprar_rama(1, 1)
		KEY_3:
			_comprar_rama(1, 2)

		KEY_8:
			_comprar_rama(2, 0)
		KEY_9:
			_comprar_rama(2, 1)
		KEY_0:
			_comprar_rama(2, 2)



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
		# Compatibilidad: la antigua habilidad FRIO ahora es DISTORSIÓN.
		zona.tipo = ZonaTemperatura.TipoTemperatura.FRIO
		zona.duracion = 8.0
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

func comprar_mutacion(id_jugador: int, tipo_base: String) -> void:
	if estado_actual != EstadoJuego.FASE_INFECCION:
		return
	var mutaciones: Array[String]
	var adn: int
	if id_jugador == 1:
		mutaciones = mutaciones_p1
		adn = adn_cian
	elif id_jugador == 2:
		mutaciones = mutaciones_p2
		adn = adn_magenta
	else:
		return

	if _encontrar_rama(tipo_base, id_jugador).is_empty():
		print("No puedes comprar mutaciones de otra cepa.")
		return
	var siguiente: String = obtener_siguiente_evolucion(tipo_base, mutaciones)
	if siguiente == "":
		print("Esta rama ya está completa o no corresponde a tu cepa.")
		return
	var costo: int = obtener_costo_mutacion(tipo_base, mutaciones)
	if adn < costo:
		print("Jugador ", id_jugador, ": necesita ", costo, " ADN para ", siguiente)
		return
	if id_jugador == 1:
		adn_cian -= costo
		mutaciones_p1.append(siguiente)
	else:
		adn_magenta -= costo
		mutaciones_p2.append(siguiente)
	actualizar_mutaciones_existentes(id_jugador)
	actualizar_menu_mutaciones()
	# Solo suena tras aplicar la compra y descontar el ADN.
	AudioManager.efecto("mutacion_comprada", -11.0, false)
	# Se desbloqueo un nuevo nivel en esta rama.
	if obtener_siguiente_evolucion(tipo_base, mutaciones) != "":
		AudioManager.efecto("mutacion_desbloqueada", -17.0, false)
	print("Jugador ", id_jugador, " compró ", siguiente, " (", costo, " ADN)")


func _encontrar_rama(tipo_base: String, id_jugador: int) -> Array:
	for rama in obtener_ramas_jugador(id_jugador):
		if rama[0] == tipo_base:
			return rama
	return []


func obtener_siguiente_evolucion(tipo_base: String, mutaciones: Array[String]) -> String:
	# Seguridad: sólo reconoce ramas de las cepas disponibles.
	for cepa in TIPOS:
		for rama in RAMAS[cepa]:
			if rama[0] != tipo_base:
				continue
			for mutacion in rama:
				if mutacion not in mutaciones:
					return str(mutacion)
			return ""
	return ""


func obtener_costo_mutacion(tipo_base: String, mutaciones: Array[String]) -> int:
	for cepa in TIPOS:
		for rama in RAMAS[cepa]:
			if rama[0] != tipo_base:
				continue
			var nivel: int = 0
			for mutacion in rama:
				if mutacion in mutaciones:
					nivel += 1
			if nivel == 0:
				return COSTO_BASE
			if nivel == 1:
				return COSTO_EVOLUCION_1
			return COSTO_EVOLUCION_2
	return 999


func actualizar_adn_remontada(delta: float) -> void:
	if estado_actual != EstadoJuego.FASE_INFECCION:
		tiempo_remontada = 0.0
		equipo_remontada = 0
		return

	var stats: Dictionary = contar_infecciones()
	var cian: int = int(stats["blue"])
	var magenta: int = int(stats["magenta"])
	var perdedor: int = 0

	if magenta - cian >= diferencia_minima_remontada:
		perdedor = 1
	elif cian - magenta >= diferencia_minima_remontada:
		perdedor = 2

	if perdedor == 0:
		tiempo_remontada = 0.0
		equipo_remontada = 0
		return

	if perdedor != equipo_remontada:
		equipo_remontada = perdedor
		tiempo_remontada = 0.0

	tiempo_remontada += delta
	while tiempo_remontada >= 1.0:
		tiempo_remontada -= 1.0
		if perdedor == 1:
			adn_cian += adn_por_segundo_remontada
		else:
			adn_magenta += adn_por_segundo_remontada


# Inestabilidad: aumenta SOLO la curacion natural del lider.
# Ofensiva: se activa desde 20 y permanece hasta bajar a 15.
func actualizar_balance_tardio() -> void:
	multiplicador_curacion_cian = 1.0
	multiplicador_curacion_magenta = 1.0
	if estado_actual != EstadoJuego.FASE_INFECCION:
		equipo_curacion_ofensiva = 0
		return

	var stats: Dictionary = contar_infecciones()
	var cian: int = int(stats["blue"])
	var magenta: int = int(stats["magenta"])
	var diferencia: int = absi(cian - magenta)
	var lider: int = 0
	var perdedor: int = 0
	if cian > magenta:
		lider = 1
		perdedor = 2
	elif magenta > cian:
		lider = 2
		perdedor = 1

	var factor: float = 1.0
	if diferencia >= diferencia_inestabilidad_3:
		factor = multiplicador_inestabilidad_3
	elif diferencia >= diferencia_inestabilidad_2:
		factor = multiplicador_inestabilidad_2
	elif diferencia >= diferencia_inestabilidad_1:
		factor = multiplicador_inestabilidad_1
	if lider == 1:
		multiplicador_curacion_cian = factor
	elif lider == 2:
		multiplicador_curacion_magenta = factor

	if equipo_curacion_ofensiva != 0:
		if equipo_curacion_ofensiva != perdedor or diferencia <= diferencia_desactivar_curacion_ofensiva:
			equipo_curacion_ofensiva = 0
	if equipo_curacion_ofensiva == 0 and perdedor != 0 and diferencia >= diferencia_activar_curacion_ofensiva:
		equipo_curacion_ofensiva = perdedor


func obtener_multiplicador_curacion_natural(id_jugador: int) -> float:
	if id_jugador == 1:
		return multiplicador_curacion_cian
	if id_jugador == 2:
		return multiplicador_curacion_magenta
	return 1.0


func sumar_adn(id_jugador: int) -> void:
	if id_jugador == 1:
		adn_cian += 1
		contagios_cian += 1
	elif id_jugador == 2:
		adn_magenta += 1
		contagios_magenta += 1


func aplicar_mutaciones_a_bot(bot: Node2D) -> void:
	if not is_instance_valid(bot) or not bot.is_infected:
		return
	if bot.player_duenio == 1:
		bot.aplicar_mutaciones(mutaciones_p1, cepa_cian)
	elif bot.player_duenio == 2:
		bot.aplicar_mutaciones(mutaciones_p2, cepa_magenta)


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

# ============================================================
# EFECTOS AVANZADOS: NUBES TEMPORALES Y REPLICACIÓN
# ============================================================

func crear_nube_persistente(posicion: Vector2, id_jugador: int, color: Color) -> void:
	var propias: int = 0
	for nube in nubes_activas:
		if nube["jugador"] == id_jugador:
			propias += 1
	if propias >= MAX_NUBES_POR_JUGADOR:
		return

	var poligono := Polygon2D.new()
	poligono.name = "EsporasAmbientales"
	var puntos := PackedVector2Array()
	for i in range(24):
		var angulo: float = TAU * float(i) / 24.0
		puntos.append(Vector2(cos(angulo), sin(angulo)) * RADIO_NUBE_AMBIENTAL)
	poligono.polygon = puntos
	poligono.color = Color(color.r, color.g, color.b, 0.16)
	poligono.z_index = 2
	add_child(poligono)
	poligono.global_position = posicion
	nubes_activas.append({"nodo": poligono, "jugador": id_jugador, "color": color, "duracion": DURACION_NUBE_AMBIENTAL})


func _physics_process(delta: float) -> void:
	if nubes_activas.is_empty():
		return
	for i in range(nubes_activas.size() - 1, -1, -1):
		nubes_activas[i]["duracion"] = float(nubes_activas[i]["duracion"]) - delta
		if float(nubes_activas[i]["duracion"]) <= 0.0:
			var poligono: Node2D = nubes_activas[i]["nodo"]
			if is_instance_valid(poligono):
				poligono.queue_free()
			nubes_activas.remove_at(i)
	reloj_nubes += delta
	if reloj_nubes < 0.5:
		return
	reloj_nubes = 0.0
	var bots = get_tree().get_nodes_in_group("bots")
	for nube in nubes_activas:
		var centro: Node2D = nube["nodo"]
		for nodo in bots:
			if not is_instance_valid(nodo) or not nodo is Node2D:
				continue
			if nodo.is_infected:
				continue
			if centro.global_position.distance_squared_to(nodo.global_position) > RADIO_NUBE_AMBIENTAL * RADIO_NUBE_AMBIENTAL:
				continue
			if randf() < CHANCE_NUBE_AMBIENTAL:
				nodo.infectar(nube["color"], int(nube["jugador"]))


func crear_replicado(origen: Node2D) -> bool:
	if not is_instance_valid(origen) or not origen.is_infected:
		return false
	if obtener_cepa_jugador(origen.player_duenio) != "exponencial":
		return false
	if get_tree().get_nodes_in_group("bots").size() >= MAX_BOTS_TOTALES:
		return false
	var jugador: int = origen.player_duenio
	if jugador == 1 and replicas_cian >= MAX_REPLICAS_POR_JUGADOR:
		return false
	if jugador == 2 and replicas_magenta >= MAX_REPLICAS_POR_JUGADOR:
		return false
	var replicado: Node2D = ESCENA_BOT.instantiate() as Node2D
	if replicado == null:
		return false
	var contenedor: Node = get_node_or_null("Bots")
	if contenedor == null:
		contenedor = self
	contenedor.add_child(replicado)
	replicado.global_position = origen.global_position + Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * 28.0
	# La réplica cuenta como infectado, pero NO da ADN y NO dispara compras.
	replicado.es_replica = true
	replicado.activar_infeccion(origen.color_infeccion, jugador, false)
	if jugador == 1:
		replicas_cian += 1
	else:
		replicas_magenta += 1
	return true


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

	# Detenemos la musica antes de congelar el arbol: AudioManager sigue activo.
	AudioManager.detener_musica()
	if stats.blue != stats.magenta:
		AudioManager.efecto("victoria", -7.0, false)
	else:
		# El empate usa el cierre alternativo (no hay ganador).
		AudioManager.efecto("derrota", -10.0, false)

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


		if bot.player_duenio == 1:

			blue += 1


		elif bot.player_duenio == 2:

			magenta += 1


	return {
		"blue": blue,
		"magenta": magenta
	}
