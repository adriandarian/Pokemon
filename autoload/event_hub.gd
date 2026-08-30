extends Node

## Cross-feature lifecycle events only. Keep this bus deliberately small.

signal creature_collected(creature: CreatureInstance)
signal party_changed(party_size: int, reserve_size: int)
signal badge_earned(badge_id: StringName)
signal inventory_changed(item_id: StringName, quantity: int)
