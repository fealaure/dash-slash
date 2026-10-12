class_name EnemyBoar
extends CharacterBody2D
## Javali: avista o jogador que vem pela frente (pela esquerda) e investe em
## linha reta. Para na beirada ou na parede e se recompõe. Depois que o
## jogador passa por cima dele, não persegue pelas costas. Aguenta 2 golpes.

const GRAVITY = 1000.0
const CHARGE_SPEED = 150.0
const SIGHT = Vector2(230.0, 40.0)
const RECOVER = 0.7

@export var points: int = 250
@export var health: int = 2

var dead: bool = false
var _dir: float = 0.0
var _recover: float = 0.0
var _flash: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if dead:
		return
	_recover -= delta
	_flash -= delta
	sprite.modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE
	velocity.y = minf(velocity.y + GRAVITY * delta, 420.0)
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if _dir == 0.0 and _recover <= 0.0 and player != null:
		var d: Vector2 = player.global_position - global_position
		sprite.flip_h = d.x < 0.0
		if d.x < 0.0 and -d.x < SIGHT.x and absf(d.y) < SIGHT.y:
			_dir = -1.0
	if _dir != 0.0:
		velocity.x = _dir * CHARGE_SPEED
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	move_and_slide()
	if _dir != 0.0:
		var ledge: bool = not test_move(global_transform.translated(Vector2(_dir * 10.0, 0.0)), Vector2(0, 4))
		if is_on_wall() or (is_on_floor() and ledge):
			_dir = 0.0
			velocity.x = 0.0
			_recover = RECOVER
	if _dir != 0.0:
		sprite.flip_h = _dir < 0.0
		sprite.play("run")
	else:
		sprite.stop()
		sprite.frame = 0


func hit() -> void:
	if dead:
		return
	health -= 1
	_flash = 0.15
	if health > 0:
		# O golpe interrompe a investida e empurra o javali para trás
		var player: Node2D = get_tree().get_first_node_in_group("player")
		var away: float = signf(global_position.x - player.global_position.x) if player else 1.0
		_dir = 0.0
		_recover = RECOVER
		velocity = Vector2(away * 120.0, -150.0)
		return
	dead = true
	FX.burst(get_parent(), global_position + Vector2(0, -10), Color(0.6, 0.4, 0.25), 18)
	queue_free()
