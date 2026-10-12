class_name EnemyNinja
extends Node2D
## Ninja inimigo parado que arremessa shurikens quando o jogador se aproxima
## pela frente. Depois que o jogador passa por ele, não arremessa mais: o
## jogador não pode virar, então seria dano inevitável.
## Morre com 1 golpe; a shuriken também pode ser rebatida com a espada.

const SHURIKEN_SCENE = preload("res://scenes/shuriken.tscn")
const SIGHT = Vector2(180.0, 56.0)
const THROW_SPEED = 130.0
const COOLDOWN = 1.7

var dead: bool = false
## Pontos ao ser derrotado
@export var points: int = 200
var _cooldown: float = 0.5
var _pose: float = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta: float) -> void:
	if dead:
		return
	_cooldown -= delta
	_pose -= delta
	var player: Node2D = get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var d: Vector2 = player.global_position - global_position
	var face: float = signf(d.x) if d.x != 0.0 else -1.0
	sprite.flip_h = face < 0.0
	if _cooldown <= 0.0 and d.x < 0.0 and -d.x < SIGHT.x and absf(d.y) < SIGHT.y:
		_cooldown = COOLDOWN
		_pose = 0.3
		var s: Projectile = SHURIKEN_SCENE.instantiate()
		s.position = position + Vector2(face * 10.0, -14.0)
		s.velocity = Vector2(face * THROW_SPEED, 0.0)
		get_parent().add_child(s)
	sprite.frame = 1 if _pose > 0.0 else 0


func hit() -> void:
	if dead:
		return
	dead = true
	FX.burst(get_parent(), global_position + Vector2(0, -12), Color(0.9, 0.2, 0.25))
	queue_free()
