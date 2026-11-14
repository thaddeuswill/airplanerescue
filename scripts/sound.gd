extends AudioStreamPlayer
## All the game's audio. Synthesized here: soft prairie wind, a buzzy engine drone while
## `engine` > 0 (0..1 throttle), distant bird calls and small cues. Recorded (sounds/, see
## CREDITS.md): tool one-shots via sfx(), held-tool loops via loop(), hangar room tone and music.

const RATE := 22050.0
var engine := 0.0
var _pb: AudioStreamGeneratorPlayback
var _wind := 0.0
var _phase := 0.0
var _pulse := 0.0
var _exhaust := 0.0
var _prop_wash := 0.0
const CLIPS := ["ratchet", "torque_turn", "screw", "scrape", "wire", "tray", "seat", "snip", "heavy", "part", "wood", "tool",
	"thread", "breakfree", "latch", "click", "crank", "jack", "deny", "panel", "seat_panel", "rag", "sweep", "rustle", "pump", "spray", "liquid"]
## Track, and the dB that brings it to the same loudness as the others (measured).
const MUSIC := [["res://sounds/music/one_step_at_a_time.wav", -0.6], ["res://sounds/music/la_da_da_guitar.mp3", -4.0], ["res://sounds/music/apple_cider.ogg", -1.4]]
const MOODS := {"menu": [-3.0, -60.0], "world": [-9.0, -60.0], "work": [-6.0, -8.0], "flight": [-28.0, -60.0], "pause": [-18.0, -60.0]}  # music dB, room tone dB
var _track_db := 0.0
var _clips := {}  # name -> every recorded take of it, picked at random
var _pool: Array[AudioStreamPlayer] = []
var _loop: AudioStreamPlayer
var _loop_name := ""
var _music: AudioStreamPlayer
var _room: AudioStreamPlayer
var _cruise: AudioStreamPlayer
var _cruise_fade: Tween
var _mood := ""
## tracks: indexes into MUSIC. Your Music leaves the set silent and drives the PC's own player.
const STATIONS := [
	{"key": "Mix", "freq": "88", "name": "Shop Mix", "hint": "A bit of everything, all day.", "tracks": [0, 1, 2]},
	{"key": "Morning", "freq": "92", "name": "Easy Morning", "hint": "Slow coffee and a clean bench.", "tracks": [0]},
	{"key": "Porch", "freq": "96", "name": "Front Porch", "hint": "Guitar on the back forty.", "tracks": [1]},
	{"key": "Cider", "freq": "100", "name": "Cider Mill", "hint": "Warm and easy, late in the day.", "tracks": [2]},
	{"key": "Yours", "freq": "104", "name": "Your Music", "hint": "Runs the music app open on this PC.", "tracks": [], "yours": true},
	{"key": "Off", "freq": "OFF", "name": "Off", "hint": "Just the shop.", "tracks": []},
]
var station := 0
var _static := 0.0  # seconds of hiss left from tuning
var _tracks := []
var _next_track := 0.0  # seconds of quiet left before the next song


func _ready() -> void:
	var g := AudioStreamGenerator.new()
	g.mix_rate = RATE
	g.buffer_length = 0.15
	stream = g
	volume_db = -6.0
	_setup_buses()
	bus = "SFX"
	play()
	_pb = get_stream_playback()
	for n in CLIPS:
		_clips[n] = []
		for suffix in ["", "_1", "_2", "_3"]:
			for ext in [".wav", ".ogg"]:
				var path := "res://sounds/sfx/%s%s%s" % [n, suffix, ext]
				if ResourceLoader.exists(path):
					_clips[n].append(load(path))
	for i in 6:
		_pool.append(_player("Tools"))
	_loop = _player("Tools")
	_loop.finished.connect(_loop_again)
	_cruise = _player("SFX")
	_cruise.stream = _bake_cruise()  # a quarter second: at launch, not as the first trip starts
	_room = _player("Ambience")  # its own slider in Settings > Audio
	_room.stream = load("res://sounds/amb/room.wav")
	_room.volume_db = -40.0
	_room.finished.connect(_room.play)
	_room.play()
	_music = _player("Music")
	_music.volume_db = -40.0
	_music.finished.connect(func(): _next_track = randf_range(6.0, 18.0) if STATIONS[station].tracks.size() > 0 else 0.0)
	_next_track = 0.5


## Tools ring in a tin hangar. In a repair, the music comes out of the shop radio on the bench.
func _setup_buses() -> void:
	if AudioServer.get_bus_index("Music") >= 0:  # buses outlive a scene reload
		return
	for b in ["Music", "SFX", "Tools", "Ambience"]:
		AudioServer.add_bus()
		AudioServer.set_bus_name(AudioServer.bus_count - 1, b)
	AudioServer.set_bus_send(AudioServer.get_bus_index("Tools"), "SFX")
	var room := AudioEffectReverb.new()
	room.room_size = 0.6
	room.damping = 0.55
	room.predelay_msec = 25.0
	room.wet = 0.2
	AudioServer.add_bus_effect(AudioServer.get_bus_index("Tools"), room)
	var m := AudioServer.get_bus_index("Music")
	var shelf := AudioEffectLowShelfFilter.new()  # two of the tracks are mostly bass
	shelf.cutoff_hz = 160.0
	shelf.gain = 0.5
	AudioServer.add_bus_effect(m, shelf)
	var hp := AudioEffectHighPassFilter.new()
	hp.cutoff_hz = 300.0
	AudioServer.add_bus_effect(m, hp)
	var lp := AudioEffectLowPassFilter.new()
	lp.cutoff_hz = 3500.0
	AudioServer.add_bus_effect(m, lp)


func _player(bus_name: String) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.bus = bus_name
	add_child(p)
	return p


## One recorded sound, a random take, pitched a touch differently so repeats don't machine-gun.
func sfx(n: String) -> void:
	if not _clips.has(n) or _clips[n].is_empty():
		return
	for p in _pool:
		if not p.playing:
			p.stream = _clips[n].pick_random()
			p.pitch_scale = randf_range(0.95, 1.05)
			p.play()
			return


## A sound that runs while a tool is held down. Joins mid-clip: short holds shouldn't all match.
func loop(n: String) -> void:
	if n == _loop_name or not _clips.has(n) or _clips[n].is_empty():
		return
	_loop_name = n
	_loop.stream = _clips[n][0]
	_loop.play(randf() * _loop.stream.get_length() * 0.6)


func stop_loop() -> void:
	_loop_name = ""
	_loop.stop()


func _loop_again() -> void:
	if _loop_name != "":
		_loop.play()


## Four cylinders firing: uneven low thumps, filtered dark, with prop wash over them.
func _engine_sample(e: float) -> float:
	_phase += (20.0 + e * 58.0) / RATE
	if _phase >= 1.0:
		_phase -= 1.0
		_pulse = randf_range(0.7, 1.0)
	_pulse *= 0.9988
	_exhaust += (_pulse * (sin(_phase * TAU * 2.0) * 0.8 + (randf() * 2.0 - 1.0) * 0.4) - _exhaust) * 0.07
	_prop_wash += (randf() * 2.0 - 1.0 - _prop_wash) * 0.03
	return _exhaust * (0.2 + e * 0.16) + _prop_wash * e * 0.12


## Moves the dial: a burst of hiss between stations, then the new one comes up.
func tune(i: int, quiet := false) -> void:
	station = i
	_tracks = []
	_music.stop()
	_next_track = 0.5 if STATIONS[i].tracks.size() > 0 else 0.0
	if not quiet:
		_static = 0.45


## The drone of a trip between fields: throttles up, then back as you arrive.
## Start it a full second before any heavy work: a stalled frame counts for only ~0.13 s of tween time.
func cruise(on: bool) -> void:
	if _cruise_fade:
		_cruise_fade.kill()
	_cruise_fade = create_tween().set_parallel().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if on:
		_cruise.volume_db = -40.0
		_cruise.pitch_scale = 0.8
		_cruise.play()
	_cruise_fade.tween_property(_cruise, "volume_db", -6.0 if on else -50.0, 1.0)
	_cruise_fade.tween_property(_cruise, "pitch_scale", 1.0 if on else 0.75, 1.0)
	if not on:
		_cruise_fade.chain().tween_callback(_cruise.stop)


## Rendered to a looping clip, not streamed: building the next field stalls the game thread, and the clip plays through that.
func _bake_cruise() -> AudioStreamWAV:
	var n := int(RATE * 8.0)
	var blend := int(RATE * 0.5)
	var raw := PackedFloat32Array()
	raw.resize(n + blend)
	var air := 0.0
	var lo := 0.0
	var hi := 0.0
	var fire := 0.0
	var burst := 0.0
	for i in n + blend:
		var white := randf() * 2.0 - 1.0
		fire += 76.0 / RATE  # 2300 rpm, four cylinders: a rasp of exhaust bursts, or small speakers hear nothing
		if fire >= 1.0:
			fire -= 1.0
			burst = randf_range(0.7, 1.0)
		burst *= 0.995
		lo += (white - lo) * 0.2
		hi += (lo - hi) * 0.04
		air += (white - air) * 0.4  # wind past the cabin
		raw[i] = _engine_sample(0.85) * 0.6 + (lo - hi) * burst * 1.5 + air * 0.05
	for i in blend:  # the end fades into the start, so the loop has no seam
		var k := float(i) / blend
		raw[i] = raw[i] * k + raw[n + i] * (1.0 - k)
	var peak := 0.001
	for i in n:
		peak = maxf(peak, absf(raw[i]))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(raw[i] / peak * 0.7 * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(RATE)
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = n
	wav.data = data
	return wav


## menu, world, work or flight: fades the music and the hangar room tone to suit.
func set_mood(m: String) -> void:
	if m == _mood or _music == null:
		return
	_mood = m
	var m_bus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_effect_enabled(m_bus, 1, m == "work")
	AudioServer.set_bus_effect_enabled(m_bus, 2, m == "work")
	var t := create_tween().set_parallel()
	t.tween_property(_music, "volume_db", MOODS[m][0] + _track_db, 1.5)
	t.tween_property(_room, "volume_db", MOODS[m][1], 1.5)


## Small cues: a soft two-note chime when a new call comes in, and a pen scratching a signature.
var _notes := []  # [delay s, freq Hz, length s, amplitude, elapsed s]
var _pen := 0.0  # seconds of pen stroke left
var _pen_t := 0.0


func chime() -> void:
	_notes.append([0.0, 1318.5, 0.9, 0.12, 0.0])
	_notes.append([0.2, 987.8, 1.2, 0.12, 0.0])


func low_tone() -> void:  # a loss: soft, low and falling, never a buzzer
	_notes.append([0.0, 196.0, 1.2, 0.14, 0.0])
	_notes.append([0.25, 146.8, 1.6, 0.14, 0.0])


func done_tone() -> void:  # the new-call chime turned upward: a job finished
	_notes.append([0.0, 987.8, 0.7, 0.1, 0.0])
	_notes.append([0.14, 1318.5, 1.0, 0.1, 0.0])


func pen() -> void:
	_pen = 0.8
	_pen_t = 0.0


var birds := true  # set false to silence the calls (they also stop while the engine runs)
var _call_wait := 6.0
var _call_t := -1.0  # seconds into the current two-note call, -1 = silent
var _call_pitch := 1.0
var _call_phase := 0.0


func _process(delta: float) -> void:
	if _next_track > 0.0:
		_next_track -= delta
		if _next_track <= 0.0:
			if _tracks.is_empty():
				_tracks = STATIONS[station].tracks.map(func(t): return MUSIC[t])
				_tracks.shuffle()
			var track: Array = _tracks.pop_back()
			_track_db = track[1]
			_music.stream = load(track[0])
			_music.volume_db = MOODS.get(_mood, MOODS.world)[0] + _track_db
			_music.play()
	if _pb == null:  # no audio device (headless runs)
		return
	_call_wait -= delta
	if _call_wait <= 0.0 and birds and engine == 0.0:  # a meadowlark-ish whistle every 10-20 s
		_call_wait = randf_range(10.0, 20.0)
		_call_t = 0.0
		_call_pitch = randf_range(0.85, 1.2)
	for i in _pb.get_frames_available():
		_wind += (randf() * 2.0 - 1.0 - _wind) * 0.015  # low-passed noise
		var s := _wind * 0.5
		if engine > 0.0:
			s += _engine_sample(engine)
		if _static > 0.0:
			_static -= 1.0 / RATE
			s += (randf() * 2.0 - 1.0) * 0.1
		if _call_t >= 0.0:  # two falling whistled notes, distant and soft
			_call_t += 1.0 / RATE
			var note := 0 if _call_t < 0.22 else 1
			var nt := _call_t - note * 0.3
			if nt >= 0.0 and nt < 0.22:
				var f := (3300.0 - 900.0 * nt / 0.22 - note * 500.0) * _call_pitch
				_call_phase = fmod(_call_phase + f / RATE, 1.0)
				s += sin(_call_phase * TAU) * sin(PI * nt / 0.22) * 0.07
			if _call_t > 0.55:
				_call_t = -1.0
		for n in _notes:
			n[4] += 1.0 / RATE
			var nt: float = n[4] - n[0]
			if nt >= 0.0:
				s += sin(nt * TAU * n[1]) * n[3] * exp(-nt * 4.0 / n[2])  # bell-like decay
		if _pen > 0.0:  # scratchy noise in three quick strokes
			_pen -= 1.0 / RATE
			_pen_t += 1.0 / RATE
			s += (randf() * 2.0 - 1.0) * 0.09 * maxf(0.0, sin(_pen_t * TAU * 3.7))
		_pb.push_frame(Vector2(s, s))
	_notes = _notes.filter(func(n): return n[4] - n[0] < n[2])
