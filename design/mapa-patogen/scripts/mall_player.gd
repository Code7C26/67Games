extends CharacterBody2D
## Standalone placeholder player for map validation.
## Team integration can replace this node/script without touching the map collision.

@export var speed: float = 280.0
@export var acceleration: float = 1800.0
@export var deceleration: float = 2200.0

func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var target := direction * speed
	var rate := acceleration if direction != Vector2.ZERO else deceleration
	velocity = velocity.move_toward(target, rate * delta)
	move_and_slide()
