extends RichTextLabel

#region INSTANCE VARIABLES 

var update_interval : float = 0.5  #How often to update (in seconds)
var warning_color : Color = Color(1, 0.8, 0, 1)  #Yellow for warnings
var critical_color : Color = Color(1, 0, 0, 1)   #Red for critical

#endregion INSTANCE VARIABLES 

var _time_since_update : float = 0.0
var _fps_history : Array[float] = []
var _max_history_size : int = 60  #Track last 60 frames for averaging

func _ready() -> void:
	# Initial update
	_update_stats()

func _process(delta: float) -> void:
	_time_since_update += delta #Add to time
	
	#Track FPS history
	var current_fps = Engine.get_frames_per_second()
	_fps_history.append(current_fps)
	if _fps_history.size() > _max_history_size:
		_fps_history.pop_front()
	
	if _time_since_update >= update_interval:
		_update_stats()
		_time_since_update = 0.0

func _update_stats() -> void:
	self.clear() #Remove all text 
	
	# === FPS Stats ===
	var current_fps = Engine.get_frames_per_second()
	var avg_fps = _calculate_average_fps()
	var min_fps = _calculate_min_fps()
	
	self.append_text("PERFORMANCE\n")
	self.append_text(_colorize_fps("FPS: %d" % current_fps, current_fps))
	self.append_text(" (Avg: %d, Min: %d)\n" % [avg_fps, min_fps])
	self.append_text("Frame Time: %.2f ms\n" % (1000.0 / max(current_fps, 1)))
	
	# === Memory Stats ===
	var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC) / 1024.0 / 1024.0
	var static_max = Performance.get_monitor(Performance.MEMORY_STATIC_MAX) / 1024.0 / 1024.0
	
	self.append_text("\nMEMORY\n")
	self.append_text("Used: %.1f MB / %.1f MB\n" % [static_memory, static_max])
	
	# === Rendering Stats ===
	var draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var objects_drawn = Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	var vertices = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	
	self.append_text("\nRENDERING\n")
	self.append_text("Draw Calls: %d\n" % draw_calls)
	self.append_text("Objects: %d\n" % objects_drawn)
	self.append_text("Vertices: %s\n" % _format_number(vertices))
	
	# === Scene Stats ===
	var node_count = Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	var orphan_nodes = Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)
	
	self.append_text("\nSCENE\n")
	self.append_text("Nodes: %d\n" % node_count)
	if orphan_nodes > 0:
		self.append_text("[color=#FF0000]Orphan Nodes: %d[/color]\n" % orphan_nodes)
	

func _calculate_average_fps() -> int:
	if _fps_history.is_empty():
		return 0
	var sum := 0.0
	for fps in _fps_history:
		sum += fps
	return int(sum / _fps_history.size())

func _calculate_min_fps() -> int:
	if _fps_history.is_empty():
		return 0
	var min_val := _fps_history[0]
	for fps in _fps_history:
		if fps < min_val:
			min_val = fps
	return int(min_val)

func _colorize_fps(textString : String, fps : float) -> String:
	if fps >= 60:
		return textString  #White for good FPS
	elif fps >= 30:
		return "[color=#%s]%s[/color]" % [warning_color.to_html(false), textString]
	else:
		return "[color=#%s]%s[/color]" % [critical_color.to_html(false), textString]

func _format_number(num: float) -> String:
	if num >= 1000000:
		return "%.2fM" % (num / 1000000.0)
	elif num >= 1000:
		return "%.2fK" % (num / 1000.0)
	else:
		return str(int(num))
