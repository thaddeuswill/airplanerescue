extends AudioStreamPlayer
## Procedural sound, no audio files yet: soft prairie wind always, a buzzy engine drone
## while `engine` > 0 (0..1 throttle), a wrench "clink" and ratchet ticks on demand, and a
## distant bird call every 10-20 s.

const RATE := 22050.0
var engine := 0.0
var _pb: AudioStreamGeneratorPlayback
var _wind := 0.0
var _phase := 0.0
var _clink := 0.0
var _clink_t := 0.0
var _tick := 0.0


func _ready() -> void:
	var g := AudioStreamGenerator.new()
	g.mix_rate = RATE
	g.buffer_length = 0.15
	stream = g
	volume_db = -6.0
	play()
	_pb = get_stream_playback()


func clink() -> void:
	_clink = 1.0
	_clink_t = 0.0


func tick() -> void:  # one ratchet pawl click
	_tick = 1.0


var birds := true  # set false to silence the calls (they also stop while the engine runs)
var _call_wait := 6.0
var _call_t := -1.0  # seconds into the current two-note call, -1 = silent
var _call_pitch := 1.0
var _call_phase := 0.0


func _process(delta: float) -> void:
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
			_phase = fmod(_phase + (34.0 + engine * 80.0) / RATE, 1.0)
			s += (fmod(_phase * 2.0, 1.0) * 2.0 - 1.0) * 0.12 * (0.35 + engine)  # piston-buzz saw
		if _clink > 0.002:
			_clink_t += 1.0 / RATE
			s += sin(_clink_t * TAU * 2300.0) * _clink * 0.35
			_clink *= 0.9992
		if _tick > 0.01:
			s += (randf() * 2.0 - 1.0) * _tick * 0.5
			_tick *= 0.985
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
		_pb.push_frame(Vector2(s, s))
