extends Node
## Teste automático: um bot joga a fase sorteada e diz se chegou ao portal.
## Prova que os blocos encaixados são atravessáveis com a física atual.
## Uso: godot --headless --fixed-fps 60 --path . res://tests/bot_run.tscn -- --seed=7
## Saída: uma linha "BOT seed=<n> result=PASS|FAIL ..." e exit code 0/1.

const MAIN_SCENE = preload("res://scenes/main.tscn")
const TIME_LIMIT = 240.0
const ATTACK_RANGE = 44.0

var level: Level
var player: Player
var _jump_held: bool = false
var _released_frames: int = 0
var _held_frames: int = 0
var _game_time: float = 0.0


func _ready() -> void:
	level = MAIN_SCENE.instantiate()
	add_child(level)
	player = level.player
	player.health_changed.connect(func(h: int, _m: int) -> void:
		print("  dano x=%d y=%d bloco=%s vida=%d" % [player.global_position.x, player.global_position.y,
			_chunk_at(player.global_position.x), h]))
	player.died.connect(func() -> void: _finish(false, "morreu"))
	for goal: Node in level.entities.get_children():
		if goal is Goal:
			goal.reached.connect(func() -> void: _finish(true, "portal"))


func _physics_process(delta: float) -> void:
	_game_time += delta
	if _game_time > TIME_LIMIT:
		_finish(false, "tempo esgotado")
		return
	_send("attack", false)
	if not player.active:
		_send("jump", true)
		return
	if _jump_held:
		_held_frames += 1
		# Segura o pulo até o topo para não cortar a altura
		if _held_frames > 3 and player.velocity.y >= 0.0:
			_send("jump", false)
			_jump_held = false
			_released_frames = 0
	else:
		_released_frames += 1
		if _released_frames >= 2 and _wants_jump():
			_send("jump", true)
			_jump_held = true
			_held_frames = 0
			if OS.has_environment("BOT_DEBUG"):
				print("  pulo x=%d bloco=%s chao=%s cling=%s" % [player.global_position.x,
					_chunk_at(player.global_position.x), player.is_on_floor(), player.get("_clinging")])
	if _enemy_ahead():
		_send("attack", true)


## Injeta a ação como um evento de verdade (igual a uma tecla), processado
## pelo Player no próximo frame de física.
func _send(action: String, pressed: bool) -> void:
	if Input.is_action_pressed(action) == pressed:
		return
	var ev: InputEventAction = InputEventAction.new()
	ev.action = action
	ev.pressed = pressed
	Input.parse_input_event(ev)


func _wants_jump() -> bool:
	if player.get("_clinging"):
		return true
	if not player.is_on_floor():
		return false
	var f: float = player.facing
	if player.test_move(player.global_transform, Vector2(f * 6.0, 0.0)):
		return true  # parede ou degrau à frente
	if not _floor_at(player.global_position.x + f * 5.0):
		return true  # beirada (fosso, espinhos ou degrau para baixo)
	for n: Node in level.entities.get_children():
		if n.scene_file_path.ends_with("spikes.tscn"):
			var dx: float = (n.global_position.x - player.global_position.x) * f
			if dx > 0.0 and dx < 26.0 and absf(n.global_position.y - player.global_position.y) < 20.0:
				return true
	return false


func _floor_at(x: float) -> bool:
	var y: float = player.global_position.y
	var q: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.create(
		Vector2(x, y - 4.0), Vector2(x, y + 12.0), 1)
	return not player.get_world_2d().direct_space_state.intersect_ray(q).is_empty()


func _enemy_ahead() -> bool:
	for n: Node in level.entities.get_children():
		if (n is EnemyWalker or n is EnemyBat) and not n.dead:
			var d: Vector2 = (n as Node2D).global_position - player.global_position
			if d.x * player.facing > -6.0 and absf(d.x) < ATTACK_RANGE and absf(d.y + 10.0) < 34.0:
				return true
	return false


func _chunk_at(x: float) -> String:
	var spans: Array = []
	Level.compose_map(level.level_seed, spans)
	for sp: Array in spans:
		if x >= sp[1] and x < sp[2]:
			return "%s(+%d)" % [sp[0], int(x - sp[1])]
	return "?"


func _finish(ok: bool, reason: String) -> void:
	if not ok:
		var fell: bool = player.global_position.y > player.death_y
		reason += " caiu" if fell else " dano"
		reason += " bloco=" + _chunk_at(player.global_position.x)
	print("BOT seed=%d result=%s motivo=%s x=%d/%d tempo=%.1fs vida=%d" % [
		level.level_seed, "PASS" if ok else "FAIL", reason, int(player.global_position.x),
		level.player.camera.limit_right, _game_time, player.health])
	get_tree().quit(0 if ok else 1)
