extends CanvasLayer

func _on_reiniciar_button_pressed() -> void:
	# IMPORTANTE: Despausar antes de recargar
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_menu_button_pressed() -> void:
	# IMPORTANTE: Despausar antes de ir al menú
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
