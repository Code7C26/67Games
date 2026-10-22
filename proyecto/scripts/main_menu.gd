extends Control

func _ready() -> void:
	AudioManager.reproducir_menu()

func _on_jugar_pressed() -> void:
	AudioManager.efecto("click")
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_opciones_pressed() -> void:
	AudioManager.efecto("click")
	pass

func _on_salir_pressed() -> void:
	get_tree().quit()
