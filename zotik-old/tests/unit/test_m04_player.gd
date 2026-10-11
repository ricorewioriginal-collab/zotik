extends TestCase

var root: Node3D
var player: Player


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	root = Node3D.new()
	tree.root.add_child(root)
	var floor_body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(60, 1, 60)
	col.shape = box
	col.position.y = -0.5
	floor_body.add_child(col)
	root.add_child(floor_body)
	player = load("res://scenes/player/player.tscn").instantiate()
	root.add_child(player)
	await physics_frames(5)


func after_each() -> void:
	for a in ["move_forward", "move_back", "move_left", "move_right", "dodge", "block", "jump"]:
		Input.action_release(a)
	root.queue_free()
	await frames(1)


func test_customization_defaults_are_valid() -> void:
	for o in ["fur_shade", "scarf", "outfit"]:
		check(GameState.customization.get(o, "") in Customization.choices(o), "default for " + o)
	check(not Customization.set_choice("scarf", "COS_FUR_ORANGE_002"), "cross-option choice rejected")


func test_zotik_visual_is_orange_and_non_human() -> void:
	var v := player.visual
	for p in ["PLACEHOLDER_ear_l", "PLACEHOLDER_ear_r", "PLACEHOLDER_tail", "PLACEHOLDER_muzzle"]:
		check(v.parts.has(p), "missing creature part " + p)
	for id in Customization.choices("fur_shade"):
		var c := Color.html(Content.get_entry("cosmetics", id).color)
		check(c.r > c.g and c.g > c.b and c.h < 0.12, "%s must be an orange shade" % id)
	check(v.part_color("PLACEHOLDER_eye_l").g > 0.6, "green eyes")


func test_customization_applies_and_persists() -> void:
	Customization.set_choice("scarf", "COS_SCARF_BLUE_001")
	player.visual.apply_customization()
	eq(player.visual.part_color("PLACEHOLDER_scarf"), Color.html("#3a5fb0"), "scarf colour applied")
	var snapshot := GameState.to_dict()
	GameState.reset_new_game()
	GameState.from_dict(snapshot)
	eq(GameState.customization.scarf, "COS_SCARF_BLUE_001", "customization survives serialization")


func test_customization_does_not_change_stats() -> void:
	var atk := Stats.attack()
	var hp := Stats.max_hp()
	Customization.cycle("outfit", 1)
	Customization.cycle("fur_shade", 1)
	eq(Stats.attack(), atk, "attack unchanged")
	eq(Stats.max_hp(), hp, "max hp unchanged")


func test_moves_relative_to_camera() -> void:
	var start := player.global_position
	Input.action_press("move_forward")
	await physics_frames(30)
	Input.action_release("move_forward")
	check(player.global_position.z < start.z - 1.0, "forward moves -Z at yaw 0 (%s)" % player.global_position)
	player.camera_pivot.rotation.y = PI / 2.0
	var mid := player.global_position
	Input.action_press("move_forward")
	await physics_frames(30)
	Input.action_release("move_forward")
	check(player.global_position.x < mid.x - 1.0, "forward follows camera yaw (%s)" % player.global_position)


func test_jump_and_land() -> void:
	check(player.is_on_floor(), "starts on floor")
	Input.action_press("jump")
	await physics_frames(2)
	Input.action_release("jump")
	await physics_frames(8)
	check(player.global_position.y > 0.5, "jumped")
	await physics_frames(60)
	check(player.is_on_floor(), "landed")


func test_dodge_grants_invulnerability() -> void:
	var hp := int(GameState.player.hp)
	Input.action_press("dodge")
	await physics_frames(2)
	Input.action_release("dodge")
	check(player.is_dodging or player.invulnerable_time > 0.0, "dodging")
	eq(player.take_damage(50), 0, "no damage during i-frames")
	eq(int(GameState.player.hp), hp, "hp unchanged")
	await physics_frames(40)
	check(player.take_damage(50) > 0, "damage after i-frames")


func test_block_reduces_damage_and_death() -> void:
	var open_dmg := player.take_damage(30)
	player.is_blocking = true
	Input.action_press("block")
	await physics_frames(1)
	var blocked := player.take_damage(30)
	Input.action_release("block")
	check(blocked < open_dmg, "block reduces damage (%d < %d)" % [blocked, open_dmg])
	var died := [false]
	player.died.connect(func(): died[0] = true)
	await physics_frames(1)
	while not player.dead:
		player.take_damage(999)
	check(died[0], "died emitted")
	eq(int(GameState.player.hp), 0, "hp 0")
	player.revive_full()
	eq(int(GameState.player.hp), Stats.max_hp(), "revived")


func test_equipment_bonus() -> void:
	var base := Stats.attack()
	GameState.equipment["weapon"] = "WEAPON_WORLD_BLADE_001"
	eq(Stats.attack(), base + 18, "world blade attack bonus")
	GameState.equipment["accessory"] = "ITEM_MOON_PENDANT_001"
	eq(Stats.max_hp(), 105, "pendant max hp")


func test_relative_scale_c23() -> void:
	var zotik_h := 1.75 * ZotikVisual.SCALE
	check(zotik_h > 1.1 and zotik_h < 1.3, "Zotik about 1.2 m (%.2f)" % zotik_h)
	check(zotik_h < 1.8 * 0.8, "clearly smaller than human NPCs")
	eq(player.visual.part_color("PLACEHOLDER_scarf"), Color.html("#3f8a4a"), "canonical green scarf by default")
	check(player.visual.parts.has("PLACEHOLDER_shoulder_bag"), "brown shoulder bag (03_CHARACTERS)")
