class_name Level
extends Node2D
## Monta a fase sorteando blocos ASCII (res://levels/chunks.gd) a partir de
## uma seed, gerencia início, morte, vitória e reinício.
## Morrer repete a mesma fase; completar sorteia uma nova.
## Seed fixa para testes: godot --path . -- --seed=123

const TILE = 16
const CHUNKS = preload("res://levels/chunks.gd")
## Altura da fase em tiles (40 x 16 px = altura da tela) e linha do chão
const LEVEL_ROWS = 40
const GROUND_ROW = 34
## Quantos blocos sorteados entre o início e o fim
const MIDDLE_COUNT = 10
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const WALKER_SCENE = preload("res://scenes/enemy_walker.tscn")
const BAT_SCENE = preload("res://scenes/enemy_bat.tscn")
const SPIKES_SCENE = preload("res://scenes/spikes.tscn")
const GEM_SCENE = preload("res://scenes/gem.tscn")
const GOAL_SCENE = preload("res://scenes/goal.tscn")
const TEX_STONE = preload("res://assets/generated/tile_stone.png")
const TEX_STONE_TOP = preload("res://assets/generated/tile_stone_top.png")

const SRC_STONE = 0
const SRC_STONE_TOP = 1

## Seed da próxima fase (-1 = sortear). Sobrevive ao reload da cena.
static var next_seed: int = -1

var player: Player
var level_seed: int = 0
var total_gems: int = 0
var elapsed: float = 0.0
var _running: bool = false
var _finished: bool = false
var _can_restart: bool = false

@onready var tiles: TileMapLayer = $TileMapLayer
@onready var entities: Node2D = $Entities
@onready var hud: HUD = $HUD


func _ready() -> void:
	Engine.time_scale = 1.0
	tiles.tile_set = _build_tileset()
	level_seed = _pick_seed()
	var map: Array = compose_map(level_seed)
	_build_level(map)
	var level_size: Vector2 = Vector2(map[0].length(), map.size()) * TILE
	_setup_camera(level_size)
	player.death_y = level_size.y + 32.0
	player.health_changed.connect(hud.set_health)
	player.gems_changed.connect(func(n: int) -> void: hud.set_gems(n, total_gems))
	player.started.connect(_on_started)
	player.died.connect(_on_player_died)
	hud.setup(player.max_health, total_gems)
	hud.show_message("TOQUE PARA COMEÇAR\n\nPULO: agarra e salta\nentre paredes")


func _physics_process(delta: float) -> void:
	if _running:
		elapsed += delta
		hud.set_time(elapsed)
	if _can_restart and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack")):
		get_tree().reload_current_scene()


func _pick_seed() -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			return int(arg.trim_prefix("--seed="))
	if next_seed >= 0:
		return next_seed
	return randi() % 1000000


## Sorteia a sequência de blocos e devolve o mapa ASCII completo.
## O jogador corre da direita para a esquerda, então o INÍCIO fica à direita.
## Se `spans` for passado, recebe [nome, x_inicial, x_final] de cada bloco (em px).
static func compose_map(seed_value: int, spans: Array = []) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var sequence: Array = [CHUNKS.START]
	var last_name: String = ""
	for i: int in MIDDLE_COUNT:
		# Dificuldade sobe ao longo da fase: tier 1 no começo, 3 no final
		var max_tier: int = 1 + int(float(i) / MIDDLE_COUNT * 3.0)
		var options: Array = CHUNKS.MIDDLE.filter(func(c: Dictionary) -> bool:
			return c.tier <= max_tier and c.name != last_name)
		# Blocos do tier atual aparecem com o dobro de chance
		var weights: PackedFloat32Array = PackedFloat32Array()
		for c: Dictionary in options:
			weights.append(2.0 if c.tier == max_tier else 1.0)
		var pick: Dictionary = options[rng.rand_weighted(weights)]
		sequence.append(pick)
		last_name = pick.name
	sequence.append(CHUNKS.END)
	sequence.reverse()

	var map: Array = []
	map.resize(LEVEL_ROWS)
	map.fill("#")  # parede na borda esquerda
	for chunk: Dictionary in sequence:
		var rows: Array = chunk.rows
		var width: int = String(rows[0]).length()
		var x0: int = String(map[0]).length()
		spans.append([chunk.name, x0 * TILE, (x0 + width) * TILE])
		var top: int = GROUND_ROW - (rows.size() - 1)
		assert(top >= 0, "Bloco '%s' alto demais" % chunk.name)
		for y: int in LEVEL_ROWS:
			var row: String
			if y < top:
				row = ".".repeat(width)
			else:
				row = rows[mini(y - top, rows.size() - 1)]
			assert(row.length() == width, "Bloco '%s' com linhas de larguras diferentes" % chunk.name)
			map[y] += row
	for y: int in LEVEL_ROWS:
		map[y] += "#"  # parede na borda direita
	return map


func _build_tileset() -> TileSet:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var half: float = TILE * 0.5
	var square: PackedVector2Array = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	var textures: Array[Texture2D] = [TEX_STONE, TEX_STONE_TOP]
	for i: int in textures.size():
		var src: TileSetAtlasSource = TileSetAtlasSource.new()
		src.texture = textures[i]
		src.texture_region_size = Vector2i(TILE, TILE)
		ts.add_source(src, i)
		src.create_tile(Vector2i.ZERO)
		var data: TileData = src.get_tile_data(Vector2i.ZERO, 0)
		data.add_collision_polygon(0)
		data.set_collision_polygon_points(0, 0, square)
	return ts


func _build_level(map: Array) -> void:
	for y: int in map.size():
		var row: String = map[y]
		for x: int in row.length():
			var c: String = row[x]
			var cell_center: Vector2 = Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
			var cell_floor: Vector2 = Vector2(x * TILE + TILE * 0.5, (y + 1) * TILE)
			match c:
				"#":
					var above_solid: bool = y > 0 and String(map[y - 1])[x] == "#"
					tiles.set_cell(Vector2i(x, y), SRC_STONE if above_solid else SRC_STONE_TOP, Vector2i.ZERO)
				"P":
					player = PLAYER_SCENE.instantiate()
					player.position = cell_floor
				"W":
					_spawn(WALKER_SCENE, cell_floor)
				"B":
					_spawn(BAT_SCENE, cell_center)
				"^":
					_spawn(SPIKES_SCENE, cell_center)
				"*":
					_spawn(GEM_SCENE, cell_center)
					total_gems += 1
				"G":
					var goal: Goal = _spawn(GOAL_SCENE, cell_floor) as Goal
					goal.reached.connect(_on_goal_reached)
	assert(player != null, "O mapa precisa de um 'P' (início do jogador)")
	entities.add_child(player)


func _spawn(scene: PackedScene, pos: Vector2) -> Node2D:
	var n: Node2D = scene.instantiate()
	n.position = pos
	entities.add_child(n)
	return n


func _setup_camera(level_size: Vector2) -> void:
	var cam: Camera2D = player.camera
	cam.limit_left = 0
	cam.limit_top = 0
	cam.limit_right = int(level_size.x)
	cam.limit_bottom = int(level_size.y)
	cam.reset_smoothing()


func _on_started() -> void:
	_running = true
	hud.hide_message()


func _on_player_died() -> void:
	_running = false
	next_seed = level_seed
	hud.show_message("VOCÊ MORREU")
	await get_tree().create_timer(1.6).timeout
	get_tree().reload_current_scene()


func _on_goal_reached() -> void:
	if _finished:
		return
	_finished = true
	_running = false
	player.freeze()
	next_seed = -1
	hud.show_message("FASE COMPLETA!\n\nGemas: %d / %d\nTempo: %s\n\nToque para jogar de novo" % [
		player.gems, total_gems, HUD.format_time(elapsed)])
	await get_tree().create_timer(1.0).timeout
	_can_restart = true
