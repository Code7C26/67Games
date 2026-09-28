
@tool
extends Area2D

# Tipos de temperatura disponibles para la zona
enum TipoTemperatura { FRIO, CALOR }

# Define si la zona es fría o caliente
@export var tipo: TipoTemperatura = TipoTemperatura.FRIO:
	set(nuevo_tipo):
		tipo = nuevo_tipo
		actualizar_color_visual()

# Referencia al rectángulo que muestra visualmente la zona
@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	# Actualiza el color según el tipo de temperatura
	actualizar_color_visual()
	
	# Conecta las señales solamente durante el juego
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)


# Cambia el color visual de la zona según su temperatura
func actualizar_color_visual() -> void:
	if not has_node("ColorRect"):
		return
		
	color_rect = $ColorRect
	
	# Azul para representar el frío
	if tipo == TipoTemperatura.FRIO:
		color_rect.color = Color(0.0, 0.4, 1.0, 0.35) # Azul
	
	# Rojo para representar el calor
	elif tipo == TipoTemperatura.CALOR:
		color_rect.color = Color(1.0, 0.2, 0.1, 0.35) # Rojo


# Aplica los efectos de temperatura cuando un bot entra
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bots"):
		
		# Efectos de la zona fría
		if tipo == TipoTemperatura.FRIO:
			body.multiplicador_velocidad_temp = 0.6
			body.multiplicador_contagio_temp = 0.7
			body.probabilidad_curacion = 0.001 # 0.1% (Inmortalidad casi total)
		
		# Efectos de la zona caliente
		elif tipo == TipoTemperatura.CALOR:
			body.multiplicador_velocidad_temp = 1.3
			body.multiplicador_contagio_temp = 2.5 # BROTE MASIVO (87.5% contagio)
			body.probabilidad_curacion = 0.18 # 18% (Riesgo letal alto)


# Restablece los valores normales cuando el bot sale
func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("bots"):
		# Retorno a valores neutros
		body.multiplicador_velocidad_temp = 1.0
		body.multiplicador_contagio_temp = 1.0
		body.probabilidad_curacion = 0.01 # 1% (Resistencia neutra alta)
