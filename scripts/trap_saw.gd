extends Node2D
## Serra que sobe e desce sobre o chão: baixa, pule por cima; alta, passe
## por baixo. Não pode ser destruída.

const LOW = -9.0
const HIGH = -64.0
const PERIOD = 2.4

var _t: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hitbox: Area2D = $Hitbox


func _ready() -> void:
	# Fase inicial fixa pela posição, para cada serra ter seu ritmo
	_t = fmod(position.x * 0.013, 1.0) * PERIOD


func _physics_process(delta: float) -> void:
	_t += delta
	var k: float = 0.5 - 0.5 * cos(_t / PERIOD * TAU)
	var y: float = lerpf(LOW, HIGH, k)
	sprite.position.y = y
	hitbox.position.y = y
	sprite.rotation += 14.0 * delta
