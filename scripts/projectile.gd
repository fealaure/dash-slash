class_name Projectile
extends Node2D
## Projétil em linha reta (shuriken do ninja, dardo da armadilha).
## Some ao bater em parede, ao acertar o jogador, ao acabar o tempo ou ao
## levar um golpe de espada.

@export var spin: float = 0.0

var velocity: Vector2 = Vector2.ZERO
var dead: bool = false
## Pontos ao ser derrotado
@export var points: int = 20
var _life: float = 4.0

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	sprite.flip_h = velocity.x < 0.0


func _physics_process(delta: float) -> void:
	position += velocity * delta
	sprite.rotation += spin * delta
	_life -= delta
	if _life <= 0.0 or _inside_wall():
		queue_free()


func _inside_wall() -> bool:
	var q: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	q.position = global_position
	q.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()


func hit() -> void:
	if dead:
		return
	dead = true
	FX.burst(get_parent(), global_position, Color(0.85, 0.85, 0.95), 6)
	queue_free()


func on_hit_player() -> void:
	dead = true
	queue_free()
