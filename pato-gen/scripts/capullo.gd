extends Node2D
## Presentation only: money, cooldowns and winner live on the match controller.
const FUENTE = preload("res://Fuentes/press-start-2p.ttf")
@export_range(1, 2) var equipo: int = 1
var mundo: Node
var color_equipo := Color.CYAN
var pulso := 0.0

func _ready() -> void:
	mundo = get_parent().get_parent()
	color_equipo = Color("58d8d8") if equipo == 1 else Color("e489ce")
	z_index = 4
	queue_redraw()

func _process(delta: float) -> void:
	pulso += delta
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(mundo):
		return
	var progreso: int = mundo.inversion_simbionte[equipo - 1]
	var cooldown: float = mundo.cooldown_simbionte[equipo - 1]
	var listo: bool = mundo.simbionte_en_juego() and cooldown <= 0.0 and mundo.obtener_adn(equipo) >= mundo.PAGO_SIMBIONTE
	var escala: float = 1.0 + sin(pulso * 2.4) * 0.025
	draw_circle(Vector2(0, 13), 23, Color(0.02, 0.06, 0.1, 0.5))
	var huevo := PackedVector2Array()
	for i in range(40):
		var angulo := TAU * float(i) / 40.0
		huevo.append(Vector2(cos(angulo) * (17.0 + sin(angulo) * 3.0), sin(angulo) * 25.0) * escala)
	draw_colored_polygon(huevo, Color("172b36"))
	huevo.append(huevo[0])
	draw_polyline(huevo, color_equipo, 2.0, true)
	for lado in [-1, 1]:
		var vena := PackedVector2Array([Vector2(lado * 12, 12), Vector2(lado * 5, 2), Vector2(lado * 11, -8), Vector2(lado * 3, -19)])
		draw_polyline(vena, Color(color_equipo, 0.65), 2.0, true)
	draw_circle(Vector2(0, -1), 5.0 + 4.0 * float(progreso) / 60.0, Color(color_equipo, 0.7))
	draw_rect(Rect2(-30, 30, 60, 5), Color("18212d"))
	draw_rect(Rect2(-30, 30, float(progreso), 5), color_equipo)
	var tecla := "Q" if equipo == 1 else "U"
	var estado := "%s  +5 ADN" % tecla
	if not mundo.simbionte_en_juego():
		estado = "EN ESPERA"
	elif cooldown > 0.0:
		estado = "%s  %.1fs" % [tecla, cooldown]
	draw_rect(Rect2(-60, -50, 120, 20), Color("172b36"))
	draw_rect(Rect2(-70, 39, 140, 18), Color("172b36"))
	draw_string(FUENTE, Vector2(-60, -34), "%d / 60" % progreso, HORIZONTAL_ALIGNMENT_CENTER, 120, 14, color_equipo)
	draw_string(FUENTE, Vector2(-70, 52), estado, HORIZONTAL_ALIGNMENT_CENTER, 140, 12, Color.WHITE if listo else Color("a5b6bc"))
