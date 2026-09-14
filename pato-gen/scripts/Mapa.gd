extends Node2D

@onready var timer_inicio: Timer = $TimerInicio
@onready var timer_juego: Timer = $TimerJuego
@onready var label_contador: Label = $HUD/LabelContador

@onready var label_adn_cian: Label = $HUD_ADN/LabelADN_Cian
@onready var label_adn_magenta: Label = $HUD_ADN/LabelADN_Magenta

# Referencias a los Paneles
@onready var panel_cian: Panel = $HUD_ADN/PanelCian
@onready var panel_magenta: Panel = $HUD_ADN/PanelMagenta

enum EstadoJuego { FASE_PATOS, FASE_INFECCION, FIN }
var estado_actual: EstadoJuego = EstadoJuego.FASE_PATOS

var adn_cian: int = 0
var adn_magenta: int = 0

# Multiplicadores de mutación acumulados
var radio_p1: float = 1.0
var velocidad_p1: float = 1.0

var radio_p2: float = 1.0
var velocidad_p2: float = 1.0

func _ready() -> void:
	timer_inicio.timeout.connect(_on_timer_inicio_timeout)
	timer_juego.timeout.connect(_on_timer_juego_timeout)
	
	if panel_cian: panel_cian.hide()
	if panel_magenta: panel_magenta.hide()

func _process(_delta: float) -> void:
	label_adn_cian.text = "ADN Cian: " + str(adn_cian) + " [E: Menú]"
	label_adn_magenta.text = "ADN Mag: " + str(adn_magenta) + " [O: Menú]"
	
	label_adn_cian.modulate = Color.GREEN if adn_cian >= 5 else Color.WHITE
	label_adn_magenta.modulate = Color.GREEN if adn_magenta >= 5 else Color.WHITE

	if estado_actual == EstadoJuego.FASE_PATOS:
		var tiempo = ceil(timer_inicio.time_left)
		label_contador.text = "¡A infectar!\n" + str(tiempo)
		
	elif estado_actual == EstadoJuego.FASE_INFECCION:
		var tiempo = ceil(timer_juego.time_left)
		var stats = contar_infecciones()
		label_contador.text = "Tiempo: " + str(tiempo) + "s\n[Cian: " + str(stats.cian) + "]   [Magenta: " + str(stats.magenta) + "]"

func _unhandled_input(event: InputEvent) -> void:
	if estado_actual != EstadoJuego.FASE_INFECCION:
		return
		
	if event is InputEventKey and event.pressed and not event.echo:
		# --- CONTROLES JUGADOR 1 (CIAN) ---
		if event.keycode == KEY_E and panel_cian:
			panel_cian.visible = not panel_cian.visible
		elif event.keycode == KEY_1:
			comprar_mutacion(1, "radio")
		elif event.keycode == KEY_2:
			comprar_mutacion(1, "velocidad")
			
		# --- CONTROLES JUGADOR 2 (MAGENTA) ---
		if event.keycode == KEY_O and panel_magenta:
			panel_magenta.visible = not panel_magenta.visible
		elif event.keycode == KEY_9:
			comprar_mutacion(2, "radio")
		elif event.keycode == KEY_0:
			comprar_mutacion(2, "velocidad")

func comprar_mutacion(id_jugador: int, tipo: String) -> void:
	var costo = 5
	
	if id_jugador == 1 and adn_cian >= costo:
		adn_cian -= costo
		if tipo == "radio": radio_p1 *= 1.5
		elif tipo == "velocidad": velocidad_p1 *= 1.5
		actualizar_mutaciones_existentes(1)
		print("J1 compró mutación:", tipo)
		
	elif id_jugador == 2 and adn_magenta >= costo:
		adn_magenta -= costo
		if tipo == "radio": radio_p2 *= 1.5
		elif tipo == "velocidad": velocidad_p2 *= 1.5
		actualizar_mutaciones_existentes(2)
		print("J2 compró mutación:", tipo)

func sumar_adn(id_jugador: int) -> void:
	if id_jugador == 1:
		adn_cian += 1
	elif id_jugador == 2:
		adn_magenta += 1

func aplicar_mutaciones_a_bot(bot: Node2D) -> void:
	if bot.player_duenio == 1:
		bot.aplicar_mutaciones(radio_p1, velocidad_p1)
	elif bot.player_duenio == 2:
		bot.aplicar_mutaciones(radio_p2, velocidad_p2)

func actualizar_mutaciones_existentes(id_jugador: int) -> void:
	var bots = get_tree().get_nodes_in_group("bots")
	for bot in bots:
		if bot.is_infected and bot.player_duenio == id_jugador:
			aplicar_mutaciones_a_bot(bot)

func _on_timer_inicio_timeout() -> void:
	var patos = get_tree().get_nodes_in_group("patos")
	for pato in patos:
		if is_instance_valid(pato):
			pato.infectar_y_desaparecer()
	
	estado_actual = EstadoJuego.FASE_INFECCION
	timer_juego.start()

func _on_timer_juego_timeout() -> void:
	estado_actual = EstadoJuego.FIN
	timer_juego.stop()
	get_tree().paused = true
	
	var stats = contar_infecciones()
	if stats.cian > stats.magenta:
		label_contador.text = "¡GANÓ EL JUGADOR CIAN!\n(Infectados: " + str(stats.cian) + ")"
	elif stats.magenta > stats.cian: # <-- ACÁ ESTABA EL ERROR (decía stats.magenta > stats.magenta)
		label_contador.text = "¡GANÓ EL JUGADOR MAGENTA!\n(Infectados: " + str(stats.magenta) + ")"
	else:
		label_contador.text = "¡EMPATE TÉCNICO!"

func contar_infecciones() -> Dictionary:
	var bots = get_tree().get_nodes_in_group("bots")
	var cian = 0
	var magenta = 0
	
	for bot in bots:
		if bot.is_infected:
			if bot.color_infeccion.is_equal_approx(Color.CYAN):
				cian += 1
			elif bot.color_infeccion.is_equal_approx(Color.MAGENTA):
				magenta += 1
				
	return {"cian": cian, "magenta": magenta}
