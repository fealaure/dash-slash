extends Node2D
## Poça de ácido: queima e arremessa o jogador para cima.

const LAUNCH = -380.0

@onready var surface: Sprite2D = $Surface
@onready var area: Area2D = $Area


func _physics_process(delta: float) -> void:
	# A superfície "ferve" deslizando a textura
	surface.region_rect.position.x = fmod(surface.region_rect.position.x + 6.0 * delta, 64.0)
	for body: Node2D in area.get_overlapping_bodies():
		if body is Player and not (body as Player).is_dead:
			var p: Player = body
			if p.can_take_damage():
				p.take_damage(global_position.x)
				p.velocity.y = LAUNCH
