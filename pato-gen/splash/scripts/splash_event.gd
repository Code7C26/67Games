extends Node2D
## Infection policy is a hook; production game owns infection data.
signal phase_changed(phase: String, seconds_left: float)
signal attraction_requested(destinations: Array[Vector2], max_visitors: int, duration: float)
signal attraction_finished
signal splash_impact(strength: float)
signal npc_splashed(actor: Node)
signal infection_effect_requested(actor: Node, effect: int, exposure: float)
enum InfectionEffect { NEUTRAL, CLEAN, SPREAD }
@export var enabled := true
@export_group("Fases / segundos")
@export_range(1.0, 120.0, 0.5) var calm_seconds := 30.0
@export_range(0.2, 5.0, 0.1) var warning_seconds := 1.5
@export_range(0.2, 5.0, 0.1) var splash_seconds := 1.5
@export_range(0.2, 5.0, 0.1) var settle_seconds := 1.0
@export_range(0, 12, 1) var max_attracted_visitors := 10
@export_group("Empapado / integracion")
@export_enum("Neutro", "Limpiar", "Propagar") var infection_effect: int = InfectionEffect.NEUTRAL
@export_range(0.0, 1.0, 0.05) var infection_exposure := 1.0
@export_range(1.0, 15.0, 0.5) var soaked_seconds := 6.0
@export var audio_enabled := true
var phase := "calma"
var elapsed := 0.0
var cycles := 0
var paused := false
var chime: AudioStreamPlayer
var impact_sound: AudioStreamPlayer
var cannon: Node2D
var hit_this_cycle: Dictionary = {}

func _ready() -> void:
	cannon = get_node("09_GranChapuzon")
	chime = AudioStreamPlayer.new(); chime.name = "SilbatoGuardavidas"
	chime.stream = load("res://splash/assets/silbato_guardavidas.wav"); chime.volume_db = -17.0; add_child(chime)
	impact_sound = AudioStreamPlayer.new(); impact_sound.name = "SonidoAgua"
	impact_sound.stream = preload("res://splash/assets/chapuzon.wav"); impact_sound.volume_db = -13.0; add_child(impact_sound)
	var legacy: Node2D = get_node_or_null("05_Efectos")
	if legacy: legacy.hide()
	phase_changed.emit(phase, phase_duration())

func phase_duration() -> float:
	match phase:
		"aviso": return maxf(0.2, warning_seconds)
		"chapuzon": return maxf(0.2, splash_seconds)
		"reposo": return maxf(0.2, settle_seconds)
	return maxf(1.0, calm_seconds)

func request_attraction() -> void:
	if phase == "calma" and enabled and not paused: elapsed = phase_duration()

func _process(delta: float) -> void:
	if not enabled or paused: return
	advance_event(delta)

func advance_event(delta: float) -> void:
	elapsed += delta
	while elapsed >= phase_duration():
		elapsed -= phase_duration()
		match phase:
			"calma":
				phase = "aviso"; hit_this_cycle.clear(); cannon.begin_warning(warning_seconds)
				var destinations: Array[Vector2] = []
				for marker_name in ["ChapuzonOeste", "ChapuzonCentro", "ChapuzonEste"]:
					destinations.append(get_node("06_Marcadores/" + marker_name).global_position)
				attraction_requested.emit(destinations, max_attracted_visitors, warning_seconds + splash_seconds + settle_seconds)
				if audio_enabled: chime.play()
			"aviso":
				phase = "chapuzon"; cannon.begin_fire(splash_seconds); splash_impact.emit(1.0)
				if audio_enabled: impact_sound.play()
			"chapuzon": phase = "reposo"; cannon.end_fire(settle_seconds)
			"reposo":
				phase = "calma"; cycles += 1; cannon.finish_event(); attraction_finished.emit()
	phase_changed.emit(phase, maxf(0.0, phase_duration() - elapsed))

func wet_visitor(actor: Node) -> void:
	var id := actor.get_instance_id()
	if hit_this_cycle.has(id): return
	hit_this_cycle[id] = true
	if actor.has_method("become_soaked"): actor.become_soaked(soaked_seconds)
	npc_splashed.emit(actor)
	# Connect to the production infection system. One exposure per actor/event.
	if infection_effect != InfectionEffect.NEUTRAL:
		infection_effect_requested.emit(actor, infection_effect, infection_exposure)
