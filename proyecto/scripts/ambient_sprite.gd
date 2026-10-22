extends AnimatedSprite2D
## Purely visual. No collision, navigation, interaction or gameplay changes.
## Initialization runs once; AnimatedSprite2D handles playback natively.
@export var animar: bool = true
@export var variar_fase: bool = true

func _ready() -> void:
    _start_ambient.call_deferred()

func _start_ambient() -> void:
    if not animar:
        stop()
        return
    if not sprite_frames or not sprite_frames.has_animation(&"ambiente"):
        return
    play(&"ambiente")
    if variar_fase:
        var seed_value: int = abs(str(get_parent().get_path()).hash())
        var count: int = sprite_frames.get_frame_count(&"ambiente")
        if count > 0:
            set_frame_and_progress(seed_value % count, float(seed_value % 100) / 100.0)
