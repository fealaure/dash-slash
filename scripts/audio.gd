extends Node
## Som do jogo (autoload "Audio"): música de cada fase e efeitos.
## Efeitos ficam em res://assets/audio/<nome>_<n>.ogg; cada chamada sorteia
## uma variação e varia um pouco o tom, para não soar repetido.

const DIR = "res://assets/audio/"
const MUSIC_TRACKS = 4
const VOICES = 8
const PITCH_JITTER = 0.06
## Volume (dB) por efeito
const SFX_DB = {"slash": -4.0, "kill": -2.0, "gem": -6.0, "jump": -8.0, "step": -16.0,
	"hurt": -4.0, "spring": -6.0}

var _variants: Dictionary = {}  # nome -> Array[AudioStream]
var _players: Array[AudioStreamPlayer] = []
var _next: int = 0
var _music: AudioStreamPlayer
## Sem janela (testes automáticos) o driver de áudio é falso e nunca libera o
## que toca: só registramos a faixa, sem tocar.
var _silent: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silent = DisplayServer.get_name() == "headless"
	for i: int in VOICES:
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -10.0
	add_child(_music)
	_ready_quit_hook()


func _ready_quit_hook() -> void:
	get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_cleanly()


## Fecha o jogo depois de parar o som. Se fechar com som tocando, o servidor
## de áudio ainda segura as faixas e o Godot acusa recursos vazados na saída.
func quit_cleanly(exit_code: int = 0) -> void:
	get_tree().paused = true  # nada mais toca som enquanto o mixer esvazia
	stop_all()
	await get_tree().create_timer(0.3, true, false, true).timeout
	get_tree().quit(exit_code)


func stop_all() -> void:
	for p: AudioStreamPlayer in _players:
		p.stop()
		p.stream = null
	_music.stop()
	_music.stream = null
	_variants.clear()


func play(sfx: String) -> void:
	if _silent:
		return
	var streams: Array = _load_variants(sfx)
	if streams.is_empty():
		return
	var p: AudioStreamPlayer = _players[_next]
	_next = (_next + 1) % _players.size()
	p.stream = streams.pick_random()
	p.volume_db = SFX_DB.get(sfx, -6.0)
	p.pitch_scale = 1.0 + randf_range(-PITCH_JITTER, PITCH_JITTER)
	p.play()


## Toca a música da fase (as faixas se repetem em ciclo depois da última)
func play_music(stage: int) -> void:
	var path: String = DIR + "music_%d.ogg" % ((stage - 1) % MUSIC_TRACKS + 1)
	if _music.stream != null and _music.stream.resource_path == path and _music.playing:
		return
	if not ResourceLoader.exists(path):
		return
	var stream: AudioStreamOggVorbis = load(path)
	stream.loop = true
	_music.stream = stream
	if not _silent:
		_music.play()


func _load_variants(sfx: String) -> Array:
	if not _variants.has(sfx):
		var list: Array = []
		for i: int in range(1, 10):
			var path: String = DIR + "%s_%d.ogg" % [sfx, i]
			if not ResourceLoader.exists(path):
				break
			list.append(load(path))
		_variants[sfx] = list
	return _variants[sfx]
