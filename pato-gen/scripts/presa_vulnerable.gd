extends Node2D
## Estado local de una presa: sólo el captor puede consumir su bonificación.
var captor: WeakRef
var restante := 1.0
var factor := 0.5
var bono := 0.25
var limite := 0.90
var consumido := false
var equipo_color := Color.WHITE

func _ready() -> void:
	z_index = 5
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func vigente() -> bool:
	var presa: Node2D = get_parent()
	var origen: Node2D = captor.get_ref() if captor != null else null
	return restante > 0.0 and is_instance_valid(origen) and not origen.is_queued_for_deletion() and origen._anfitrion_valido() and is_instance_valid(presa) and not presa.is_queued_for_deletion() and not presa.is_infected and presa.proteccion_coloso <= 0.0 and presa.proteccion_sano_ofensiva <= 0.0

func factor_movimiento() -> float:
	return clampf(factor, 0.1, 1.0) if vigente() else 1.0

func cancelar() -> void:
	restante = 0.0
	consumido = true
	queue_free()

func consumir(origen: Node2D, chance: float) -> float:
	if consumido or not vigente() or captor.get_ref() != origen: return chance
	consumido = true
	return clampf(chance + maxf(0.0, bono), 0.0, minf(0.90, limite))

func actualizar(delta: float) -> void:
	if not vigente():
		queue_free()
		return
	var origen: Node2D = captor.get_ref()
	if not origen._partida_activa(): return
	restante = maxf(0.0, restante - delta)
	queue_redraw()
	if restante <= 0.0: queue_free()

func _physics_process(delta: float) -> void:
	actualizar(delta)

func _draw() -> void:
	if not vigente(): return
	var alpha := minf(1.0, restante * 3.0)
	var angle := restante * 5.0
	for index in 3:
		var punto := Vector2(cos(angle + TAU * index / 3.0) * 7.0, sin(angle + TAU * index / 3.0) * 2.0 - 23.0)
		draw_rect(Rect2(punto.round(), Vector2(2, 2)), Color(equipo_color, alpha))
