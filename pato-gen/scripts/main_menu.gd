extends Control

func _on_jugar_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/PatogenMall_Editable.tscn")

func _on_opciones_pressed() -> void:
	pass

func _on_salir_pressed() -> void:
	get_tree().quit()
