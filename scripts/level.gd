class_name Level
extends Node2D
## Monta a fase sorteando blocos ASCII (res://levels/chunks.gd) a partir de
## uma seed, gerencia início, morte, vitória e a passagem para a próxima fase.
## Morrer repete a mesma fase; completar avança para a fase seguinte, mais
## longa e mais difícil.
## Para testes: godot --path . -- --seed=123 --stage=2

const TILE = 16
const CHUNKS = preload("res://levels/chunks.gd")
## Altura da fase em tiles e linha do chão. Sobra chão abaixo para a câmera
## manter o jogador no meio da tela, acima dos botões de toque.
const LEVEL_ROWS = 52
const GROUND_ROW = 34
## Quantos blocos sorteados entre o início e o fim: cresce a cada fase
const MIDDLE_COUNT_BASE = 14
const MIDDLE_COUNT_PER_STAGE = 4
const MIDDLE_COUNT_MAX = 30
const MAX_TIER = 4
## Cenário de cada fase (repete em ciclo): 1 bambuzal ao luar, 2 montanha
## nevada, 3 vale de outono, 4 caverna vulcânica. Cada tema tem céu, três
## camadas de parallax e o atlas do terreno em res://assets/generated/themes/<n>/
const THEMES = 4
const THEME_DIR = "res://assets/generated/themes/%d/"
const PLAYER_SCENE = preload("res://scenes/player.tscn")
const WALKER_SCENE = preload("res://scenes/enemy_walker.tscn")
const BAT_SCENE = preload("res://scenes/enemy_bat.tscn")
const SPIKES_SCENE = preload("res://scenes/spikes.tscn")
const GEM_SCENE = preload("res://scenes/gem.tscn")
const GOAL_SCENE = preload("res://scenes/goal.tscn")
const NINJA_SCENE = preload("res://scenes/enemy_ninja.tscn")
const TOAD_SCENE = preload("res://scenes/enemy_toad.tscn")
const SAW_SCENE = preload("res://scenes/trap_saw.tscn")
const SPRING_SCENE = preload("res://scenes/trap_spring.tscn")
const CRUMBLE_SCENE = preload("res://scenes/trap_crumble.tscn")
const SHOOTER_SCENE = preload("res://scenes/trap_shooter.tscn")
const BOAR_SCENE = preload("res://scenes/enemy_boar.tscn")
const SNAKE_SCENE = preload("res://scenes/enemy_snake.tscn")
const SPIDER_SCENE = preload("res://scenes/enemy_spider.tscn")
const SWORDNINJA_SCENE = preload("res://scenes/enemy_swordninja.tscn")
const ACID_SCENE = preload("res://scenes/trap_acid.tscn")
const POPSPIKES_SCENE = preload("res://scenes/trap_popspikes.tscn")
const FIRE_SCENE = preload("res://scenes/trap_fire.tscn")
const STALACTITE_SCENE = preload("res://scenes/trap_stalactite.tscn")

## Enfeites espalhados sobre o chão: [textura, peso do sorteio, temas onde aparece]
const DECOR = [
	[preload("res://assets/generated/props/grass_a.png"), 10.0, "13"],
	[preload("res://assets/generated/props/grass_b.png"), 10.0, "13"],
	[preload("res://assets/generated/props/grass_c.png"), 8.0, "13"],
	[preload("res://assets/generated/props/flowers.png"), 4.0, "1"],
	[preload("res://assets/generated/props/stone_moss.png"), 4.0, "123"],
	[preload("res://assets/generated/props/rock.png"), 3.0, "1234"],
	[preload("res://assets/generated/props/shoot_a.png"), 4.0, "13"],
	[preload("res://assets/generated/props/shoot_b.png"), 3.0, "13"],
	[preload("res://assets/generated/props/shoot_c.png"), 3.0, "13"],
	[preload("res://assets/generated/props/shoot_d.png"), 3.0, "13"],
	[preload("res://assets/generated/props/mushroom.png"), 2.0, "13"],
	[preload("res://assets/generated/props/fence.png"), 1.5, "123"],
	[preload("res://assets/generated/props/fence_broken.png"), 1.5, "1234"],
	[preload("res://assets/generated/props/lantern.png"), 1.0, "1234"],
	[preload("res://assets/generated/props/skull.png"), 1.0, "1234"],
]
const DECOR_CHANCE = 0.55
## Raízes penduradas sob plataformas (grama virada de cabeça para baixo)
const ROOTS_CHANCE = 0.3

## Atlas do terreno: 16 blocos (um por combinação de vizinhos sólidos: cima=1,
## direita=2, baixo=4, esquerda=8), cada um com a textura de 8x8 tiles. Cada
## célula usa o pedaço da textura da sua posição, então o chão fica contínuo,
## com grama/neve só no topo, bordas escuras nos lados e cantos arredondados.
const TEX_CELLS = 8

## Seed da próxima fase (-1 = sortear). Sobrevive ao reload da cena.
static var next_seed: int = -1
## Fase atual (1, 2, 3...). Sobrevive ao reload da cena.
static var stage: int = 1
## Pontuação acumulada entre as fases. Morrer volta à pontuação do início
## da fase (que é repetida).
static var score: int = 0
const GEM_POINTS = 50
const STAGE_BONUS = 1000
const SAVE_PATH = "user://save.cfg"

var player: Player
var level_seed: int = 0
var total_gems: int = 0
var elapsed: float = 0.0
var _running: bool = false
var _finished: bool = false
var _can_restart: bool = false
var _stage_start_score: int = 0

@onready var tiles: TileMapLayer = $TileMapLayer
@onready var entities: Node2D = $Entities
@onready var decor: Node2D = $Decor
@onready var hud: HUD = $HUD


func _ready() -> void:
	Engine.time_scale = 1.0
	level_seed = _pick_seed()
	tiles.tile_set = _build_tileset(load(_theme_path("terrain.png")))
	var map: Array = compose_map(level_seed, stage)
	_build_level(map)
	var level_size: Vector2 = Vector2(map[0].length(), map.size()) * TILE
	_decorate(map)
	_add_depth_shade(level_size)
	_add_fireflies(level_size)
	_setup_camera(level_size)
	player.death_y = level_size.y + 32.0
	player.health_changed.connect(hud.set_health)
	player.gems_changed.connect(func(n: int) -> void:
		hud.set_gems(n, total_gems)
		_add_score(GEM_POINTS))
	player.scored.connect(_add_score)
	_stage_start_score = score
	Audio.play_music(stage)
	player.started.connect(_on_started)
	player.died.connect(_on_player_died)
	hud.setup(player.max_health, total_gems)
	hud.set_score(score)
	_apply_theme()
	hud.show_message("FASE %d\n\nTOQUE PARA COMEÇAR\n\nPULO: agarra e salta\nentre paredes" % stage)


func _physics_process(delta: float) -> void:
	if _running:
		elapsed += delta
		hud.set_time(elapsed)
	if _can_restart and (Input.is_action_just_pressed("jump") or Input.is_action_just_pressed("attack")):
		get_tree().reload_current_scene()


func _pick_seed() -> int:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--stage="):
			stage = maxi(1, int(arg.trim_prefix("--stage=")))
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			return int(arg.trim_prefix("--seed="))
	if next_seed >= 0:
		return next_seed
	return randi() % 1000000


## Sorteia a sequência de blocos e devolve o mapa ASCII completo.
## O jogador corre da esquerda para a direita: INÍCIO à esquerda, FIM à direita.
## Se `spans` for passado, recebe [nome, x_inicial, x_final] de cada bloco (em px).
static func compose_map(seed_value: int, stage_number: int = 1, spans: Array = []) -> Array:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	var count: int = mini(MIDDLE_COUNT_BASE + MIDDLE_COUNT_PER_STAGE * (stage_number - 1), MIDDLE_COUNT_MAX)
	var sequence: Array = [CHUNKS.START]
	var last_name: String = ""
	for i: int in count:
		# Dificuldade sobe ao longo da fase e começa mais alta a cada fase:
		# fase 1 vai do tier 1 ao 3, fase 2 do 2 ao 4, fase 3 em diante do 3 ao 4
		var first_tier: int = mini(stage_number, MAX_TIER - 1)
		var max_tier: int = mini(first_tier + int(float(i) / count * 3.0), MAX_TIER)
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
			elif y - top < rows.size():
				row = rows[y - top]
			else:
				# Abaixo do chão: só blocos maciços continuam até o fundo (o ácido
				# é uma poça rasa, com chão logo abaixo)
				row = String(rows[-1]).replace("C", ".").replace("A", "#")
			assert(row.length() == width, "Bloco '%s' com linhas de larguras diferentes" % chunk.name)
			map[y] += row
	for y: int in LEVEL_ROWS:
		map[y] += "#"  # parede na borda direita
	return map


func _theme_path(file: String) -> String:
	return THEME_DIR % ((stage - 1) % THEMES + 1) + file


func _build_tileset(atlas: Texture2D) -> TileSet:
	var ts: TileSet = TileSet.new()
	ts.tile_size = Vector2i(TILE, TILE)
	ts.add_physics_layer()
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	var half: float = TILE * 0.5
	var square: PackedVector2Array = PackedVector2Array([
		Vector2(-half, -half), Vector2(half, -half), Vector2(half, half), Vector2(-half, half)])
	var src: TileSetAtlasSource = TileSetAtlasSource.new()
	src.texture = atlas
	src.texture_region_size = Vector2i(TILE, TILE)
	ts.add_source(src, 0)
	for x: int in 16 * TEX_CELLS:
		for y: int in TEX_CELLS:
			src.create_tile(Vector2i(x, y))
			var data: TileData = src.get_tile_data(Vector2i(x, y), 0)
			data.add_collision_polygon(0)
			data.set_collision_polygon_points(0, 0, square)
	return ts


static func _solid(map: Array, x: int, y: int) -> bool:
	if y < 0 or y >= map.size() or x < 0 or x >= String(map[y]).length():
		return true
	return String(map[y])[x] == "#"


## Coordenada no atlas para o bloco em (x, y)
static func _terrain_coords(map: Array, x: int, y: int) -> Vector2i:
	var mask: int = (1 if _solid(map, x, y - 1) else 0) | (2 if _solid(map, x + 1, y) else 0) \
		| (4 if _solid(map, x, y + 1) else 0) | (8 if _solid(map, x - 1, y) else 0)
	return Vector2i(mask * TEX_CELLS + x % TEX_CELLS, y % TEX_CELLS)


func _build_level(map: Array) -> void:
	for y: int in map.size():
		var row: String = map[y]
		for x: int in row.length():
			var c: String = row[x]
			var cell_center: Vector2 = Vector2(x * TILE + TILE * 0.5, y * TILE + TILE * 0.5)
			var cell_floor: Vector2 = Vector2(x * TILE + TILE * 0.5, (y + 1) * TILE)
			match c:
				"#":
					tiles.set_cell(Vector2i(x, y), 0, _terrain_coords(map, x, y))
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
				"N":
					_spawn(NINJA_SCENE, cell_floor)
				"H":
					_spawn(TOAD_SCENE, cell_floor)
				"S":
					_spawn(SAW_SCENE, cell_floor)
				"J":
					_spawn(SPRING_SCENE, cell_floor)
				"C":
					_spawn(CRUMBLE_SCENE, cell_center)
				"D":
					_spawn(SHOOTER_SCENE, cell_center)
				"Q":
					_spawn(BOAR_SCENE, cell_floor)
				"V":
					_spawn(SNAKE_SCENE, cell_floor)
				"U":
					_spawn(SPIDER_SCENE, Vector2(cell_center.x, y * TILE))
				"E":
					_spawn(SWORDNINJA_SCENE, cell_floor)
				"A":
					_spawn(ACID_SCENE, cell_center)
				"R":
					_spawn(POPSPIKES_SCENE, cell_center)
				"F":
					_spawn(FIRE_SCENE, cell_floor)
				"T":
					_spawn(STALACTITE_SCENE, cell_center)
	assert(player != null, "O mapa precisa de um 'P' (início do jogador)")
	entities.add_child(player)


func _decorate(map: Array) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = level_seed + 1
	var theme: String = str((stage - 1) % THEMES + 1)
	var weights: PackedFloat32Array = PackedFloat32Array()
	for d: Array in DECOR:
		weights.append(d[1] if String(d[2]).contains(theme) else 0.0)
	var root_ids: Array = range(DECOR.size()).filter(func(i: int) -> bool: return weights[i] > 0.0)
	# Enfeites tingidos pela luz de cada tema
	decor.modulate = [Color.WHITE, Color(0.85, 0.92, 1.1), Color(1.05, 0.9, 0.8), Color(0.75, 0.5, 0.45)][int(theme) - 1]
	for y: int in range(1, map.size() - 1):
		for x: int in String(map[y]).length():
			if String(map[y])[x] != "#":
				continue
			var above: String = String(map[y - 1])[x]
			var below: String = String(map[y + 1])[x]
			if above == "." and rng.randf() < DECOR_CHANCE:
				var tex: Texture2D = DECOR[rng.rand_weighted(weights)][0]
				_add_decor(tex, Vector2(x * TILE + TILE * 0.5 + rng.randf_range(-4.0, 4.0),
					y * TILE - tex.get_height() * 0.5), rng.randf() < 0.5, false)
			elif below == "." and above == "#" and rng.randf() < ROOTS_CHANCE:
				var roots: Texture2D = DECOR[root_ids[rng.randi_range(0, mini(2, root_ids.size() - 1))]][0]
				var s: Sprite2D = _add_decor(roots, Vector2(x * TILE + TILE * 0.5,
					(y + 1) * TILE + roots.get_height() * 0.5), rng.randf() < 0.5, true)
				s.modulate = Color(0.55, 0.6, 0.75)


func _add_decor(tex: Texture2D, pos: Vector2, flip_h: bool, flip_v: bool) -> Sprite2D:
	var s: Sprite2D = Sprite2D.new()
	s.texture = tex
	s.position = pos.round()
	s.flip_h = flip_h
	s.flip_v = flip_v
	decor.add_child(s)
	return s


## Partículas do clima de cada tema: vaga-lumes, neve, folhas ou brasas
func _add_fireflies(level_size: Vector2) -> void:
	var theme: int = (stage - 1) % THEMES + 1
	var color: Color = [Color(0.85, 1.0, 0.5), Color(0.95, 0.97, 1.0), Color(1.0, 0.55, 0.2), Color(1.0, 0.4, 0.1)][theme - 1]
	var p: CPUParticles2D = CPUParticles2D.new()
	p.amount = int(level_size.x / (40.0 if theme == 1 else 18.0))
	p.lifetime = 6.0
	p.preprocess = 6.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(level_size.x * 0.5, GROUND_ROW * TILE * 0.35)
	p.position = Vector2(level_size.x * 0.5, GROUND_ROW * TILE * 0.62)
	p.spread = 180.0 if theme == 1 else 25.0
	p.direction = Vector2.UP if theme == 4 else Vector2.DOWN
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 3.0 if theme == 1 else 12.0
	p.initial_velocity_max = 10.0 if theme == 1 else 28.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	var fade: Gradient = Gradient.new()
	var clear: Color = Color(color, 0.0)
	fade.set_color(0, clear)
	fade.set_color(1, clear)
	fade.add_point(0.3, Color(color, 0.9))
	fade.add_point(0.7, Color(color, 0.9))
	p.color_ramp = fade
	decor.add_child(p)


func _spawn(scene: PackedScene, pos: Vector2) -> Node2D:
	var n: Node2D = scene.instantiate()
	n.position = pos
	entities.add_child(n)
	return n


func _apply_theme() -> void:
	($Sky/TextureRect as TextureRect).texture = load(_theme_path("sky.png"))
	for layer: String in ["Mountains", "Mid", "Near"]:
		var tex: Texture2D = load(_theme_path(layer.to_lower() + ".png"))
		(get_node(layer + "/Sprite2D") as Sprite2D).texture = tex
		(get_node(layer) as Parallax2D).repeat_size.x = tex.get_width()


## Escurece o chão conforme a profundidade (por cima dos tiles)
func _add_depth_shade(level_size: Vector2) -> void:
	var grad: Gradient = Gradient.new()
	grad.set_color(0, Color(0, 0, 0.05, 0.0))
	grad.set_color(1, Color(0, 0, 0.05, 0.75))
	var tex: GradientTexture2D = GradientTexture2D.new()
	tex.gradient = grad
	tex.fill_from = Vector2(0, 0)
	tex.fill_to = Vector2(0, 1)
	tex.width = 4
	tex.height = 64
	var shade: Sprite2D = Sprite2D.new()
	shade.texture = tex
	shade.centered = false
	var top: float = (GROUND_ROW + 1) * TILE
	shade.position = Vector2(0, top)
	shade.scale = Vector2(level_size.x / tex.width, (level_size.y - top) / tex.height)
	add_child(shade)
	move_child(shade, tiles.get_index() + 1)


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


func _add_score(points: int) -> void:
	score += points
	hud.set_score(score)


## Guarda o recorde e devolve o maior valor já feito
static func save_best(points: int) -> int:
	var cfg: ConfigFile = ConfigFile.new()
	cfg.load(SAVE_PATH)
	var best: int = maxi(int(cfg.get_value("recorde", "pontos", 0)), points)
	cfg.set_value("recorde", "pontos", best)
	cfg.save(SAVE_PATH)
	return best


func _on_player_died() -> void:
	_running = false
	next_seed = level_seed
	var best: int = save_best(score)
	hud.show_message("VOCÊ MORREU\n\nPONTOS: %d\nRECORDE: %d\n\nFASE %d de novo..." % [score, best, stage])
	score = _stage_start_score
	await get_tree().create_timer(1.6).timeout
	get_tree().reload_current_scene()


func _on_goal_reached() -> void:
	if _finished:
		return
	_finished = true
	_running = false
	player.freeze()
	next_seed = -1
	_add_score(STAGE_BONUS)
	var best: int = save_best(score)
	hud.show_message("FASE %d COMPLETA!\n\nGemas: %d / %d\nTempo: %s\nPONTOS: %d\nRECORDE: %d\n\nPróxima: FASE %d" % [
		stage, player.gems, total_gems, HUD.format_time(elapsed), score, best, stage + 1])
	stage += 1
	await get_tree().create_timer(1.0).timeout
	_can_restart = true
	# Segue sozinho para a próxima fase se ninguém tocar
	await get_tree().create_timer(2.5).timeout
	get_tree().reload_current_scene()
