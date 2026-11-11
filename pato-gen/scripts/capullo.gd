extends Node2D
## Presentation only: money, cooldowns and winner live on the match controller.
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
const AspectoCapullo = preload("res://scripts/aspecto_capullo.gd")
const Equipos = preload("res://scripts/equipos_infeccion.gd")
@export_range(1, 2) var equipo: int = 1
var mundo: Node
var color_equipo := Color("528dff")
var despedido := false
@onready var aspecto: AnimatedSprite2D = $Aspecto

func _ready() -> void:
	mundo = get_parent().get_parent()
	color_equipo = Equipos.color_equipo(equipo)
	z_index = 4
	aspecto.mundo = mundo
	aspecto.configurar_equipo(equipo)
	queue_redraw()

func _process(_delta: float) -> void:
	if is_instance_valid(mundo):
		aspecto.inquieto = mundo.inversion_simbionte[equipo - 1] >= mundo.META_SIMBIONTE * 0.75
	queue_redraw()

func recibir_inversion() -> void:
	aspecto.inquieto = mundo.inversion_simbionte[equipo - 1] >= mundo.META_SIMBIONTE * 0.75
	aspecto.latir()

func despedir(gano: bool) -> void:
	if despedido or not is_instance_valid(mundo):
		return
	despedido = true
	var resto = AspectoCapullo.new()
	resto.name = "EclosionCapullo" if gano else "CapulloMarchito"
	resto.mundo = mundo
	resto.z_index = z_index
	mundo.add_child(resto)
	resto.global_transform = aspecto.global_transform
	resto.offset = aspecto.offset
	resto.configurar_equipo(equipo)
	resto.finalizar(gano)

func _draw() -> void:
	if not is_instance_valid(mundo):
		return
	var progreso: int = mundo.inversion_simbionte[equipo - 1]
	var cooldown: float = mundo.cooldown_simbionte[equipo - 1]
	var listo: bool = mundo.simbionte_en_juego() and cooldown <= 0.0 and mundo.obtener_adn(equipo) >= mundo.PAGO_SIMBIONTE
	draw_rect(Rect2(-17, 14, 34, 4), Color(0.02, 0.04, 0.06, 0.32))
	draw_rect(Rect2(-30, 23, 60, 5), Color("18212d"))
	draw_rect(Rect2(-30, 23, 60.0 * progreso / mundo.META_SIMBIONTE, 5), color_equipo)
	var tecla := "Q" if equipo == 1 else "U"
	var estado := "%s · +%d ADN" % [tecla, mundo.PAGO_SIMBIONTE]
	if not mundo.simbionte_en_juego():
		estado = "EN ESPERA"
	elif cooldown > 0.0:
		estado = "%s · %.1fs" % [tecla, cooldown]
	var titulo := Rect2(-96, -76, 192, 34)
	var accion := Rect2(-82, 33, 164, 22)
	if mundo.has_meta("bounds"):
		var limites: Rect2 = mundo.get_meta("bounds")
		var punto: Vector2 = mundo.to_local(global_position)
		# Keep larger cards inside the map even at a randomized edge placement.
		titulo.position.x = clampf(punto.x - 96, limites.position.x + 4, limites.end.x - 196) - punto.x
		accion.position.x = clampf(punto.x - 82, limites.position.x + 4, limites.end.x - 168) - punto.x
		if punto.y - 76 < limites.position.y + 4:
			titulo.position.y = 64
		if punto.y + 55 > limites.end.y - 4:
			accion.position.y = -105
	draw_rect(titulo, Color("172b36"))
	draw_rect(titulo, Color(color_equipo, 0.7), false, 1.0)
	if titulo.position.y < 0:
		draw_line(titulo.position + Vector2(96, 34), Vector2(0, -35), color_equipo, 2.0, true)
	draw_string(FUENTE, titulo.position + Vector2(4, 15), "HUEVO SIMBIONTE", HORIZONTAL_ALIGNMENT_CENTER, 184, 11, color_equipo)
	draw_string(FUENTE, titulo.position + Vector2(4, 29), "%d / %d ADN" % [progreso, mundo.META_SIMBIONTE], HORIZONTAL_ALIGNMENT_CENTER, 184, 10, Color.WHITE)
	draw_rect(accion, Color("172b36"))
	draw_rect(accion, Color(color_equipo, 0.55), false, 1.0)
	draw_string(FUENTE, accion.position + Vector2(4, 16), estado, HORIZONTAL_ALIGNMENT_CENTER, 156, 12, Color.WHITE if listo else Color("a5b6bc"))
