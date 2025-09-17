extends Node

# any global vars you want:
var dev: bool = false
@export var quake_start_times: Array[float] = [19.6,66.4] 
@export var blink_start_times: Array[float] = [23.6, 70.4]
#var final_focus: Array[float] = [31.6, 78.4]
var final_focus: Array[float] = [0, 10]
@export var environment: String = "prod"

# you can also define functions:
func reset():
	var st := Engine.get_main_loop() as SceneTree
	var path := ""
	if st.current_scene and st.current_scene.scene_file_path != "":
		path = st.current_scene.scene_file_path
	else:
		path = str(ProjectSettings.get_setting("application/run/main_scene"))
	if environment != "dev":
		st.change_scene_to_file(path)
