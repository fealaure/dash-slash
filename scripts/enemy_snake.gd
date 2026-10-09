class_name EnemySnake
extends Node2D
## Cobra peçonhenta enrolada no chão: dá o bote quando o jogador chega perto
## pela frente (nunca nas costas de quem já passou).

const STRIKE_RANGE = 60.0
const STRIKE_TIME = 0.35
const COOLDOWN = 1.1
const REACH = 12.0

@export var points: int = 150

var dead: bool = false
var _strike: float = 0.0
var _cooldown: float = 0.0
var _face: float = -1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox


func _physics_process(delta: float) -> void:
	if dead:
		return
	_strike -= delta
	_cooldown -= delta
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player != null and _strike <= 0.0:
		var d: Vector2 = player.global_position - global_position
		_face = signf(d.x) if d.x != 0.0 else _face
		if _cooldown <= 0.0 and d.x < 0.0 and -d.x < STRIKE_RANGE and absf(d.y) < 30.0:
			_strike = STRIKE_TIME
			_cooldown = COOLDOWN
	var striking: bool = _strike > 0.0
	sprite.frame = 1 if striking else 0
	sprite.flip_h = _face < 0.0
	hurtbox.position.x = _face * (REACH if striking else 0.0)


func hit() -> void:
	if dead:
		return
	dead = true
	FX.burst(get_parent(), global_position + Vector2(0, -6), Color(0.5, 0.85, 0.2))
	queue_free()
