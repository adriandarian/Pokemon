extends Node

const LocationBannerType = preload("res://features/location_banner/location_banner.gd")
const LOCATION_BANNER_SCENE: PackedScene = preload(
	"res://features/location_banner/location_banner.tscn"
)

var _failures: Array[String] = []


func _ready() -> void:
	var banner: LocationBannerType = LOCATION_BANNER_SCENE.instantiate() as LocationBannerType
	banner.fade_duration = 0.02
	banner.hold_duration = 0.03
	add_child(banner)
	await get_tree().process_frame

	banner.present("Mossglass Frontier", "Windfall Village", "Follow the east trail.")
	_expect(banner.is_presenting(), "Presenting a location makes the banner visible immediately.")
	_expect(banner.region_label.text == "MOSSGLASS FRONTIER", "The region copy is normalized to uppercase.")
	_expect(banner.location_label.text == "Windfall Village", "The location copy is updated.")
	_expect(banner.objective_label.text == "Follow the east trail.", "The objective copy is updated.")

	banner.present("Mossglass Frontier", "Mossglass Wilds", "Approach a roaming creature.")
	_expect(banner.location_label.text == "Mossglass Wilds", "Replaying the banner replaces the previous location.")
	await get_tree().create_timer(0.12).timeout
	_expect(not banner.is_presenting(), "The banner disappears after its fade and readable hold.")

	SettingsService.set_reduced_motion(true)
	banner.present("Mossglass Frontier", "Windfall Village", "Follow the east trail.")
	_expect(is_equal_approx(banner.modulate.a, 1.0), "Reduced motion presents the banner without a fade.")
	await get_tree().create_timer(0.06).timeout
	_expect(not banner.is_presenting(), "Reduced motion preserves timed dismissal.")
	SettingsService.set_reduced_motion(false)

	if _failures.is_empty():
		print("LOCATION_BANNER_SMOKE_TEST: PASS")
		get_tree().quit(0)
		return
	for failure: String in _failures:
		push_error("LOCATION_BANNER_SMOKE_TEST: %s" % failure)
	get_tree().quit(1)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
