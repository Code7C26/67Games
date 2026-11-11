extends Node2D
## Señales locales; la marca sólo se dibuja en una vista explícita de su equipo.
const Preferencias = preload("res://scripts/visual_preferences.gd")
var color_equipo := Color.WHITE
var tiempo := 0.0
var estado := ""
var buscando := false
var fase := 0.0
var equipo := 0
var pulso_restante := 0.0
var marca: WeakRef
var mostrar_marca := false

func configurar(id_equipo: int) -> void:
	equipo = id_equipo
	color_equipo = preload("res://scripts/equipos_infeccion.gd").color_equipo(equipo)
	z_index = 5

func fijar() -> void:
	estado = "fijar"
	tiempo = 0.5
	queue_redraw()

func perder() -> void:
	estado = "perder"
	tiempo = 0.65
	queue_redraw()

func limpiar() -> void:
	estado = ""
	tiempo = 0.0
	buscando = false
	pulso_restante = 0.0
	marca = null
	mostrar_marca = false
	queue_redraw()

func convocar() -> void:
	pulso_restante = 0.55
	queue_redraw()

func actualizar_marca(presa: Node2D, restante: float, mundo: Node, observada: bool = false) -> void:
	marca = weakref(presa) if is_instance_valid(presa) and restante > 0.0 else null
	# PatoGen usa una única cámara para los dos jugadores. Sin una vista privada
	# explícita, dibujar sobre la presa revelaría el rastro también al adversario.
	mostrar_marca = marca != null and observada and is_instance_valid(mundo) and int(mundo.get_meta("equipo_visible", 0)) == equipo
	queue_redraw()

func actualizar(delta: float, en_busqueda: bool) -> void:
	if pulso_restante > 0.0:
		pulso_restante = maxf(0.0, pulso_restante - delta)
		queue_redraw()
	fase += delta
	var tiempo_anterior := tiempo
	tiempo = maxf(0.0, tiempo - delta)
	if tiempo <= 0.0: estado = ""
	if buscando != en_busqueda or tiempo_anterior > 0.0 or en_busqueda: queue_redraw()
	buscando = en_busqueda

func _draw() -> void:
	if pulso_restante > 0.0:
		var progreso := 0.5 if Preferencias.reduced_motion(self) else 1.0 - pulso_restante / 0.55
		draw_arc(Vector2.ZERO, 12.0 + progreso * 30.0, 0.0, TAU, 20, Color(color_equipo, pulso_restante / 0.55 * 0.65), 1.5)
	var presa: Node2D = marca.get_ref() if marca != null else null
	if mostrar_marca and is_instance_valid(presa) and not presa.is_queued_for_deletion():
		var punto := to_local(presa.global_position) + Vector2(0, -25)
		draw_polyline(PackedVector2Array([punto + Vector2(-3, 0), punto + Vector2(0, -3), punto + Vector2(3, 0), punto + Vector2(0, 3), punto + Vector2(-3, 0)]), Color(color_equipo, 0.8), 1.0)
	if estado == "fijar":
		var tinta := Color(color_equipo, minf(1.0, tiempo * 3.0))
		draw_polyline(PackedVector2Array([Vector2(-5, -26), Vector2(0, -22), Vector2(5, -26)]), tinta, 2.0)
	elif estado == "perder":
		var tinta := Color(color_equipo, minf(1.0, tiempo * 2.0))
		draw_line(Vector2(-5, -25), Vector2(-1, -25), tinta, 2.0)
		draw_line(Vector2(2, -25), Vector2(6, -25), tinta, 2.0)
	elif buscando:
		var brillo := 0.7 if Preferencias.reduced_motion(self) else 0.45 + 0.25 * sin(fase * 4.0)
		draw_arc(Vector2(0, -20), 5.0, PI * 1.1, PI * 1.9, 8, Color(color_equipo, brillo), 1.5)
