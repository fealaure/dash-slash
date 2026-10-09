class_name EnemySwordNinja
extends CharacterBody2D
## Ninja espadachim: corre na direção do jogador, ergue a espada (aviso) e
## avança cortando. Aguenta 2 golpes; recua um pouco quando é atingido.

const GRAVITY = 1000.0
const SPEED = 85.0
const SIGHT = Vector2(220.0, 48.0)
const SWING_RANGE = 34.0
const WINDUP = 0.28
const SLASH = 0.22
const RECOVER = 0.45
const LUNGE = 150.0

@export var points: int = 300
@export var health: int = 2

var dead: bool = false
var _flash: float = 0.0
var _knock: float = 0.0
## 0 perseguindo, 1 erguendo a espada, 2 cortando, 3 se recompondo
var _state: int = 0
var _timer: float = 0.0
var _face: float = -1.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if dead:
		return
	_flash -= delta
	_knock -= delta
	_timer -= delta
	sprite.modulate = Color(1, 0.4, 0.4) if _flash > 0.0 else Color.WHITE
	velocity.y = minf(velocity.y + GRAVITY * delta, 420.0)
	var player: Node2D = get_tree().get_first_node_in_group("player")
	var anim: String = "idle"
	if _knock > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 400.0 * delta)
	elif _state == 1:
		anim = "windup"
		velocity.x = 0.0
		if _timer <= 0.0:
			_state = 2
			_timer = SLASH
	elif _state == 2:
		anim = "slash"
		velocity.x = _face * LUNGE if _safe_ahead(_face) else 0.0
		if _timer <= 0.0:
			_state = 3
			_timer = RECOVER
	elif _state == 3:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
		if _timer <= 0.0:
			_state = 0
	elif player != null:
		var d: Vector2 = player.global_position - global_position
		_face = signf(d.x) if d.x != 0.0 else _face
		velocity.x = 0.0
		if absf(d.x) < SWING_RANGE and absf(d.y) < SIGHT.y:
			_state = 1
			_timer = WINDUP
			anim = "windup"
		elif absf(d.x) < SIGHT.x and absf(d.y) < SIGHT.y and _safe_ahead(_face):
			velocity.x = _face * SPEED
			anim = "run"
	sprite.flip_h = _face < 0.0
	move_and_slide()
	if sprite.animation != anim:
		sprite.play(anim)


## Não se joga da beirada
func _safe_ahead(dir: float) -> bool:
	return test_move(global_transform.translated(Vector2(dir * 10.0, 0.0)), Vector2(0, 4))


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
		_state = 0
		return
	dead = true
	FX.burst(get_parent(), global_position + Vector2(0, -12), Color(0.3, 0.8, 0.4))
	queue_free()
