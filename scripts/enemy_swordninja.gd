class_name EnemySwordNinja
extends CharacterBody2D
## Ninja espadachim: corre na direção do jogador e golpeia de perto.
## Aguenta 2 golpes; recua um pouco quando é atingido.

const GRAVITY = 1000.0
const SPEED = 85.0
const SIGHT = Vector2(220.0, 48.0)
const SWING_RANGE = 28.0

@export var points: int = 300
@export var health: int = 2

var dead: bool = false
var _flash: float = 0.0
var _knock: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if dead:
		return
	_flash -= delta
	_knock -= delta
	sprite.modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE
	velocity.y = minf(velocity.y + GRAVITY * delta, 420.0)
	var player: Node2D = get_tree().get_first_node_in_group("player")
	var anim: String = "idle"
	if _knock > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	elif player != null:
		var d: Vector2 = player.global_position - global_position
		var face: float = signf(d.x) if d.x != 0.0 else -1.0
		sprite.flip_h = face < 0.0
		velocity.x = 0.0
		if absf(d.x) < SWING_RANGE and absf(d.y) < SIGHT.y:
			anim = "slash"
		elif absf(d.x) < SIGHT.x and absf(d.y) < SIGHT.y:
			# Não se joga da beirada
			if test_move(global_transform.translated(Vector2(face * 10.0, 0.0)), Vector2(0, 4)):
				velocity.x = face * SPEED
				anim = "run"
	move_and_slide()
	sprite.play(anim)


func hit() -> void:
	if dead:
		return
	health -= 1
	_flash = 0.15
	if health > 0:
		var player: Node2D = get_tree().get_first_node_in_group("player")
		var away: float = signf(global_position.x - player.global_position.x) if player else 1.0
		velocity = Vector2(away * 160.0, -120.0)
		_knock = 0.3
		return
	dead = true
	FX.burst(get_parent(), global_position + Vector2(0, -12), Color(0.3, 0.8, 0.4))
	queue_free()
