# PatoGen — AudioManager.gd (Godot 4)
# Autoload opcional: Proyecto > Ajustes del proyecto > Globales > Autocarga
# Nombre del autoload: AudioManager
# Copiar las carpetas audio/ e integracion/ a res://
extends Node

const MUSICA_MENU: AudioStream = preload("res://audio/musica/menu_laboratorio.ogg")
const MUSICA_PARTIDA: AudioStream = preload("res://audio/musica/partida_contagio.ogg")
const MOTOR_ROBOT: AudioStream = preload("res://audio/efectos/12_robot_aspiradora_loop.wav")

const EFECTOS: Dictionary = {
    "contagio": preload("res://audio/efectos/01_contagio.wav"),
    "curacion": preload("res://audio/efectos/02_curacion.wav"),
    "mutacion_comprada": preload("res://audio/efectos/03_mutacion_comprada.wav"),
    "mutacion_desbloqueada": preload("res://audio/efectos/04_mutacion_desbloqueada.wav"),
    "bot_sano": preload("res://audio/efectos/05_bot_sano.wav"),
    "bot_infectado": preload("res://audio/efectos/06_bot_infectado.wav"),
    "click": preload("res://audio/efectos/07_ui_click.wav"),
    "seleccion_cepa": preload("res://audio/efectos/08_ui_seleccion_cepa.wav"),
    "atras": preload("res://audio/efectos/09_ui_atras.wav"),
    "victoria": preload("res://audio/efectos/10_victoria.wav"),
    "derrota": preload("res://audio/efectos/11_derrota.wav"),
    "robot_encender": preload("res://audio/efectos/13_robot_aspiradora_encender.wav"),
    "robot_apagar": preload("res://audio/efectos/14_robot_aspiradora_apagar.wav"),
    "pato_desaparecer": preload("res://audio/efectos/15_pato_desaparecer.wav"),
    "alerta_persecucion": preload("res://audio/efectos/16_alerta_persecucion.wav"),
    "escudo_activado": preload("res://audio/efectos/17_escudo_activado.wav")
}

const MAX_EFECTOS_SIMULTANEOS: int = 18
const MIN_MS_ENTRE_CONTAGIOS: int = 110

var _musica: AudioStreamPlayer
var _efectos_activos: int = 0
var _ultimo_contagio_ms: int = -100000


func _ready() -> void:
    _musica = AudioStreamPlayer.new()
    _musica.name = "Musica"
    _musica.volume_db = -9.0
    add_child(_musica)

    # Activar loop del motor en la resource WAV importada.
    if MOTOR_ROBOT is AudioStreamWAV:
        var robot_wav := MOTOR_ROBOT as AudioStreamWAV
        robot_wav.loop_mode = AudioStreamWAV.LOOP_FORWARD


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

    # Evita que decenas de infecciones en un mismo frame saturen el sonido.
    if nombre == "contagio":
        var ahora := Time.get_ticks_msec()
        if ahora - _ultimo_contagio_ms < MIN_MS_ENTRE_CONTAGIOS:
            return
        _ultimo_contagio_ms = ahora

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


# Devuelve un reproductor espacial para conectarlo al robot de curacion.
# Luego hacer: motor.play() al activar y motor.stop() al desactivar.
func crear_motor_robot(padre: Node2D) -> AudioStreamPlayer2D:
    var motor := AudioStreamPlayer2D.new()
    motor.name = "MotorAspiradora"
    motor.stream = MOTOR_ROBOT
    motor.volume_db = -15.0
    motor.max_distance = 500.0
    padre.add_child(motor)
    return motor
