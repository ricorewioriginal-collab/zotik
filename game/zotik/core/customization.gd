class_name Customization
extends RefCounted
## "Mein Zotik": cosmetic options from data/cosmetics.json. Visual only.


static func options() -> Array:
	var out := []
	for id in Content.table("cosmetics"):
		var o: String = Content.get_entry("cosmetics", id).option
		if not o in out:
			out.append(o)
	return out


static func choices(option: String) -> Array:
	var out := []
	for id in Content.table("cosmetics"):
		if Content.get_entry("cosmetics", id).option == option:
			out.append(id)
	out.sort()
	return out


static func default_choice(option: String) -> String:
	for id in choices(option):
		if Content.get_entry("cosmetics", id).get("default", false):
			return id
	return ""


## Fills missing options with defaults and drops invalid values.
static func ensure_valid() -> void:
	for o in options():
		if not GameState.customization.get(o, "") in choices(o):
			GameState.customization[o] = default_choice(o)


static func set_choice(option: String, id: String) -> bool:
	if not id in choices(option):
		return false
	GameState.customization[option] = id
	return true


static func cycle(option: String, step: int) -> String:
	var c := choices(option)
	var i := c.find(GameState.customization.get(option, default_choice(option)))
	var next: String = c[posmod(i + step, c.size())]
	GameState.customization[option] = next
	return next


static func color(option: String) -> Color:
	var id: String = GameState.customization.get(option, default_choice(option))
	return Color.html(Content.get_entry("cosmetics", id).get("color", "#ffffff"))
