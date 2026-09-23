@tool
extends Area2D

enum TipoTemperatura { FRIO, CALOR }
@export var tipo: TipoTemperatura = TipoTemperatura.FRIO:
	set(nuevo_tipo):
		tipo = nuevo_tipo
		actualizar_color_visual()

@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	actualizar_color_visual()
	
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)
		body_exited.connect(_on_body_exited)

func actualizar_color_visual() -> void:
	if not has_node("ColorRect"):
		return
		
	color_rect = $ColorRect
	if tipo == TipoTemperatura.FRIO:
		color_rect.color = Color(0.0, 0.4, 1.0, 0.35) # Azul
	elif tipo == TipoTemperatura.CALOR:
		color_rect.color = Color(1.0, 0.2, 0.1, 0.35) # Rojo

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("bots"):
		if tipo == TipoTemperatura.FRIO:
			body.multiplicador_velocidad_temp = 0.6
			body.multiplicador_contagio_temp = 0.7
			body.probabilidad_curacion = 0.001 # 0.1% (Inmortalidad casi total)
			
		elif tipo == TipoTemperatura.CALOR:
			body.multiplicador_velocidad_temp = 1.3
			body.multiplicador_contagio_temp = 2.5 # BROTE MASIVO (87.5% contagio)
			body.probabilidad_curacion = 0.18 # 18% (Riesgo letal alto)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("bots"):
		# Retorno a valores neutros
		body.multiplicador_velocidad_temp = 1.0
		body.multiplicador_contagio_temp = 1.0
		body.probabilidad_curacion = 0.01 # 1% (Resistencia neutra alta)
