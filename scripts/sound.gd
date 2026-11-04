extends AudioStreamPlayer
## Procedural sound, no audio files yet: soft prairie wind always, a buzzy engine drone
## while `engine` > 0 (0..1 throttle), and a wrench "clink" on demand.

const RATE := 22050.0
var engine := 0.0
var _pb: AudioStreamGeneratorPlayback
var _wind := 0.0
var _phase := 0.0
var _clink := 0.0
var _clink_t := 0.0


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


func _process(_delta: float) -> void:
	if _pb == null:  # no audio device (headless runs)
		return
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
		_pb.push_frame(Vector2(s, s))
