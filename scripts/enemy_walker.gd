class_name EnemyWalker
extends CharacterBody2D
## Soldado que patrulha o chão, vira em paredes e beiradas. Morre com 1 golpe.

const SPEED = 30.0
const GRAVITY = 1000.0

@export var direction: int = 1

var dead: bool = false
## Pontos ao ser derrotado
@export var points: int = 100
## Depois de virar, ignora novas viradas por um instante. Sem isso o soldado
## travava virando a cada frame (o sensor ainda lia a posição antiga) e
## aparecia nos dois sentidos ao mesmo tempo, como um "X".
var _turn_lock: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var floor_ray: RayCast2D = $FloorRay


func _ready() -> void:
	sprite.play("walk")


func _physics_process(delta: float) -> void:
	if dead:
		return
	_turn_lock -= delta
	velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	velocity.x = direction * SPEED
	move_and_slide()
	floor_ray.position.x = 7.0 * direction
	floor_ray.force_raycast_update()
	if _turn_lock <= 0.0 and is_on_floor() and (is_on_wall() or not floor_ray.is_colliding()):
		direction = -direction
		_turn_lock = 0.3
		floor_ray.position.x = 7.0 * direction
	sprite.flip_h = direction < 0


func hit() -> void:
	if dead:
		return
	dead = true
	FX.burst(get_parent(), global_position + Vector2(0, -12), Color(1.0, 0.45, 0.2))
	queue_free()
