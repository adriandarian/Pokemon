extends Node

const REGION_ARGUMENT: String = "--terrain-region="
const OUTPUT_ARGUMENT: String = "--terrain-output="
const PREFIX_ARGUMENT: String = "--terrain-prefix="


func _ready() -> void:
	var region_path: String = ""
	var output_directory: String = ""
	var output_prefix: String = ""
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with(REGION_ARGUMENT):
			region_path = argument.trim_prefix(REGION_ARGUMENT)
		elif argument.begins_with(OUTPUT_ARGUMENT):
			output_directory = argument.trim_prefix(OUTPUT_ARGUMENT)
		elif argument.begins_with(PREFIX_ARGUMENT):
			output_prefix = argument.trim_prefix(PREFIX_ARGUMENT)
	if region_path.is_empty() or output_directory.is_empty():
		push_error("compile_region requires --terrain-region and --terrain-output arguments.")
		get_tree().quit(1)
		return
	var region: TerrainRegionDefinition = ResourceLoader.load(region_path) as TerrainRegionDefinition
	if region == null:
		push_error("Unable to load terrain region: %s" % region_path)
		get_tree().quit(1)
		return
	if output_prefix.is_empty():
		output_prefix = String(region.region_id)
	var chunks: Array[TerrainChunkData] = TerrainCompiler.compile_region(region)
	var expected_count: int = region.chunk_count.x * region.chunk_count.y
	if chunks.size() != expected_count:
		push_error("Terrain compilation failed: expected %d chunks, received %d." % [expected_count, chunks.size()])
		get_tree().quit(1)
		return
	var absolute_directory: String = ProjectSettings.globalize_path(output_directory)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		push_error("Unable to create terrain output directory: %s" % error_string(directory_error))
		get_tree().quit(1)
		return
	for chunk: TerrainChunkData in chunks:
		var output_path := "%s/%s_%d_%d.tres" % [
			output_directory,
			output_prefix,
			chunk.chunk_coord.x,
			chunk.chunk_coord.y,
		]
		var save_error: Error = ResourceSaver.save(chunk, output_path)
		if save_error != OK:
			push_error("Unable to save %s: %s" % [output_path, error_string(save_error)])
			get_tree().quit(1)
			return
	print("TERRAIN_COMPILE: PASS (%s, %d chunks)" % [region.region_id, chunks.size()])
	get_tree().quit(0)

