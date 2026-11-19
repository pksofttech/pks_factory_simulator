extends Node

const SAMPLE_RATE := 22050

var _streams: Dictionary = {}
var sound_enabled: bool = true


func _ready() -> void:
	_build_streams()


func set_sound_enabled(enabled: bool) -> void:
	sound_enabled = enabled
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx >= 0:
		AudioServer.set_bus_mute(master_idx, not enabled)


func attach_loop(parent: Node3D, sound_id: String, volume_db: float = 0.0, max_dist: float = 65.0) -> AudioStreamPlayer3D:
	if parent == null:
		return null
	var player := AudioStreamPlayer3D.new()
	player.name = "_LoopAudio"
	player.stream = _get_stream(sound_id)
	player.volume_db = maxf(volume_db + 8.0, -2.0)
	player.unit_size = 22.0
	player.max_distance = maxf(max_dist, 60.0)
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	parent.add_child(player)
	return player


func set_loop_active(player: AudioStreamPlayer3D, is_active: bool) -> void:
	if player == null or DisplayServer.get_name() == "headless":
		return
	if is_active:
		if not player.playing:
			player.play()
	elif player.playing:
		player.stop()


func play_one_shot(parent: Node3D, sound_id: String, volume_db: float = 4.0, max_dist: float = 65.0, pitch_scale: float = 1.0) -> void:
	if parent == null or not sound_enabled or DisplayServer.get_name() == "headless":
		return
	var player := parent.get_node_or_null("_OneShotAudio") as AudioStreamPlayer3D
	if player == null:
		player = AudioStreamPlayer3D.new()
		player.name = "_OneShotAudio"
		player.unit_size = 24.0
		player.max_distance = maxf(max_dist, 60.0)
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		parent.add_child(player)
	player.stream = _get_stream(sound_id)
	player.volume_db = maxf(volume_db + 8.0, 3.0) if volume_db >= 0.0 else (volume_db + 8.0)
	player.pitch_scale = pitch_scale
	player.play()


func play_ui_confirm() -> void:
	if not sound_enabled or DisplayServer.get_name() == "headless":
		return
	var player := get_node_or_null("_UIConfirmAudio") as AudioStreamPlayer
	if player == null:
		player = AudioStreamPlayer.new()
		player.name = "_UIConfirmAudio"
		add_child(player)
	player.stream = _get_stream("remove")
	player.volume_db = 2.0
	player.play()


func _get_stream(sound_id: String) -> AudioStreamWAV:
	if _streams.is_empty():
		_build_streams()
	return _streams.get(sound_id) as AudioStreamWAV


func _build_streams() -> void:
	_streams["conveyor_loop"] = _make_loop_hum(78.0, 156.0, 0.65, 0.25, 0.8)
	_streams["fan_loop"] = _make_loop_hum(115.0, 230.0, 0.55, 0.45, 0.6)
	_streams["pump_loop"] = _make_loop_hum(96.0, 192.0, 0.72, 0.30, 0.7)
	_streams["tank_loop"] = _make_loop_hum(165.0, 330.0, 0.38, 0.50, 0.5)
	_streams["pneumatic"] = _make_one_shot(0.18, 460.0, 180.0, 0.72, 0.55)
	_streams["emit"] = _make_one_shot(0.14, 260.0, 120.0, 0.85, 0.25)
	_streams["remove"] = _make_one_shot(0.16, 560.0, 360.0, 0.78, 0.12)
	_streams["alarm"] = _make_one_shot(0.24, 880.0, 880.0, 0.85, 0.0)
	_streams["npc_chat"] = _make_soft_chirp_chat(0.28, 380.0, 560.0, 3, 18.0)
	_streams["npc_chat_2"] = _make_soft_chirp_chat(0.30, 440.0, 620.0, 4, 22.0)
	_streams["npc_chat_reply"] = _make_soft_chirp_chat(0.26, 520.0, 360.0, 3, 16.0)
	_streams["npc_check"] = _make_one_shot(0.06, 520.0, 660.0, 0.34, 0.0)
	_streams["npc_log"] = _make_one_shot(0.05, 420.0, 300.0, 0.30, 0.04)
	_streams["npc_warn"] = _make_one_shot(0.14, 740.0, 580.0, 0.45, 0.0)
	_streams["safety_alert"] = _make_one_shot(0.18, 860.0, 640.0, 0.50, 0.0)


func _make_soft_chirp_chat(dur: float, f_a: float, f_b: float, syllables: int, mod_rate: float) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	var syl := maxi(2, syllables)
	for i in range(count):
		var u := float(i) / float(max(1, count - 1))
		var t := float(i) / float(SAMPLE_RATE)
		var syl_u := fmod(u * float(syl), 1.0)
		var gate := pow(sin(PI * syl_u), 1.5) if syl_u < 0.82 else 0.0
		var syl_idx := int(floor(u * float(syl)))
		var step_pitch := 1.0 + 0.12 * sin(float(syl_idx) * 2.1)
		var base_f := lerpf(f_a, f_b, u) * step_pitch
		var warble := sin(TAU * mod_rate * t) * 42.0
		phase += TAU * maxf(180.0, base_f + warble) / float(SAMPLE_RATE)
		var sample := clampf((sin(phase) * 0.62 + sin(phase * 2.0) * 0.16) * gate * 0.72, -0.95, 0.95)
		data.encode_s16(i * 2, int(round(sample * 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = data
	return wav


func _make_loop_hum(freq_a: float, freq_b: float, tone_amp: float, noise_amp: float, dur: float) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(freq_a * 100.0)
	var lp := 0.0
	for i in range(count):
		var t := float(i) / float(SAMPLE_RATE)
		var mod := 0.85 + 0.15 * sin(TAU * 3.0 * t)
		var tone := (sin(TAU * freq_a * t) * 0.7 + sin(TAU * freq_b * t) * 0.3) * tone_amp * mod
		lp = lerpf(lp, rng.randf_range(-1.0, 1.0), 0.18)
		var sample := clampf(tone + lp * noise_amp, -0.95, 0.95)
		var s16 := int(round(sample * 32767.0))
		data.encode_s16(i * 2, s16)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = count
	return wav


func _make_one_shot(dur: float, f_start: float, f_end: float, tone_amp: float, noise_amp: float) -> AudioStreamWAV:
	var count := int(SAMPLE_RATE * dur)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(f_start * 31.0)
	var phase := 0.0
	for i in range(count):
		var u := float(i) / float(max(1, count - 1))
		var env := (1.0 - u) * minf(1.0, u * 18.0)
		var freq := lerpf(f_start, f_end, u)
		phase += TAU * freq / float(SAMPLE_RATE)
		var tone := sin(phase) * tone_amp
		var n := rng.randf_range(-1.0, 1.0) * noise_amp * (1.0 - u)
		var sample := clampf((tone + n) * env, -0.95, 0.95)
		data.encode_s16(i * 2, int(round(sample * 32767.0)))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.data = data
	return wav
