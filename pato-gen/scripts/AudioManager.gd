
extends Node

const MUSICA_MENU: AudioStream = preload("res://assets/Sonidos/musica/menu_laboratorio.ogg")
const MUSICA_PARTIDA: AudioStream = preload("res://assets/Sonidos/musica/partida_contagio.ogg")
const MOTOR_ROBOT: AudioStream = preload("res://assets/Sonidos/efectos/12_robot_aspiradora_loop.wav")

const EFECTOS: Dictionary = {
	"contagio": preload("res://assets/Sonidos/efectos/01_contagio.wav"),
	"curacion": preload("res://assets/Sonidos/efectos/02_curacion.wav"),
	"mutacion_comprada": preload("res://assets/Sonidos/efectos/03_mutacion_comprada.wav"),
	"mutacion_desbloqueada": preload("res://assets/Sonidos/efectos/04_mutacion_desbloqueada.wav"),
	"bot_sano": preload("res://assets/Sonidos/efectos/05_bot_sano.wav"),
	"bot_infectado": preload("res://assets/Sonidos/efectos/06_bot_infectado.wav"),
	"click": preload("res://assets/Sonidos/efectos/07_ui_click.wav"),
	"seleccion_cepa": preload("res://assets/Sonidos/efectos/08_ui_seleccion_cepa.wav"),
	"atras": preload("res://assets/Sonidos/efectos/09_ui_atras.wav"),
	"victoria": preload("res://assets/Sonidos/efectos/10_victoria.wav"),
	"derrota": preload("res://assets/Sonidos/efectos/11_derrota.wav"),
	"robot_encender": preload("res://assets/Sonidos/efectos/13_robot_aspiradora_encender.wav"),
	"robot_apagar": preload("res://assets/Sonidos/efectos/14_robot_aspiradora_apagar.wav"),
	"pato_desaparecer": preload("res://assets/Sonidos/efectos/15_pato_desaparecer.wav"),
	"alerta_persecucion": preload("res://assets/Sonidos/efectos/16_alerta_persecucion.wav"),
	"escudo_activado": preload("res://assets/Sonidos/efectos/17_escudo_activado.wav")
}

const MAX_EFECTOS_SIMULTANEOS: int = 18
# Limites compartidos por todos los bots: impiden saturacion de audio en batallas grandes.
const INTERVALOS_EFECTO_MS: Dictionary = {
	"contagio": 650,
	"curacion": 220,
	"bot_sano": 500,
	"bot_infectado": 700,
	"alerta_persecucion": 4500,
	"escudo_activado": 900,
	"robot_encender": 250,
	"robot_apagar": 250
}

var _ultimo_efecto_ms: Dictionary = {}

var _musica: AudioStreamPlayer
var _efectos_activos: int = 0


func _ready() -> void:
	# El singleton sigue reproduciendo efectos incluso con Game Over en pausa.
	process_mode = Node.PROCESS_MODE_ALWAYS
	_musica = AudioStreamPlayer.new()
	_musica.name = "Musica"
	_musica.volume_db = -9.0
	add_child(_musica)



func reproducir_menu() -> void:
	_poner_musica(MUSICA_MENU)


func reproducir_partida() -> void:
	_poner_musica(MUSICA_PARTIDA)


func detener_musica() -> void:
	_musica.stop()


func _poner_musica(pista: AudioStream) -> void:
	if _musica.playing and _musica.stream == pista:
		return

	if pista is AudioStreamOggVorbis:
		var ogg := pista as AudioStreamOggVorbis
		ogg.loop = true

	_musica.stop()
	_musica.stream = pista
	_musica.play()


func efecto(nombre: String, volumen_db: float = -9.0, variar_tono: bool = true) -> void:
	if not EFECTOS.has(nombre):
		push_warning("PatoGen: sonido desconocido: " + nombre)
		return

	if _efectos_activos >= MAX_EFECTOS_SIMULTANEOS:
		return

	# Cada evento tiene su propia frecuencia maxima global.
	var intervalo: int = int(INTERVALOS_EFECTO_MS.get(nombre, 0))
	if intervalo > 0:
		var ahora: int = Time.get_ticks_msec()
		var ultimo: int = int(_ultimo_efecto_ms.get(nombre, -100000))
		if ahora - ultimo < intervalo:
			return
		_ultimo_efecto_ms[nombre] = ahora

	var jugador := AudioStreamPlayer.new()
	jugador.stream = EFECTOS[nombre]
	jugador.volume_db = volumen_db

	if variar_tono:
		jugador.pitch_scale = randf_range(0.97, 1.03)

	add_child(jugador)
	_efectos_activos += 1

	jugador.finished.connect(_efecto_terminado.bind(jugador))
	jugador.play()


func _efecto_terminado(jugador: AudioStreamPlayer) -> void:
	_efectos_activos = maxi(0, _efectos_activos - 1)
	jugador.queue_free()


# Crear motor de aspiradora para robot curativo
func crear_motor_robot(padre: Node2D) -> AudioStreamPlayer2D:
	var motor := AudioStreamPlayer2D.new()

	motor.name = "MotorAspiradora"
	motor.stream = MOTOR_ROBOT
	motor.volume_db = -18.0
	# Audibilidad amplia en un mapa de 1920 x 1080.
	motor.max_distance = 2500.0

	padre.add_child(motor)

	return motor
