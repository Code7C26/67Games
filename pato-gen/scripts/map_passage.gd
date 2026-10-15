extends Area2D
## Optional map-only connection. Does not know infection, AI or player rules.
signal transferred(body: CharacterBody2D, arrival: Marker2D)
@export var enabled: bool = true
@export var required_group: StringName = &"bots"
@export var destination: Marker2D
@export_range(0.2, 5.0, 0.1) var cooldown_seconds: float = 1.0
const LOCK: StringName = &"patogen_map_passage_until_ms"
var _queued: Dictionary = {}
var _retry_time: float = 0.0

func _ready() -> void:
    body_entered.connect(_request_transfer)

func _physics_process(delta: float) -> void:
    _retry_time += delta
    if _retry_time < 0.15 or not enabled:
        return
    _retry_time = 0.0
    # A blocked landing can become free while a body is still at the threshold.
    for body in get_overlapping_bodies():
        _request_transfer(body)

func _eligible(body: Node) -> bool:
    return (enabled and is_instance_valid(body) and body is CharacterBody2D
        and body.is_inside_tree() and is_instance_valid(destination)
        and destination.is_inside_tree() and body.collision_layer != 0
        and required_group != &"" and body.is_in_group(required_group)
        and Time.get_ticks_msec() >= int(body.get_meta(LOCK, 0)))

func _request_transfer(body: Node) -> void:
    if not _eligible(body) or _queued.has(body.get_instance_id()):
        return
    _queued[body.get_instance_id()] = true
    _transfer.call_deferred(weakref(body), body.get_instance_id())

func _landing_is_clear(body: CharacterBody2D) -> bool:
    # Physics transforms synchronize on the next step. Reserve the marker across
    # that step so two deferred arrivals in the same frame cannot overlap.
    if Engine.get_physics_frames() <= int(destination.get_meta(&"passage_reserved_until_frame", -1)):
        return false
    var candidate: Transform2D = body.global_transform
    candidate.origin = destination.global_position
    var count: int = 0
    for owner_id in body.get_shape_owners():
        if body.is_shape_owner_disabled(owner_id):
            continue
        for index in range(body.shape_owner_get_shape_count(owner_id)):
            count += 1
            var query := PhysicsShapeQueryParameters2D.new()
            query.shape = body.shape_owner_get_shape(owner_id, index)
            query.transform = candidate * body.shape_owner_get_transform(owner_id)
            query.collision_mask = body.collision_mask
            query.exclude = [body.get_rid()]
            query.collide_with_areas = false
            query.margin = 1.0
            if not get_world_2d().direct_space_state.intersect_shape(query, 1).is_empty():
                return false
    return count > 0

func _transfer(reference: WeakRef, id: int) -> void:
    _queued.erase(id)
    var body: Node = reference.get_ref()
    if not _eligible(body) or not _landing_is_clear(body):
        return
    body.set_meta(LOCK, Time.get_ticks_msec() + int(cooldown_seconds * 1000.0))
    destination.set_meta(&"passage_reserved_until_frame", Engine.get_physics_frames() + 1)
    body.global_position = destination.global_position
    # Preserve velocity, faction, infection, timers and possession untouched.
    transferred.emit(body, destination)
