extends Area2D
## Espinhos que se escondem no chão e saltam para fora em ciclo.

const HIDDEN = 1.3
const WARN = 0.35
const OUT = 1.0

var _t: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	_t = fmod(position.x * 0.017, 1.0) * (HIDDEN + WARN + OUT)


func _physics_process(delta: float) -> void:
	_t = fmod(_t + delta, HIDDEN + WARN + OUT)
	var y: float
	if _t < HIDDEN:
		y = 14.0
	elif _t < HIDDEN + WARN:
		y = 10.0 + sin(_t * 60.0)  # aviso: as pontas tremem na beirada
	else:
		y = 3.0
	sprite.position.y = y
	shape.disabled = _t < HIDDEN + WARN
