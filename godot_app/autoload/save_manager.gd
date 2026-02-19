extends Node
## Handles saving and loading game state to disk.

const SAVE_PATH := "user://crossums_save.json"


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_run() -> bool:
	## Save current run state to disk
	if GameState.run == null:
		return false

	var data := GameState.serialize()
	var json_str := JSON.stringify(data)

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: Could not open save file for writing")
		return false

	file.store_string(json_str)
	file.close()
	print("SaveManager: Saved run (stage %d, puzzle %d)" % [
		GameState.run.stage, GameState.run.puzzle_index
	])
	return true


func load_run() -> bool:
	## Load run state from disk
	if not save_exists():
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveManager: Could not open save file for reading")
		return false

	var json_str := file.get_as_text()
	file.close()

	var data = JSON.parse_string(json_str)
	if data == null:
		push_error("SaveManager: Invalid JSON in save file")
		return false

	if GameState.deserialize(data):
		print("SaveManager: Loaded run (stage %d, puzzle %d)" % [
			GameState.run.stage, GameState.run.puzzle_index
		])
		return true

	push_error("SaveManager: Failed to deserialize save data")
	return false


func delete_save() -> void:
	## Delete save file (called on run completion or game over)
	if save_exists():
		DirAccess.remove_absolute(SAVE_PATH)
		print("SaveManager: Deleted save file")
