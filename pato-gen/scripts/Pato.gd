extends CharacterBody2D

@export var speed: float = 300.0
@export_enum("Jugador 1: 1", "Jugador 2: 2") var player_id: int = 1
@export var color_jugador: Color = Color.CYAN

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

var esta_desapareciendo: bool = false

func _ready() -> void:
	add_to_group("patos")
	
	if player_id == 1:
		color_jugador = Color.CYAN
	else:
		color_jugador = Color.MAGENTA
		
	if animated_sprite:
		animated_sprite.modulate = color_jugador

	iniciar_temporizador_desaparicion()

func iniciar_temporizador_desaparicion() -> void:
	# 1. Espera los 15 segundos iniciales
	await get_tree().create_timer(15.0).timeout
	
	# 2. Bloquea el movimiento e interrumpe animaciones de caminata
	esta_desapareciendo = true
	velocity = Vector2.ZERO
	
	if animated_sprite and animated_sprite.sprite_frames:
		var animaciones = animated_sprite.sprite_frames.get_animation_names()
		var anim_encontrada = ""
		
		for anim in animaciones:
			if "desaparec" in anim.to_lower():
				anim_encontrada = anim
				break
		
		if anim_encontrada != "":
			# Fuerza a que NO esté en loop para evitar saltos inmediatos
			animated_sprite.sprite_frames.set_animation_loop(anim_encontrada, false)
			
			animated_sprite.play(anim_encontrada)
			
			# Calcula el tiempo real que dura la animación
			var frames = animated_sprite.sprite_frames.get_frame_count(anim_encontrada)
			var fps = animated_sprite.sprite_frames.get_animation_speed(anim_encontrada)
			var duracion = float(frames) / max(fps, 1.0)
			
			# Espera el tiempo justo antes de borrar el nodo
			await get_tree().create_timer(duracion).timeout
	
	# 3. Infecta y elimina al pato
	infectar_y_desaparecer()

func _physics_process(_delta: float) -> void:
	if esta_desapareciendo:
		return

	var input_vector: Vector2 = Vector2.ZERO
	
	if player_id == 1:
		var left = Input.is_key_pressed(KEY_A)
		var right = Input.is_key_pressed(KEY_D)
		var up = Input.is_key_pressed(KEY_W)
		var down = Input.is_key_pressed(KEY_S)
		input_vector = Vector2(int(right) - int(left), int(down) - int(up)).normalized()
	else:
		var left = Input.is_key_pressed(KEY_LEFT)
		var right = Input.is_key_pressed(KEY_RIGHT)
		var up = Input.is_key_pressed(KEY_UP)
		var down = Input.is_key_pressed(KEY_DOWN)
		input_vector = Vector2(int(right) - int(left), int(down) - int(up)).normalized()
	
	velocity = input_vector * speed
	move_and_slide()
	
	actualizar_animacion(input_vector)

func infectar_y_desaparecer() -> void:
	var bots = get_tree().get_nodes_in_group("bots")
	var bot_mas_cercano: Node2D = null
	var distancia_minima: float = INF

	for bot in bots:
		if not bot.is_infected:
			var distancia = global_position.distance_to(bot.global_position)
			if distancia < distancia_minima:
				distancia_minima = distancia
				bot_mas_cercano = bot

	if bot_mas_cercano != null:
		bot_mas_cercano.infectar(color_jugador, player_id)

	queue_free()

func actualizar_animacion(direccion: Vector2) -> void:
	if esta_desapareciendo or not animated_sprite:
		return

	if direccion.length_squared() < 0.01:
		animated_sprite.stop()
		return

	if abs(direccion.x) > abs(direccion.y):
		if direccion.x > 0:
			animated_sprite.play("Derecha")
		else:
			animated_sprite.play("Izquierda")
	else:
		if direccion.y > 0:
			animated_sprite.play("Abajo")
		else:
			animated_sprite.play("Arriba")
