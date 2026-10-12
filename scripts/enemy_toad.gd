class_name EnemyToad
extends CharacterBody2D
## Sapo-demônio que dá saltos na direção do jogador. Morre com 1 golpe.

const GRAVITY = 1000.0
const HOP = Vector2(75.0, -290.0)
const HOP_DELAY = 1.1
const SIGHT = 220.0

var dead: bool = false
## Pontos ao ser derrotado
@export var points: int = 150
var _wait: float = HOP_DELAY
var _fall_limit: float = 100000.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	_fall_limit = global_position.y + 400.0


func _physics_process(delta: float) -> void:
	if dead:
		return
	velocity.y = minf(velocity.y + GRAVITY * delta, 420.0)
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if is_on_floor():
		velocity.x = 0.0
		_wait -= delta
		if player != null:
			var dx: float = player.global_position.x - global_position.x
			sprite.flip_h = dx < 0.0
			if _wait <= 0.0 and absf(dx) < SIGHT:
				_wait = HOP_DELAY
				velocity = Vector2(signf(dx) * HOP.x, HOP.y)
	move_and_slide()
	sprite.frame = 0 if is_on_floor() else 1
	if global_position.y > _fall_limit:
		queue_free()


func hit() -> void:
	if dead:
		return
	dead = true
	FX.burst(get_parent(), global_position + Vector2(0, -8), Color(0.6, 0.3, 0.9))
	queue_free()
