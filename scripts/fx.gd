class_name FX
extends RefCounted
## Efeitos visuais simples reutilizáveis (explosão de partículas, hit-stop).


static func burst(parent: Node, pos: Vector2, color: Color, amount: int = 14) -> void:
	var p: CPUParticles2D = CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = amount
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.direction = Vector2.UP
	p.spread = 180.0
	p.initial_velocity_min = 60.0
	p.initial_velocity_max = 140.0
	p.gravity = Vector2(0, 300)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	p.color = color
	p.global_position = pos
	parent.add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)


static func hit_stop(tree: SceneTree, duration: float = 0.06) -> void:
	Engine.time_scale = 0.05
	await tree.create_timer(duration, true, false, true).timeout
	Engine.time_scale = 1.0
