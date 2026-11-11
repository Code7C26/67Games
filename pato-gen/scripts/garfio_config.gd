extends Resource
## Balance compartido de Garfio, editable en el Inspector de Bot.tscn.
@export_group("Captura")
@export_range(54.0, 500.0, 1.0) var alcance_base := 160.0
@export_range(0.05, 2.0, 0.01) var preparacion := 0.35
@export_range(0.05, 3.0, 0.01) var duracion_max_arrastre := 0.65
@export_range(0.1, 30.0, 0.1) var enfriamiento := 7.0
@export_range(20.0, 600.0, 1.0) var velocidad_arrastre := 200.0
@export_range(50.0, 1000.0, 1.0) var velocidad_extension := 400.0
@export_range(0.05, 2.0, 0.01) var recuperacion := 0.25
@export_group("Cuerpo y contacto")
@export_range(0.1, 2.0, 0.01) var multiplicador_velocidad := 0.90
@export_range(0.0, 1.0, 0.01) var probabilidad_contagio := 0.35
@export_range(1.0, 100.0, 1.0) var distancia_minima := 52.0
@export_range(24.0, 48.0, 1.0) var distancia_contacto := 36.0
@export_range(1.0, 30.0, 1.0) var radio_impacto := 18.0
@export_group("Presa vulnerable")
@export_range(0.05, 3.0, 0.05) var duracion_vulnerable := 1.0
@export_range(0.0, 0.9, 0.01) var bono_vulnerable := 0.25
@export_range(0.0, 0.9, 0.01) var probabilidad_maxima_vulnerable := 0.90
@export var factores_movimiento_desorientado := PackedFloat32Array([0.50, 0.40, 0.30])
@export_group("Doble tendón")
## Dos cápsulas independientes; una sola recarga y cadencia de contagio.
@export var factores_duracion_doble := PackedFloat32Array([1.25, 1.20, 1.15])
@export_group("Reenganche")
## Proporción del enfriamiento base: 7 s pasan a 3 / 2,8 / 2,6 s.
@export var factores_recarga_reenganche := PackedFloat32Array([3.0 / 7.0, 2.8 / 7.0, 2.6 / 7.0])
@export_range(0.1, 3.0, 0.05) var ventana_captura := 1.0
