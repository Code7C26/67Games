extends SceneTree
## CPU headless: no mide GPU ni valida FPS visibles o balance competitivo.
var resultados: Array[Dictionary] = []

class Probe extends Node:
	var inicio: Node
	var marca := 0
	var medir := false
	var muestras: Array[float] = []
	func _physics_process(_delta: float) -> void:
		if inicio == null:
			marca = Time.get_ticks_usec()
		elif medir:
			muestras.append(float(Time.get_ticks_usec() - inicio.marca) / 1000.0)

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	for nombre in ["Shopping", "Laboratorio", "PatoSplash"]:
		root.get_node("PatogenOnboarding").requested_mode = "direct"
		var host: Node2D = load("res://scenes/" + nombre + ".tscn").instantiate()
		root.add_child(host)
		current_scene = host
		if host.has_signal("map_ready") and not host.map_is_ready: await host.map_ready
		host.timer_inicio.stop()
		host.evento_coloso.set_physics_process(false)
		host.evento_alfa.set_physics_process(false)
		var deadline := Time.get_ticks_msec() + 10000
		while host.evento_alfa.posiciones.is_empty() and Time.get_ticks_msec() < deadline: await physics_frame
		host.estado_actual = host.EstadoJuego.FASE_INFECCION
		host.timer_juego.start(600.0)
		for pato in get_nodes_in_group("patos"):
			pato.convertirse_en_fantasma()
			pato.set_physics_process(false)
		var puntos: PackedVector2Array = host.evento_alfa.posiciones
		var inicio := Probe.new()
		inicio.process_physics_priority = -10000
		host.add_child(inicio)
		var fin := Probe.new()
		fin.inicio = inicio
		fin.process_physics_priority = 10000
		host.add_child(fin)
		for cantidad in [65, 74, 90, 100, 150, 200]:
			var actual: int = host.contar_infecciones().total
			for i in range(cantidad - actual):
				var bot: Node2D = host.crear_infectado_alfa(puntos[(i * 137 + actual) % puntos.size()])
				bot.timer_curacion.stop()
			for i in 120: await physics_frame
			fin.muestras.clear()
			fin.medir = true
			for i in 180: await physics_frame
			fin.medir = false
			fin.muestras.sort()
			var n := fin.muestras.size()
			var medicion := {"mapa": nombre, "bots": cantidad, "samples": n, "script_physics_p50_ms": fin.muestras[n / 2], "script_physics_p95_ms": fin.muestras[int(n * 0.95)], "script_physics_max_ms": fin.muestras[-1]}
			resultados.append(medicion)
			print("BENCHMARK ", JSON.stringify(medicion))
		host.queue_free()
		await process_frame
		await process_frame
	var output := ProjectSettings.globalize_path("res://../work/parasito-alfa/benchmark.json").simplify_path()
	var archivo := FileAccess.open(output, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(resultados, "\t"))
	archivo.close()
	print("BENCHMARK RESULT 18 scripted-physics CPU scenarios, headless only; excludes GPU and engine work outside node callbacks")
	quit()
