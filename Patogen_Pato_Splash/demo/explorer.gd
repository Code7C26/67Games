extends CharacterBody2D
var player := 1
var sprite: AnimatedSprite2D
const VISUAL_SCALE := 2.0
func _ready() -> void:
	collision_layer=4;collision_mask=1
	var c:=CollisionShape2D.new();var sh:=CircleShape2D.new();sh.radius=15.6;c.shape=sh;add_child(c)
	sprite=AnimatedSprite2D.new();sprite.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	# Keep the original feet baseline and body physics while making the duck readable.
	sprite.scale=Vector2.ONE*VISUAL_SCALE
	sprite.position=Vector2(0,-16)
	sprite.sprite_frames=load("res://splash/assets/pato_parque.tres");sprite.animation="Abajo";add_child(sprite)
	queue_redraw()
func _draw() -> void:
	draw_arc(Vector2(0,8),27,0,TAU,32,Color("77e0e8") if player==1 else Color("df8bd0"),3)
func _physics_process(_delta: float) -> void:
	var d:=Vector2.ZERO
	if player==1:
		d=Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	else:
		d=Vector2(float(Input.is_physical_key_pressed(KEY_RIGHT))-float(Input.is_physical_key_pressed(KEY_LEFT)),float(Input.is_physical_key_pressed(KEY_DOWN))-float(Input.is_physical_key_pressed(KEY_UP)))
	velocity=d.normalized()*240
	move_and_slide()
	if d.length_squared()<.01:sprite.stop();return
	var anim:="Derecha" if d.x>0 else "Izquierda"
	if absf(d.y)>absf(d.x):anim="Abajo" if d.y>0 else "Arriba"
	sprite.play(anim)
