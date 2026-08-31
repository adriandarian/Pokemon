class_name HomesteadPreviewCapture3D
extends Node

const CAPTURE_ARGUMENT := "--capture-preview="
const DELAY_ARGUMENT := "--capture-delay-frames="
const DEFAULT_DELAY_FRAMES: int = 12


func _ready() -> void:
	var output_path: String = ""
	var delay_frames: int = DEFAULT_DELAY_FRAMES
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(CAPTURE_ARGUMENT):
			output_path = argument.trim_prefix(CAPTURE_ARGUMENT)
		elif argument.begins_with(DELAY_ARGUMENT):
			delay_frames = maxi(1, argument.trim_prefix(DELAY_ARGUMENT).to_int())
	if not output_path.is_empty():
		_capture_after_render.call_deferred(output_path, delay_frames)


func _capture_after_render(output_path: String, delay_frames: int) -> void:
	for _frame: int in range(delay_frames):
		await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	if image == null:
		push_error("Could not capture the 3D homestead: the active renderer has no viewport image.")
		get_tree().quit(ERR_UNAVAILABLE)
		return
	var absolute_path: String = ProjectSettings.globalize_path(output_path)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_path.get_base_dir())
	if directory_error != OK:
		push_error("Could not create capture directory: %s" % error_string(directory_error))
		get_tree().quit(directory_error)
		return
	var save_error: Error = image.save_png(absolute_path)
	if save_error == OK:
		print("HOMESTEAD_3D_CAPTURED: %s" % absolute_path)
	else:
		push_error("Could not save 3D homestead capture: %s" % error_string(save_error))
	get_tree().quit(save_error)
