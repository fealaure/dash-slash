class_name Level
extends Node2D
## Constrói a fase a partir do mapa ASCII (res://levels/level_01.gd),
## gerencia início, morte, vitória e reinício.

const TILE = 16
const LEVEL_DATA = preload("res://levels/level_01.gd")
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

var player: Player
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
	var map: Array = LEVEL_DATA.MAP
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
	hud.show_message("VOCÊ MORREU")
	await get_tree().create_timer(1.6).timeout
	get_tree().reload_current_scene()


func _on_goal_reached() -> void:
	if _finished:
		return
	_finished = true
	_running = false
	player.freeze()
	hud.show_message("FASE COMPLETA!\n\nGemas: %d / %d\nTempo: %s\n\nToque para jogar de novo" % [
		player.gems, total_gems, HUD.format_time(elapsed)])
	await get_tree().create_timer(1.0).timeout
	_can_restart = true
