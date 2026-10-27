extends Node
## Public adapter contract. Capabilities are opt-in, never assumed.
## The host emits facts AFTER successful gameplay actions (not key presses).
signal fact(event: String, payload: Dictionary)
var capabilities: Dictionary = {}
var world: Node
var gameplay_camera: Camera2D
var duck: Node2D
var focus_infected: Node2D

func supports(feature: String) -> bool:
	return bool(capabilities.get(feature, false))

func can_tutorial_start() -> bool:
	return true

func protected_controls() -> Array[Control]:
	return []

func notify(event: String, payload: Dictionary = {}) -> void:
	fact.emit(event, payload)

func begin_cinematic() -> void:
	pass

func play_outbreak() -> void:
	pass

func release_cinematic() -> void:
	pass

func tutorial_started() -> void:
	pass

func cleanup() -> void:
	pass

func cancel() -> void:
	cleanup()

func mutation_info() -> Dictionary:
	return {}

func highlight_target(_key: String) -> Node:
	return null

func controls_text() -> String:
	return "Consultá los controles configurados en el menú del juego."

func objective_text() -> String:
	return "Extendé la infección y elegí cómo evolucionar el patógeno."
