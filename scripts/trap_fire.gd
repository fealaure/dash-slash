extends Node2D
## Jato de fogo que sai do chão em ciclo. Ligado, pule por cima.

const OFF = 1.5
const WARN = 0.4
const ON = 0.9

var _t: float = 0.0

@onready var flame: Sprite2D = $Flame
@onready var shape: CollisionShape2D = $Hitbox/CollisionShape2D
@onready var smoke: CPUParticles2D = $Smoke


func _ready() -> void:
	_t = fmod(position.x * 0.011, 1.0) * (OFF + WARN + ON)


func _physics_process(delta: float) -> void:
	_t = fmod(_t + delta, OFF + WARN + ON)
	var on: bool = _t >= OFF + WARN
	smoke.emitting = _t >= OFF and not on
	flame.visible = on
	shape.disabled = not on
	if on:
		flame.scale = Vector2(1.0 + randf_range(-0.08, 0.08), 1.0 + randf_range(-0.1, 0.05))
