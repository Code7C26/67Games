extends Node2D

signal fase_infeccion_iniciada
var _transicion_iniciada := false
var _patos_pendientes := 0
@onready var interfaz = $HUD_ADN
@onready var evento_coloso: Node = get_node_or_null("EventoColosoAntiviral")

# Optional introduction module. Removing its autoload restores the normal path.
func _enter_tree() -> void:
	# Old editable scenes keep their source nodes intact on disk, but receive the
	# same compatible HUD at runtime before @onready paths are resolved.
	var old_hud := get_node_or_null("HUD_ADN")
	if old_hud and not old_hud.has_method("sync"):
		old_hud.free()
		var replacement := CanvasLayer.new()
		replacement.name = "HUD_ADN"
		replacement.layer = 10
		replacement.set_script(preload("res://scripts/match_hud.gd"))
		add_child(replacement)
	var onboarding := get_node_or_null("/root/PatogenOnboarding")
	if onboarding:
		onboarding.prepare_scene(self)



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

# Stable paths shared with the introduction adapter.
@onready var btn_fiebre_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnFiebre
@onready var btn_cadena_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnCadena
@onready var btn_retardada_cian: Button = $HUD_ADN/PanelCian/VBoxContainer/BtnInfeccion
@onready var btn_fiebre_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnFiebre
@onready var btn_cadena_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnCadena
@onready var btn_retardada_magenta: Button = $HUD_ADN/PanelMagenta/VBoxContainer/BtnInfeccion

# Pantalla de Game Over (Asegúrate de que el nodo en la escena se llame GameOver)
@onready var game_over_screen: CanvasLayer = get_node_or_null("GameOver")


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

# The race belongs to this match, never an autoload or a player/possession.
const PAGO_SIMBIONTE := 5
const META_SIMBIONTE := 60
const COOLDOWN_SIMBIONTE := 1.5
const ESCENA_SIMBIONTE = preload("res://scenes/simbionte.tscn")
const NavegacionSimbionte = preload("res://scripts/navegacion_simbionte.gd")
@export_group("Simbionte")
@export_range(1.0, 3.0, 0.05) var velocidad_fusion: float = 1.35
@export_range(0.0, 1.0, 0.05) var curacion_fusion: float = 0.5
@export var radio_aura_simbionte: float = 140.0
@export_range(0.0, 1.0, 0.05) var chance_aura_simbionte: float = 0.5
@export_range(0.1, 5.0, 0.05) var intervalo_aura_simbionte: float = 0.75
@export var velocidad_simbionte: float = 100.0
@export_group("")
var inversion_simbionte: Array[int] = [0, 0]
var cooldown_simbionte: Array[float] = [0.0, 0.0]
var ganador_simbionte: int = 0
var capullos: Array[Node2D] = []
var capullos_colocados := false
var navegacion_simbionte: Node2D
var simbionte: Node2D

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
	_conectar_botones_mutaciones()
	actualizar_menu_mutaciones()

	timer_inicio.timeout.connect(_on_timer_inicio_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)

	if panel_cian:
		panel_cian.show()

	if panel_magenta:
		panel_magenta.show()

	if game_over_screen:
		game_over_screen.hide()

	# Esperamos a que los Container terminen de calcular el tamaño
	# de los botones antes de colocar las teclas.
	interfaz.setup(self)
	_preparar_simbionte()
	if evento_coloso != null:
		evento_coloso.configurar(self, contar_infecciones())


# ============================================================
# PROCESS
# ============================================================

func _process(delta: float) -> void:
	# One population scan supplies balance, HUD and the environmental event.
	var stats := contar_infecciones()
	actualizar_adn_remontada(delta, stats)
	actualizar_balance_tardio(stats)
	interfaz.sync(stats)
	if evento_coloso != null:
		evento_coloso.poblacion = stats


func actualizar_menu_mutaciones() -> void:
	var botones_cian: Array[Button] = [btn_fiebre_cian, btn_cadena_cian, btn_retardada_cian]
	var botones_magenta: Array[Button] = [btn_fiebre_magenta, btn_cadena_magenta, btn_retardada_magenta]
	for i in range(3):
		_actualizar_boton_rama(botones_cian[i], 1, i)
		_actualizar_boton_rama(botones_magenta[i], 2, i)


func _actualizar_boton_rama(boton: Button, id_jugador: int, indice_rama: int) -> void:
	var ramas: Array = obtener_ramas_jugador(id_jugador)
	if indice_rama >= ramas.size():
		boton.text = "PRÓXIMAMENTE\nRama en desarrollo"

		boton.disabled = true
		return
	var mutaciones: Array[String] = mutaciones_p1 if id_jugador == 1 else mutaciones_p2
	var adn: int = adn_cian if id_jugador == 1 else adn_magenta
	var base: String = str(ramas[indice_rama][0])
	var siguiente: String = obtener_siguiente_evolucion(base, mutaciones)
	if siguiente == "":
		boton.text = _nombre_mutacion(str(ramas[indice_rama].back())) + "\nRAMA COMPLETA"
		boton.disabled = true

		return
	var costo: int = obtener_costo_mutacion(base, mutaciones)
	boton.text = _nombre_mutacion(siguiente) + "\n" + str(costo) + " ADN"

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


func _mostrar_descripcion_rama(id_jugador: int, indice_rama: int) -> void:
	interfaz.show_branch(id_jugador, indice_rama)


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
		KEY_Q:
			if not event.shift_pressed:
				accion_simbionte(1)
		KEY_U:
			if not event.shift_pressed:
				accion_simbionte(2)
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

	if not gastar_adn(id_jugador, COSTO_ZONA_TEMPERATURA):
		zona.queue_free()
		return false

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

	if not gastar_adn(id_jugador, COSTO_ROBOT):
		robot.queue_free()
		return false

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
	if not gastar_adn(id_jugador, costo):
		return
	mutaciones.append(siguiente)
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


func actualizar_adn_remontada(delta: float, stats: Dictionary) -> void:
	if estado_actual != EstadoJuego.FASE_INFECCION:
		tiempo_remontada = 0.0
		equipo_remontada = 0
		return

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
func actualizar_balance_tardio(stats: Dictionary) -> void:
	multiplicador_curacion_cian = 1.0
	multiplicador_curacion_magenta = 1.0
	if estado_actual != EstadoJuego.FASE_INFECCION:
		equipo_curacion_ofensiva = 0
		return

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


func obtener_adn(id_jugador: int) -> int:
	if id_jugador == 1:
		return adn_cian
	if id_jugador == 2:
		return adn_magenta
	return 0


func gastar_adn(id_jugador: int, cantidad: int) -> bool:
	if estado_actual != EstadoJuego.FASE_INFECCION or id_jugador not in [1, 2] or cantidad <= 0:
		return false
	if obtener_adn(id_jugador) < cantidad:
		return false
	if id_jugador == 1:
		adn_cian -= cantidad
	else:
		adn_magenta -= cantidad
	return true


func _preparar_simbionte() -> void:
	# Historical scenes can use this controller without adopting the mechanic.
	var cian := get_node_or_null("Simbiontes/CapulloCian") as Node2D
	var magenta := get_node_or_null("Simbiontes/CapulloMagenta") as Node2D
	if cian == null or magenta == null:
		return
	capullos.assign([cian, magenta])
	for capullo in capullos:
		capullo.hide()
	navegacion_simbionte = NavegacionSimbionte.new()
	navegacion_simbionte.name = "NavegacionSimbionte"
	navegacion_simbionte.limites = get_meta("bounds", Rect2(0, 80, 2128, 960))
	navegacion_simbionte.preparada.connect(_colocar_capullos, CONNECT_ONE_SHOT)
	add_child(navegacion_simbionte)


func _colocar_capullos() -> void:
	if ganador_simbionte != 0 or estado_actual == EstadoJuego.FIN:
		return
	for capullo in capullos:
		if not is_instance_valid(capullo) or capullo.is_queued_for_deletion():
			return
	# The original spawn anchors the reachable interior, excluding exterior islands.
	navegacion_simbionte.preparar_posiciones_capullos(capullos[0].global_position)
	var posiciones: PackedVector2Array = navegacion_simbionte.sortear_posiciones_capullos()
	if posiciones.size() != 2:
		push_warning("No hay dos ubicaciones seguras para los capullos; se bloquea la inversión.")
		return
	for i in range(2):
		capullos[i].global_position = posiciones[i]
		capullos[i].show()
	capullos_colocados = true


func simbionte_en_juego() -> bool:
	# The tutorial can hold TimerJuego without pausing the tree.
	return is_inside_tree() and estado_actual == EstadoJuego.FASE_INFECCION and not get_tree().paused and not timer_juego.paused and not timer_juego.is_stopped()


func accion_simbionte(id_jugador: int) -> bool:
	if not simbionte_en_juego() or id_jugador not in [1, 2]:
		return false
	if ganador_simbionte == 0:
		return invertir_simbionte(id_jugador)
	if ganador_simbionte != id_jugador:
		return false
	# The traveller is freed on contact; the live effect belongs to its actual host.
	for bot in get_tree().get_nodes_in_group("bots"):
		if not is_instance_valid(bot) or bot.is_queued_for_deletion() or not is_ancestor_of(bot):
			continue
		var efecto: Node2D = bot.efecto_simbionte
		if not is_instance_valid(efecto) or efecto.mundo != self or efecto.equipo != id_jugador or not efecto.es_valido():
			continue
		for pato in get_tree().get_nodes_in_group("patos"):
			if is_instance_valid(pato) and not pato.is_queued_for_deletion() and is_ancestor_of(pato) and pato.player_id == id_jugador:
				return pato.intentar_poseer_simbionte(bot)
	return false


func invertir_simbionte(id_jugador: int) -> bool:
	if not simbionte_en_juego() or ganador_simbionte != 0 or id_jugador not in [1, 2]:
		return false
	if not capullos_colocados or capullos.size() != 2 or not is_instance_valid(navegacion_simbionte):
		return false
	var indice := id_jugador - 1
	var capullo := capullos[indice]
	if not is_instance_valid(capullo) or capullo.is_queued_for_deletion() or cooldown_simbionte[indice] > 0.0:
		return false
	if inversion_simbionte[indice] >= META_SIMBIONTE or obtener_adn(id_jugador) < PAGO_SIMBIONTE:
		return false
	# Prepare the last purchase before charging. No await or deferred commitment.
	var viajero: Node2D = null
	if inversion_simbionte[indice] + PAGO_SIMBIONTE == META_SIMBIONTE:
		viajero = ESCENA_SIMBIONTE.instantiate()
		if viajero == null:
			return false
	if not gastar_adn(id_jugador, PAGO_SIMBIONTE):
		if viajero != null:
			viajero.free()
		return false
	inversion_simbionte[indice] += PAGO_SIMBIONTE
	cooldown_simbionte[indice] = COOLDOWN_SIMBIONTE
	if viajero != null:
		# First accepted final payment wins even if both inputs arrive this frame.
		ganador_simbionte = id_jugador
		viajero.equipo = id_jugador
		viajero.mundo = self
		viajero.navegacion = navegacion_simbionte
		viajero.velocidad = velocidad_simbionte
		viajero.position = to_local(capullo.global_position)
		simbionte = viajero
		add_child(viajero)
		for huevo in capullos:
			if is_instance_valid(huevo):
				huevo.hide()
				huevo.queue_free()
	return true


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
	if simbionte_en_juego():
		for i in range(2):
			cooldown_simbionte[i] = maxf(0.0, cooldown_simbionte[i] - delta)
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
	if _transicion_iniciada or estado_actual != EstadoJuego.FASE_PATOS:
		return
	_transicion_iniciada = true
	timer_inicio.stop()
	var patos := get_tree().get_nodes_in_group("patos")
	for pato in patos:
		if is_ancestor_of(pato) and not pato.modo_fantasma:
			_patos_pendientes += 1
			pato.fantasma_activado.connect(_pato_listo, CONNECT_ONE_SHOT)
	for pato in patos:
		if is_ancestor_of(pato):
			pato.infectar_y_desaparecer()
	if _patos_pendientes == 0:
		_comenzar_fase_infeccion()


func _pato_listo() -> void:
	_patos_pendientes -= 1
	if _patos_pendientes == 0:
		_comenzar_fase_infeccion()


func _comenzar_fase_infeccion() -> void:
	if estado_actual != EstadoJuego.FASE_PATOS:
		return
	estado_actual = EstadoJuego.FASE_INFECCION
	timer_juego.start()
	fase_infeccion_iniciada.emit()


func _on_timer_juego_timeout() -> void:

	estado_actual = EstadoJuego.FIN
	timer_juego.stop()
	if evento_coloso != null:
		evento_coloso.finalizar()
	# Remove powers before the paused result screen; never leave a live aura.
	for bot in get_tree().get_nodes_in_group("bots"):
		if is_ancestor_of(bot) and bot.has_method("quitar_simbionte"):
			bot.quitar_simbionte()
	if is_instance_valid(simbionte):
		simbionte.queue_free()

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
	var sanos: int = 0
	var total: int = 0


	for bot in bots:
		if not is_instance_valid(bot) or bot.is_queued_for_deletion() or not is_ancestor_of(bot):
			continue
		total += 1
		if not bot.is_infected:
			sanos += 1
			continue


		if bot.player_duenio == 1:

			blue += 1


		elif bot.player_duenio == 2:

			magenta += 1


	return {
		"blue": blue,
		"magenta": magenta,
		"sanos": sanos,
		"total": total
	}
