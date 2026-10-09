class_name EnemySpider
extends Node2D
## Aranha venenosa que sobe e desce pendurada no fio, do galho até a altura
## de quem passa pelo chão. Corte-a no pulo.

const DROP = 110.0
const PERIOD = 3.4

@export var points: int = 150

var dead: bool = false
var _t: float = 0.0

@onready var body: Node2D = $Body
@onready var thread: Line2D = $Thread


func _ready() -> void:
	_t = fmod(position.x * 0.021, 1.0) * PERIOD


func _physics_process(delta: float) -> void:
	if dead:
		return
	_t += delta
	var y: float = 6.0 + DROP * (0.5 - 0.5 * cos(_t / PERIOD * TAU))
	body.position.y = y
	thread.set_point_position(1, Vector2(0.0, y - 6.0))


func hit() -> void:
	if dead:
		return
	dead = true
	FX.burst(get_parent(), body.global_position, Color(0.55, 0.25, 0.7))
	queue_free()
