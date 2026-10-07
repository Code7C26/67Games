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

		# Si la escena ya está lista, actualizamos inmediatamente.
		# Si todavía se está creando, _ready() lo hará después.
		if is_node_ready():
			actualizar_color_visual()


@export var duracion: float = 20.0

var cuerpos_dentro: Array[Node2D] = []

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	actualizar_color_visual()

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

	# Sacamos esta zona del grupo ANTES de recalcular efectos.
	# Así, al desaparecer, se pueden encontrar correctamente
	# las otras zonas que todavía sigan activas.
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

func actualizar_color_visual() -> void:
	if not has_node("ColorRect"):
		return

	color_rect = $ColorRect

	if tipo == TipoTemperatura.FRIO:
		color_rect.color = Color(0.0, 0.4, 1.0, 0.35)
	else:
		color_rect.color = Color(1.0, 0.2, 0.1, 0.35)


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
		body.multiplicador_contagio_temp = 2
		body.probabilidad_curacion = 0.48


# Si hay otra zona debajo del bot, conserva su efecto.
# Solo vuelve a valores normales si ya no está dentro de ninguna.
func reaplicar_zona_o_restablecer(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	var otra_zona_encontrada := false

	var zonas = get_tree().get_nodes_in_group("zonas_temperatura")

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
