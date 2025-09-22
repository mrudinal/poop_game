extends Label

@export var show_timer: bool = true

func _ready() -> void:
	Variables.timer_reset()
	text = "%d" % [Variables.music_starts]

func _process(delta: float) -> void:
	if not show_timer:
		return

	Variables.time_elapsed_s += delta

	var seconds := int(floor(Variables.time_elapsed_s + Variables.music_starts))
	var miliseconds := int(floor((Variables.time_elapsed_s + Variables.music_starts - float(seconds)) * 1000.0 + 0.5))
	if miliseconds >= 1000:
		miliseconds = 0
		seconds += 1

	text = "%02d.%03d" % [seconds, miliseconds]
