class_name Stats
extends RefCounted
## Derived player stats: base values from data/world.json + equipment bonuses.


static func _bonus(stat: String) -> int:
	var total := 0
	for slot in GameState.equipment:
		total += int(Content.item(GameState.equipment[slot]).get("stats", {}).get(stat, 0))
	return total


static func max_hp() -> int:
	return int(Content.player_stats().get("max_hp", 100)) + _bonus("max_hp")


static func attack() -> int:
	return int(Content.player_stats().get("attack", 1)) + _bonus("attack")


static func defense() -> int:
	return int(Content.player_stats().get("defense", 0)) + _bonus("defense")


## Damage formula shared by player and enemies (minimum 1).
static func damage(attack_value: int, defense_value: int) -> int:
	return maxi(1, attack_value - defense_value)
