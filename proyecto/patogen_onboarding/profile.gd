extends RefCounted
## Local preferences only. Never reads/writes match saves or selected strains.
var path: String = "user://patogen_onboarding.cfg"
var data := {"intro_seen": false, "tutorial_completed": false, "last_result": "new", "last_step": "", "reduced_motion": false}
var last_error: Error = OK

func load_profile() -> void:
	var config := ConfigFile.new()
	var err := config.load(path)
	if err != OK:
		err = config.load(path + ".bak")
	if err == OK:
		for key in data:
			var value: Variant = config.get_value("onboarding", key, data[key])
			if typeof(value) == typeof(data[key]):
				data[key] = value
	if data.last_result == "running":
		data.last_result = "interrupted"
		save_profile()

func is_new() -> bool:
	return not data.intro_seen and data.last_result == "new"

func begin() -> void:
	data.last_result = "running"
	data.last_step = "overview"
	save_profile()

func finish(result: String) -> void:
	data.intro_seen = true
	data.last_result = result
	if result == "completed":
		data.tutorial_completed = true
	save_profile()

func save_profile() -> void:
	var config := ConfigFile.new()
	config.set_value("onboarding", "schema", 1)
	for key in data:
		config.set_value("onboarding", key, data[key])
	last_error = config.save(path + ".tmp")
	if last_error != OK:
		push_warning("PATOGEN: no se pudieron guardar las preferencias del tutorial.")
		return
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(absolute, absolute + ".bak")
	last_error = DirAccess.rename_absolute(absolute + ".tmp", absolute)
	if last_error != OK:
		# Windows may refuse replacement. Preserve the backup before removing.
		if FileAccess.file_exists(path + ".bak"):
			DirAccess.remove_absolute(absolute)
			last_error = DirAccess.rename_absolute(absolute + ".tmp", absolute)
	if last_error != OK:
		push_warning("PATOGEN: preferencias disponibles en memoria; fallo de escritura.")
