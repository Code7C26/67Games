extends Resource
## Parámetros de infiltración; nunca cambia el sensor de las otras cepas.
@export_group("Camuflaje biológico")
@export_range(0.1, 1.0, 0.01) var factor_deteccion := 0.30
@export_range(24.0, 100.0, 1.0) var distancia_revelacion := 35.0
@export_range(1.0, 30.0, 0.1) var recuperacion := 5.0
@export_range(0.05, 1.0, 0.01) var transicion_visual := 0.22
@export_group("Estadísticas")
@export_range(0.1, 1.0, 0.01) var multiplicador_velocidad := 1.0
@export_group("Pigmentación avanzada")
@export var factores_pigmentacion := PackedFloat32Array([0.27, 0.24, 0.21])
@export_group("Ataque sorpresa")
@export var bonos_ataque_sorpresa := PackedFloat32Array([0.25, 0.30, 0.35])
@export_range(0.0, 0.90, 0.01) var probabilidad_maxima_ataque := 0.90
@export_group("Desvanecimiento tras contagio exitoso")
@export var tiempos_desvanecimiento := PackedFloat32Array([1.0, 0.9, 0.8])
@export_range(0.1, 1.0, 0.05) var recuperacion_minima := 0.25
