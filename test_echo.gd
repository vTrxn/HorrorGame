extends SceneTree
func _init():
	var delay = AudioEffectDelay.new()
	print(delay.tap1_delay_ms)
	var reverb = AudioEffectReverb.new()
	print(reverb.room_size)
	quit()
