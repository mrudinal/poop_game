extends Node

# Global variables for Stage 1
# @export places the variable in Inspector
@export var environment: String = "prod"
@export var start_pos_x: float = 330.0		# 330 is the real # 264,8571428571429 pixels for every second of music
@export var start_pos_y: float = 364.0		# 364 is the real
@export var music_starts: float = 0.0
var quake_start_times: Array[float] = [19.6 - music_starts,66.4 - music_starts] 
var blink_start_times: Array[float] = [23.6 - music_starts, 70.4 - music_starts]
var final_focus: Array[float] = [31.6 - music_starts, 78.4 - music_starts]
var time_elapsed_s: float = 0.0

func timer_reset() -> void:
	time_elapsed_s = 0.0

# Reset after player loses:
func reset():
	var st := Engine.get_main_loop() as SceneTree
	var path := ""
	if st.current_scene and st.current_scene.scene_file_path != "":
		path = st.current_scene.scene_file_path
	else:
		path = str(ProjectSettings.get_setting("application/run/main_scene"))
	if environment != "dev":
		call_deferred("_deferred_change_scene", path)

func _deferred_change_scene(p: String) -> void:
	(Engine.get_main_loop() as SceneTree).change_scene_to_file(p)
