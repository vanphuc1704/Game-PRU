extends Node

## Mission/objective tracking system.

signal mission_started(mission_id: String)
signal mission_updated(mission_id: String, objective: String)
signal mission_completed(mission_id: String)
signal objective_progress(mission_id: String, current: int, total: int)
signal all_missions_complete

var active_missions: Dictionary = {}   # mission_id -> mission data
var completed_missions: Array[String] = []

class Mission:
	var id: String
	var title: String
	var objectives: Array[Dictionary] = []  # [{text, required, current, target, done}]
	var current_objective_index: int = 0
	var is_complete: bool = false

func start_mission(id: String, title: String, objectives: Array[Dictionary]) -> void:
	var mission = Mission.new()
	mission.id = id
	mission.title = title
	for obj in objectives:
		mission.objectives.append({
			"text": obj.get("text", ""),
			"required": obj.get("required", 1),
			"current": 0,
			"done": false
		})
	active_missions[id] = mission
	mission_started.emit(id)
	_update_display(id)

func progress_objective(mission_id: String, amount: int = 1) -> void:
	if not active_missions.has(mission_id):
		return
	var mission: Mission = active_missions[mission_id]
	if mission.is_complete:
		return
	var idx = mission.current_objective_index
	if idx >= mission.objectives.size():
		return
	var obj = mission.objectives[idx]
	obj.current = min(obj.current + amount, obj.required)
	objective_progress.emit(mission_id, obj.current, obj.required)
	if obj.current >= obj.required:
		obj.done = true
		mission.current_objective_index += 1
		if mission.current_objective_index >= mission.objectives.size():
			complete_mission(mission_id)
		else:
			_update_display(mission_id)

func complete_mission(mission_id: String) -> void:
	if not active_missions.has(mission_id):
		return
	var mission: Mission = active_missions[mission_id]
	mission.is_complete = true
	completed_missions.append(mission_id)
	active_missions.erase(mission_id)
	mission_completed.emit(mission_id)
	if active_missions.is_empty():
		all_missions_complete.emit()

func get_current_objective_text(mission_id: String) -> String:
	if not active_missions.has(mission_id):
		return ""
	var mission: Mission = active_missions[mission_id]
	var idx = mission.current_objective_index
	if idx >= mission.objectives.size():
		return "Hoàn thành!"
	var obj = mission.objectives[idx]
	if obj.required > 1:
		return "%s (%d/%d)" % [obj.text, obj.current, obj.required]
	return obj.text

func is_mission_active(mission_id: String) -> bool:
	return active_missions.has(mission_id)

func is_mission_complete(mission_id: String) -> bool:
	return mission_id in completed_missions

func clear_all() -> void:
	active_missions.clear()
	completed_missions.clear()

func _update_display(mission_id: String) -> void:
	var text = get_current_objective_text(mission_id)
	mission_updated.emit(mission_id, text)
