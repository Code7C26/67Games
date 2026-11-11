extends "res://scripts/Bot.gd"
## Test-only observation of the production arrival and ordinary contagion paths.
var intentos_llegada := 0
var contagios_invocados := 0

func intentar_contagio_garfio(presa: Node2D, bono: float = 0.0) -> bool:
	intentos_llegada += 1
	return super.intentar_contagio_garfio(presa, bono)

func _contagiar_objetivo(presa: Node2D) -> void:
	contagios_invocados += 1
	super._contagiar_objetivo(presa)
