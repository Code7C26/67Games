
extends CharacterBody2D

# Velocidad de movimiento del jugador
@export var speed: float = 300.0

# Permite seleccionar si es el jugador 1 o el jugador 2
@export_enum("Jugador 1: 1", "Jugador 2: 2") var player_id: int = 1

# Color que representa al jugador
@export var color_jugador: Color = Color.CYAN

# Referencia al sprite animado del pato
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

# Indica si el pato está realizando la animación de desaparición
var esta_desapareciendo: bool = false


func _ready() -> void:
	# Agrega el pato al grupo correspondiente
	add_to_group("patos")
	
	# Asigna un color según el jugador
	if player_id == 1:
		color_jugador = Color.CYAN
	else:
		color_jugador = Color.MAGENTA
		
	# Aplica el color al sprite
	if animated_sprite:
		animated_sprite.modulate = color_jugador

	# Inicia el temporizador para la desaparición
	iniciar_temporizador_desaparicion()


# Espera un tiempo antes de hacer desaparecer al pato
func iniciar_temporizador_desaparicion() -> void:
	# Espera los 15 segundos iniciales
	await get_tree().create_timer(15.0).timeout
	
	# Detiene el movimiento del jugador
	esta_desapareciendo = true
	velocity = Vector2.ZERO
	
	# Busca y reproduce la animación de desaparición
	if animated_sprite and animated_sprite.sprite_frames:
		var animaciones = animated_sprite.sprite_frames.get_animation_names()
		var anim_encontrada = ""
		
		for anim in animaciones:
			if "desaparec" in anim.to_lower():
				anim_encontrada = anim
				break
		
		if anim_encontrada != "":
			# Evita que la animación se repita
			animated_sprite.sprite_frames.set_animation_loop(anim_encontrada, false)
			
			# Reproduce la animación encontrada
			animated_sprite.play(anim_encontrada)
			
			# Calcula cuánto dura la animación
			var frames = animated_sprite.sprite_frames.get_frame_count(anim_encontrada)
			var fps = animated_sprite.sprite_frames.get_animation_speed(anim_encontrada)
			var duracion = float(frames) / max(fps, 1.0)
			
			# Espera hasta que termine la animación
			await get_tree().create_timer(duracion).timeout
	
	# Infecta a un bot y elimina al pato
	infectar_y_desaparecer()


func _physics_process(_delta: float) -> void:
	# No permite moverse mientras desaparece
	if esta_desapareciendo:
		return

	# Guarda la dirección ingresada por el jugador
	var input_vector: Vector2 = Vector2.ZERO
	
	# Controles del jugador 1 con WASD
	if player_id == 1:
		var left = Input.is_key_pressed(KEY_A)
		var right = Input.is_key_pressed(KEY_D)
		var up = Input.is_key_pressed(KEY_W)
		var down = Input.is_key_pressed(KEY_S)
		input_vector = Vector2(
			int(right) - int(left),
			int(down) - int(up)
		).normalized()
	else:
		# Controles del jugador 2 con las flechas
		var left = Input.is_key_pressed(KEY_LEFT)
		var right = Input.is_key_pressed(KEY_RIGHT)
		var up = Input.is_key_pressed(KEY_UP)
		var down = Input.is_key_pressed(KEY_DOWN)
		input_vector = Vector2(
			int(right) - int(left),
			int(down) - int(up)
		).normalized()
	
	# Aplica el movimiento según la dirección y velocidad
	velocity = input_vector * speed
	move_and_slide()
	
	# Actualiza la animación según la dirección
	actualizar_animacion(input_vector)


# Busca al bot sano más cercano, lo infecta y elimina el pato
func infectar_y_desaparecer() -> void:
	var bots = get_tree().get_nodes_in_group("bots")
	var bot_mas_cercano: Node2D = null
	var distancia_minima: float = INF
	
	# Busca el bot sano con menor distancia
	for bot in bots:
		if not bot.is_infected:
			var distancia = global_position.distance_to(bot.global_position)
			
			if distancia < distancia_minima:
				distancia_minima = distancia
				bot_mas_cercano = bot

	# Infecta al bot más cercano
	if bot_mas_cercano != null:
		bot_mas_cercano.infectar(color_jugador, player_id)

	# Elimina el pato de la escena
	queue_free()


# Cambia la animación según la dirección del movimiento
func actualizar_animacion(direccion: Vector2) -> void:
	if esta_desapareciendo or not animated_sprite:
		return

	# Detiene la animación si no hay movimiento
	if direccion.length_squared() < 0.01:
		animated_sprite.stop()
		return

	# Determina hacia qué dirección debe mirar el personaje
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
