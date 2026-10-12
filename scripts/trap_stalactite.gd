class_name Stalactite
extends Node2D
## Estalactite que se solta quando o jogador se aproxima. Corte-a com a
## espada antes que ela caia em cima de você.

const TRIGGER = 72.0
const SHAKE = 0.2
const GRAVITY = 900.0

@export var points: int = 30

var dead: bool = false
var _state: int = 0  # 0 presa, 1 tremendo, 2 caindo
var _t: float = 0.0
var _vy: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D


func _physics_process(delta: float) -> void:
	if dead:
		return
	match _state:
		0:
			var player: Node2D = get_tree().get_first_node_in_group("player")
			if player != null:
				var dx: float = global_position.x - player.global_position.x
				if dx > -8.0 and dx < TRIGGER and player.global_position.y > global_position.y:
					_state = 1
		1:
			_t += delta
			sprite.position.x = sin(_t * 70.0)
			if _t >= SHAKE:
				_state = 2
		2:
			_vy += GRAVITY * delta
			position.y += _vy * delta
			if _hits_ground():
				_shatter()


func _hits_ground() -> bool:
	var q: PhysicsPointQueryParameters2D = PhysicsPointQueryParameters2D.new()
	q.position = global_position + Vector2(0, 8)
	q.collision_mask = 1
	return not get_world_2d().direct_space_state.intersect_point(q, 1).is_empty()


func _shatter() -> void:
	dead = true
	FX.burst(get_parent(), global_position, Color(0.6, 0.6, 0.65), 10)
	queue_free()


func hit() -> void:
	if dead:
		return
	_shatter()
