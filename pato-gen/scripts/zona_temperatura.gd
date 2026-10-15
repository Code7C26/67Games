
@tool
class_name ZonaTemperatura
extends Area2D

enum TipoTemperatura {
	FRIO,
	CALOR
}

@export var tipo: TipoTemperatura = TipoTemperatura.FRIO:
	set(nuevo_tipo):
		tipo = nuevo_tipo
		if is_node_ready():
			actualizar_visual()

# Arrastrá las imágenes desde Godot al Inspector.
@export var sprite_frio: Texture2D:
	set(nueva_textura):
		sprite_frio = nueva_textura
		if is_node_ready():
			actualizar_visual()

@export var sprite_calor: Texture2D:
	set(nueva_textura):
		sprite_calor = nueva_textura
		if is_node_ready():
			actualizar_visual()

@export var duracion: float = 20.0

var cuerpos_dentro: Array[Node2D] = []

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	actualizar_visual()

	if Engine.is_editor_hint():
		return

	add_to_group("zonas_temperatura")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	iniciar_duracion()


# ============================================================
# DURACIÓN
# ============================================================

func iniciar_duracion() -> void:
	await get_tree().create_timer(duracion).timeout

	if not is_inside_tree():
		return

	remove_from_group("zonas_temperatura")

	var cuerpos_a_revisar := cuerpos_dentro.duplicate()
	cuerpos_dentro.clear()

	for body in cuerpos_a_revisar:
		if is_instance_valid(body) and body.is_in_group("bots"):
			reaplicar_zona_o_restablecer(body)

	queue_free()


# ============================================================
# VISUAL
# ============================================================

func actualizar_visual() -> void:
	if not has_node("Sprite2D"):
		return

	var sprite: Sprite2D = $Sprite2D

	if tipo == TipoTemperatura.FRIO:
		sprite.texture = load("res://assets/Zona fria.png")

	elif tipo == TipoTemperatura.CALOR:
		sprite.texture = load("res://assets/Zona caliente.png")


# ============================================================
# ENTRAR / SALIR
# ============================================================

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("bots"):
		return

	if body not in cuerpos_dentro:
		cuerpos_dentro.append(body)

	aplicar_efecto(body)


func _on_body_exited(body: Node2D) -> void:
	if not body.is_in_group("bots"):
		return

	cuerpos_dentro.erase(body)
	reaplicar_zona_o_restablecer(body)


# ============================================================
# EFECTOS
# ============================================================

func aplicar_efecto(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	if not body.is_in_group("bots"):
		return

	if tipo == TipoTemperatura.FRIO:
		body.multiplicador_velocidad_temp = 0.6
		body.multiplicador_contagio_temp = 0.7
		body.probabilidad_curacion = 0.001

	elif tipo == TipoTemperatura.CALOR:
		body.multiplicador_velocidad_temp = 1.3
		body.multiplicador_contagio_temp = 1.8
		body.probabilidad_curacion = 0.65


# ============================================================
# SUPERPOSICIÓN DE ZONAS
# ============================================================

func reaplicar_zona_o_restablecer(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	var otra_zona_encontrada := false

	var zonas = get_tree().get_nodes_in_group(
		"zonas_temperatura"
	)

	for zona in zonas:
		if zona == self:
			continue

		if not is_instance_valid(zona):
			continue

		if not zona is ZonaTemperatura:
			continue

		if body in zona.cuerpos_dentro:
			zona.aplicar_efecto(body)
			otra_zona_encontrada = true
			break

	if not otra_zona_encontrada:
		restablecer_bot(body)


func restablecer_bot(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	body.multiplicador_velocidad_temp = 1.0
	body.multiplicador_contagio_temp = 1.0
	body.probabilidad_curacion = 0.01
