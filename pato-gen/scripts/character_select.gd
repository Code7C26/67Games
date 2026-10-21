extends Control

# Índices actuales (0 a 2 para cada bando)
var indice_cian: int = 0
var indice_magenta: int = 0

# Referencias a los contenedores pasando a través del HBoxContainer
@onready var contenedores_cian = [
	$HBoxContainer/VBoxContainer1,
	$HBoxContainer/VBoxContainer2,
	$HBoxContainer/VBoxContainer3
]

@onready var contenedores_magenta = [
	$HBoxContainer/VBoxContainer4,
	$HBoxContainer/VBoxContainer5,
	$HBoxContainer/VBoxContainer6
]

func _ready() -> void:
	AudioManager.reproducir_menu()
	actualizar_visualizacion()

# --- FUNCIONES PARA EL JUGADOR CIAN ---
func _on_button_pressed() -> void:
	AudioManager.efecto("seleccion_cepa", -14.0)
	indice_cian += 1
	if indice_cian > 2:
		indice_cian = 0
	actualizar_visualizacion()

func _on_button_2_pressed() -> void:
	AudioManager.efecto("seleccion_cepa", -14.0)
	indice_cian -= 1
	if indice_cian < 0:
		indice_cian = 2
	actualizar_visualizacion()

# --- FUNCIONES PARA EL JUGADOR MAGENTA ---
func _on_button_3_pressed() -> void:
	AudioManager.efecto("seleccion_cepa", -14.0)
	indice_magenta += 1
	if indice_magenta > 2:
		indice_magenta = 0
	actualizar_visualizacion()

func _on_button_4_pressed() -> void:
	AudioManager.efecto("seleccion_cepa", -14.0)
	indice_magenta -= 1
	if indice_magenta < 0:
		indice_magenta = 2
	actualizar_visualizacion()



# --- FUNCIÓN PARA MOSTRAR/OCULTAR SEGÚN EL ÍNDICE ---
func actualizar_visualizacion() -> void:
	for i in range(contenedores_cian.size()):
		contenedores_cian[i].visible = (i == indice_cian)

	for i in range(contenedores_magenta.size()):
		contenedores_magenta[i].visible = (i == indice_magenta)

# --- CAMBIAR A LA ESCENA DE JUEGO (Vinculado únicamente al botón Comenzar Partida) ---
func _on_comenzar_pressed() -> void:
	# Guardar las cepas en la raíz del SceneTree. La raíz persiste al cambiar de escena.
	# Índices: 0 = atlético; 1 = de área; 2 = exponencial.
	var tipos: Array[String] = ["atletico", "area", "exponencial"]
	get_tree().root.set_meta("patogen_cepas", {
		1: tipos[indice_cian],
		2: tipos[indice_magenta]
	})
	# El boton Comenzar marca el verdadero inicio del juego, aunque haya escena intermedia.
	AudioManager.efecto("click")
	AudioManager.reproducir_partida()
	get_tree().change_scene_to_file("res://scenes/Shopping.tscn")
