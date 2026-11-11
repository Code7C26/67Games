extends Resource
## Rangos relativos al sensor real del mapa; no cambia AreaVision compartida.
@export_group("Instinto de caza")
@export_range(1.0, 3.0, 0.05) var multiplicador_deteccion := 1.75
@export_range(0.5, 20.0, 0.5) var memoria_persecucion := 6.0
@export_range(0.2, 5.0, 0.1) var intervalo_reevaluacion := 1.0
@export_range(0.05, 0.5, 0.01) var intervalo_observacion := 0.20
@export_range(53.0, 480.0, 1.0) var rango_base_navegado := 240.0
@export_range(0.1, 2.0, 0.05) var multiplicador_velocidad := 1.0
@export_group("Selección y navegación")
@export_range(24.0, 160.0, 1.0) var radio_aislamiento := 80.0
@export_range(0.0, 0.3, 0.01) var preferencia_aislamiento := 0.15
@export_range(0.2, 2.0, 0.05) var intervalo_ruta := 0.65
@export_group("Mejoras ADN")
@export var radios_manada := PackedFloat32Array([180.0, 200.0, 220.0])
@export_range(1, 3, 1) var maximo_aliados := 3
@export_range(1.0, 20.0, 0.5) var intervalo_manada := 8.0
@export_range(1.0, 20.0, 0.5) var duracion_manada := 8.0
@export var distancias_cerco := PackedFloat32Array([48.0, 60.0, 72.0])
@export var duraciones_marca := PackedFloat32Array([8.0, 9.0, 10.0])
