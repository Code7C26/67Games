
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
@export_range(1.0, 30.0, 0.5) var fps_animacion: float = 12.0

var acumulador_animacion: float = 0.0

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


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if fps_animacion <= 0.0 or sprite.texture == null:
		return

	acumulador_animacion += delta
	var segundos_por_frame: float = 1.0 / fps_animacion
	var total_frames: int = sprite.hframes * sprite.vframes

	while acumulador_animacion >= segundos_por_frame:
		acumulador_animacion -= segundos_por_frame
		sprite.frame = (sprite.frame + 1) % total_frames


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

	var sprite_actual: Sprite2D = $Sprite2D

	# Cada spritesheet contiene 8 columnas y 6 filas (48 frames).
	sprite_actual.hframes = 8
	sprite_actual.vframes = 6

	if tipo == TipoTemperatura.FRIO:
		if sprite_frio != null:
			sprite_actual.texture = sprite_frio
		else:
			sprite_actual.texture = load("res://assets/Zona hipnotica.png")
	elif tipo == TipoTemperatura.CALOR:
		if sprite_calor != null:
			sprite_actual.texture = sprite_calor
		else:
			sprite_actual.texture = load("res://assets/zona_caliente_sheet.png")

	sprite_actual.frame = 0
	acumulador_animacion = 0.0


# ============================================================
# ENTRAR / SALIR
# ============================================================

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("bots"):
		return

	if body not in cuerpos_dentro:
		cuerpos_dentro.append(body)

	reaplicar_zona_o_restablecer(body)


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
		# DISTORSIÓN: sólo atrae bots sanos desde Bot.gd.
		# No cambia estadísticas ni afecta infectados.
		return

	elif tipo == TipoTemperatura.CALOR:
		body.multiplicador_velocidad_temp = 1.3
		body.multiplicador_contagio_temp = 1.8
		body.probabilidad_curacion = 0.65


# ============================================================
# SUPERPOSICIÓN DE ZONAS
# ============================================================

func reaplicar_zona_o_restablecer(body: Node2D) -> void:
	if not is_instance_valid(body) or not body.is_in_group("bots"):
		return

	# La distorsión no debe borrar los efectos de una zona caliente.
	# Recalcular tomando en cuenta las zonas activas con prioridad CALOR.
	restablecer_bot(body)
	for zona in get_tree().get_nodes_in_group("zonas_temperatura"):
		if not is_instance_valid(zona) or not zona is ZonaTemperatura:
			continue
		if zona.tipo != TipoTemperatura.CALOR:
			continue
		if body in zona.cuerpos_dentro:
			zona.aplicar_efecto(body)
			return


func restablecer_bot(body: Node2D) -> void:
	if not is_instance_valid(body):
		return

	body.multiplicador_velocidad_temp = 1.0
	body.multiplicador_contagio_temp = 1.0
	body.probabilidad_curacion = 0.01
