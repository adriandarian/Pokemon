extends Node

const REGION: TerrainRegionDefinition = preload(
	"res://features/terrain_world/content/windfall_starter_region.tres"
)
const OUTPUT_DIRECTORY: String = "res://features/terrain_world/generated"


func _ready() -> void:
	var chunks: Array[TerrainChunkData] = TerrainCompiler.compile_region(REGION)
	var expected_count: int = REGION.chunk_count.x * REGION.chunk_count.y
	if chunks.size() != expected_count:
		push_error("Terrain compilation failed: expected %d chunks, received %d." % [expected_count, chunks.size()])
		get_tree().quit(1)
		return
	var absolute_directory: String = ProjectSettings.globalize_path(OUTPUT_DIRECTORY)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		push_error("Unable to create terrain output directory: %s" % error_string(directory_error))
		get_tree().quit(1)
		return
	for chunk: TerrainChunkData in chunks:
		var output_path := "%s/windfall_%d_%d.tres" % [
			OUTPUT_DIRECTORY,
			chunk.chunk_coord.x,
			chunk.chunk_coord.y,
		]
		var save_error: Error = ResourceSaver.save(chunk, output_path)
		if save_error != OK:
			push_error("Unable to save %s: %s" % [output_path, error_string(save_error)])
			get_tree().quit(1)
			return
	print("TERRAIN_COMPILE: PASS (%d chunks)" % chunks.size())
	get_tree().quit(0)

