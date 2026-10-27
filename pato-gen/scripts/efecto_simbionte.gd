extends Node2D
## One lifetime on the existing bot; possession never owns this clock.
const CuracionRadial = preload("res://scripts/curacion_radial.gd")
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
const AspectoSimbionte = preload("res://scripts/aspecto_simbionte.gd")
var aspecto: AnimatedSprite2D
var sprite_original: AnimatedSprite2D
var visibilidad_original := true
var anfitrion: Node2D
var mundo: Node
var equipo: int = 0
var restante: float = 20.0
var factor_velocidad: float = 1.35
var factor_curacion: float = 0.5
var radio_aura: float = 140.0
var chance_aura: float = 0.5
var intervalo_aura: float = 0.75
var hasta_pulso: float = 0.75
var activo := true
var color_equipo := Color.CYAN

func _ready() -> void:
	z_index = 4
	color_equipo = Color("58d8d8") if equipo == 1 else Color("e489ce")
	sprite_original = anfitrion.get_node_or_null("AnimatedSprite2D")
	if is_instance_valid(sprite_original):
		visibilidad_original = sprite_original.visible
		sprite_original.hide()
		aspecto = AspectoSimbionte.new()
		aspecto.name = "Aspecto"
		aspecto.position = sprite_original.position
		aspecto.offset = sprite_original.offset
		aspecto.centered = sprite_original.centered
		aspecto.scale = sprite_original.scale
		add_child(aspecto)
		aspecto.configurar_equipo(equipo)
		aspecto.direccion = sprite_original.animation
		# The liquid wraps the host; gameplay lifetime still begins at contact.
		aspecto.transicionar(&"fusion", true)
	queue_redraw()

func es_valido() -> bool:
	return activo and restante > 0.0 and is_instance_valid(anfitrion) and not anfitrion.is_queued_for_deletion() and anfitrion.is_infected and anfitrion.player_duenio == equipo

func _physics_process(delta: float) -> void:
	if not es_valido() or not is_instance_valid(mundo):
		terminar()
		return
	if mundo.estado_actual == mundo.EstadoJuego.FIN:
		terminar()
		return
	if not mundo.simbionte_en_juego():
		if is_instance_valid(aspecto):
			aspecto.actualizar(Vector2.ZERO, false)
		return
	avanzar(delta)
	if activo and is_instance_valid(aspecto):
		aspecto.actualizar(anfitrion.velocity)

func avanzar(delta: float) -> void:
	if not es_valido():
		terminar()
		return
	restante = maxf(0.0, restante - delta)
	# Expiration precedes any pulse: never heal at/after the 20 second boundary.
	if restante <= 0.0:
		terminar()
		return
	hasta_pulso -= delta
	# Fractional intervals can leave a tiny positive remainder at the boundary.
	if hasta_pulso <= 0.0 or is_zero_approx(hasta_pulso):
		hasta_pulso = intervalo_aura
		CuracionRadial.aplicar(self, radio_aura, chance_aura, equipo)
	queue_redraw()

func terminar() -> void:
	if not activo:
		return
	activo = false
	_restaurar_aspecto()
	if is_instance_valid(anfitrion) and anfitrion.efecto_simbionte == self:
		anfitrion.efecto_simbionte = null
	hide()
	queue_free()

func _exit_tree() -> void:
	_restaurar_aspecto()
	if is_instance_valid(anfitrion) and anfitrion.efecto_simbionte == self:
		anfitrion.efecto_simbionte = null

func _restaurar_aspecto() -> void:
	if is_instance_valid(sprite_original):
		sprite_original.visible = visibilidad_original
		sprite_original = null

func _draw() -> void:
	if not activo:
		return
	draw_circle(Vector2.ZERO, radio_aura, Color(color_equipo, 0.08))
	draw_arc(Vector2.ZERO, radio_aura, 0, TAU, 64, Color(color_equipo, 0.5), 1.5, true)
	# A compact crest distinguishes this aura from possession and infection.
	draw_colored_polygon(PackedVector2Array([Vector2(-13, -30), Vector2(-9, -43), Vector2(0, -36), Vector2(9, -43), Vector2(13, -30)]), color_equipo)
	draw_rect(Rect2(-24, -65, 48, 20), Color("172b36"))
	draw_string(FUENTE, Vector2(-22, -49), "%02ds" % ceili(restante), HORIZONTAL_ALIGNMENT_CENTER, 44, 14, Color.WHITE)
