extends TestCase
## W22: the blow lines up with the swing (delayed hit outside headless runs), a press just before the
## cooldown ends is buffered, and the first-time quick start card exists.

var root: Node3D
var player: Player


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	root = Node3D.new()
	tree.root.add_child(root)
	player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	await physics_frames(3)


func after_each() -> void:
	root.queue_free()
	await frames(1)


func test_press_shortly_before_the_end_is_buffered() -> void:
	player.attack_cooldown = 0.1
	player._press_attack(true)
	check(player._buffered == 1, "strong press remembered")
	player.attack_cooldown = 0.0
	await physics_frames(2)
	check(player._buffered == -1, "buffer consumed once the cooldown is over")
	check(player.attack_cooldown > 0.0, "the buffered attack fired")


func test_press_long_before_the_end_is_ignored() -> void:
	player.attack_cooldown = 1.0
	player._press_attack(false)
	check(player._buffered == -1, "too early to buffer")


func test_hit_fraction_is_a_part_of_the_cooldown() -> void:
	check(Player.HIT_FRACTION > 0.0 and Player.HIT_FRACTION < 0.6, "the blow lands inside the swing")


func test_quick_start_card_builds() -> void:
	var m := QuickStartMenu.new()
	root.add_child(m)
	m.open()
	check(m.list.get_child_count() >= 5, "card lists the basics")
	check(Content.table("flags").has("FLAG_QUICKSTART_SHOWN"), "flag declared")
