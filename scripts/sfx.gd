class_name Sfx
extends Node
## Tiny synthesizer: builds every game sound in code, so the project needs no audio files.

const RATE = 22050
var sounds := {}
var players: Array = []
var muted := false
var last := {}


func _ready() -> void:
	for k in 10:
		var p = AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	sounds["pop"] = _mix([_tone(900, 180, 0.12, "tri", 0.6), _noise(0.07, 0.35)])
	sounds["boom"] = _mix([_noise(0.9, 0.9), _tone(110, 35, 0.7, "sin", 0.8)])
	sounds["boing"] = _tone(160, 560, 0.28, "sin", 0.55)
	sounds["thud"] = _tone(150, 55, 0.13, "sin", 0.6)
	sounds["clank"] = _mix([_tone(760, 520, 0.14, "sq", 0.25), _tone(1500, 1500, 0.12, "tri", 0.3)])
	sounds["squeak"] = _seq([_tone(950, 1500, 0.11, "sq", 0.25), _tone(1500, 1050, 0.13, "sq", 0.25)])
	sounds["giggle"] = _seq([_tone(700, 950, 0.08, "tri", 0.4), _tone(820, 1000, 0.08, "tri", 0.4), _tone(680, 900, 0.08, "tri", 0.4), _tone(860, 1050, 0.1, "tri", 0.4)])
	sounds["magic"] = _seq([_tone(1200, 1200, 0.07, "sin", 0.3), _tone(1500, 1500, 0.07, "sin", 0.3), _tone(1800, 1800, 0.07, "sin", 0.3), _tone(2200, 2200, 0.12, "sin", 0.3)])
	sounds["spawn"] = _tone(520, 880, 0.09, "sin", 0.4)
	sounds["ouch"] = _tone(420, 180, 0.22, "tri", 0.45)
	sounds["click"] = _tone(820, 820, 0.04, "sin", 0.25)
	sounds["whoosh"] = _noise(0.35, 0.35)
	sounds["fuse"] = _noise(0.4, 0.15)
	sounds["machine"] = _seq([_tone(300, 300, 0.08, "sq", 0.2), _tone(400, 400, 0.08, "sq", 0.2), _tone(500, 500, 0.08, "sq", 0.2), _tone(300, 900, 0.3, "tri", 0.35)])
	sounds["fanfare"] = _seq([_tone(523, 523, 0.18, "tri", 0.45), _tone(659, 659, 0.18, "tri", 0.45), _tone(784, 784, 0.18, "tri", 0.45), _tone(1047, 1047, 0.45, "tri", 0.45)])
	sounds["hi"] = _seq([_tone(520, 700, 0.12, "tri", 0.4), _tone(700, 880, 0.15, "tri", 0.4)])
	for k in sounds.keys():
		if sounds[k] is PackedFloat32Array:
			sounds[k] = _wav(sounds[k])


func play(name: String, gap: float = 0.06) -> void:
	if muted or not sounds.has(name):
		return
	var t = Time.get_ticks_msec() / 1000.0
	if t - float(last.get(name, -9.0)) < gap:
		return
	last[name] = t
	for p in players:
		if not p.playing:
			p.stream = sounds[name]
			p.pitch_scale = randf_range(0.95, 1.05)
			p.play()
			return


func _wav(samples: PackedFloat32Array) -> AudioStreamWAV:
	var data = PackedByteArray()
	data.resize(samples.size() * 2)
	for k in samples.size():
		data.encode_s16(k * 2, int(clamp(samples[k], -1.0, 1.0) * 32000.0))
	var w = AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w


func _tone_s(f0: float, f1: float, dur: float, wave: String, vol: float) -> PackedFloat32Array:
	var n = int(RATE * dur)
	var out = PackedFloat32Array()
	out.resize(n)
	var ph = 0.0
	for k in n:
		var t = float(k) / n
		var f = f0 * pow(f1 / f0, t)
		ph += f / RATE
		var s = sin(ph * TAU)
		if wave == "sq":
			s = 1.0 if s > 0 else -1.0
		elif wave == "tri":
			s = 2.0 * abs(2.0 * (ph - floor(ph + 0.5))) - 1.0
		var env = (1.0 - t) * (1.0 - t) * min(1.0, k / 60.0)
		out[k] = s * env * vol
	return out


func _noise_s(dur: float, vol: float) -> PackedFloat32Array:
	var n = int(RATE * dur)
	var out = PackedFloat32Array()
	out.resize(n)
	var lp = 0.0
	for k in n:
		var t = float(k) / n
		lp = lp * 0.7 + randf_range(-1, 1) * 0.3
		out[k] = lp * (1.0 - t) * vol * 1.6
	return out


func _tone(f0: float, f1: float, dur: float, wave: String, vol: float) -> PackedFloat32Array:
	return _tone_s(f0, f1, dur, wave, vol)


func _noise(dur: float, vol: float) -> PackedFloat32Array:
	return _noise_s(dur, vol)


func _mix(list: Array) -> AudioStreamWAV:
	var n = 0
	for a in list:
		n = max(n, a.size())
	var out = PackedFloat32Array()
	out.resize(n)
	for a in list:
		for k in a.size():
			out[k] += a[k]
	return _wav(out)


func _seq(list: Array) -> AudioStreamWAV:
	var out = PackedFloat32Array()
	for a in list:
		out.append_array(a)
	return _wav(out)
