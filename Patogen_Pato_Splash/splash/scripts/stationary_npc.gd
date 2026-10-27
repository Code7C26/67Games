extends Node2D
## Portable visual actor. Navigation and infection are supplied by ParkLife.
@export var action_asset := "npc_guardia"
@export_enum("Huir", "Cubrirse", "Avisar") var reaction_kind := 0
@export var walking_skin := "banador_1"
@export var exit_offset := Vector2(0,48)
@export var phase_offset := 0.0
@export_range(32.0,360.0,8.0) var infection_radius := 176.0
@export_range(0.0,1.0,0.05) var infected_fraction := 0.25
@export_range(1,12,1) var minimum_infected := 1
@export_enum("Distancia", "Porcentaje local") var threshold_mode := 1
@export_range(2.0,30.0,0.5) var reaction_seconds := 8.0
@export_range(30.0,160.0,5.0) var flee_speed := 100.0
var age := 0.0
var home := Vector2.ZERO
var state := "rutina"
var state_age := 0.0
var velocity := Vector2.ZERO
var waypoints := PackedVector2Array()
var target_index := 0
var controller: Node2D
var reacted := 0
var whistle_left := 0.0
var cooldown := 0.0
var action_frames: SpriteFrames
var walking_frames: SpriteFrames
@onready var visual: AnimatedSprite2D = $Visual
@onready var indicator: AnimatedSprite2D = $Alerta
@onready var cover: AnimatedSprite2D = $Cubrir

func _ready() -> void:
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	home=position;age=phase_offset
	action_frames=visual.sprite_frames
	walking_frames=load("res://splash/assets/"+walking_skin+".tres")
	add_to_group("park_stationary")
	visual.stop(); indicator.hide(); cover.hide()

func trigger_reaction(focus: Vector2) -> void:
	if state!="rutina" or cooldown>0.0:return
	reacted+=1;state_age=0.0;cooldown=reaction_seconds+7.0
	state=["huida","cubrirse","avisar"][reaction_kind]
	if state=="huida" and (not is_instance_valid(controller) or not controller.navigation.is_valid()):state="cubrirse"
	indicator.show()
	if state=="huida":
		var departure:=home+exit_offset
		waypoints=PackedVector2Array([departure])
		waypoints.append_array(controller.escape_path(departure,focus));target_index=0
		visual.sprite_frames=walking_frames
	elif state=="avisar": whistle_left=1.3

func whistle() -> void:
	if state=="rutina":whistle_left=0.9

func _process(delta: float) -> void:
	age+=delta;state_age+=delta;cooldown=maxf(0,cooldown-delta);whistle_left=maxf(0,whistle_left-delta)
	indicator.frame=int(age*5.0)%4
	cover.visible=state=="cubrirse";cover.frame=int(age*5.0)%4
	if state=="huida" or state=="volver":
		_walk(delta)
		if target_index>=waypoints.size():
			if state=="huida" and state_age>reaction_seconds:
				state="volver";state_age=0
				waypoints=controller.route(position,home+exit_offset);waypoints.append(home);target_index=0
			elif state=="volver":_resume()
		return
	velocity=Vector2.ZERO
	if state!="rutina" and state_age>reaction_seconds:_resume()
	if action_asset=="npc_guardia" and whistle_left>0:
		visual.sprite_frames=load("res://splash/assets/npc_silbato.tres")
	else:visual.sprite_frames=action_frames
	visual.animation="default"
	visual.frame=int(age*visual.sprite_frames.get_animation_speed("default"))%visual.sprite_frames.get_frame_count("default")
	if state=="cubrirse":visual.modulate=Color(0.86,0.92,1.0)
	else:visual.modulate=Color.WHITE

func _walk(delta: float) -> void:
	if target_index>=waypoints.size():velocity=Vector2.ZERO;return
	var target:=waypoints[target_index]
	var old:=position;position=position.move_toward(target,flee_speed*delta);velocity=(position-old)/maxf(delta,0.001)
	if position.distance_to(target)<1.0:target_index+=1
	var animation: String="Derecha" if velocity.x>0 else "Izquierda"
	if absf(velocity.y)>absf(velocity.x):animation="Abajo" if velocity.y>0 else "Arriba"
	visual.animation=animation;visual.frame=int(age*9.0)%visual.sprite_frames.get_frame_count(animation)

func _resume() -> void:
	state="rutina";state_age=0;indicator.hide();cover.hide();visual.sprite_frames=action_frames;visual.animation="default";visual.modulate=Color.WHITE
