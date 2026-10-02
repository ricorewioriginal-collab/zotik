extends TestCase

var game: GameRoot


func before_each() -> void:
	GameState.reset_new_game()
	Customization.ensure_valid()
	Dialogue.reset()
	App.pending_load = false
	App.goto_scene(App.SCENE_GAME_ROOT)
	await frames(3)
	game = tree.current_scene
	await finish_dialogues()


func test_zotik_rig_is_a_fox_not_a_human() -> void:
	var rig: CharacterRig = game.player.visual.rig
	check(rig != null and rig.anim != null, "animated rig")
	var human_head := rig.meshes().filter(func(m): return m.name.begins_with("Sphere") or m.name.begins_with("Face"))
	eq(human_head.size(), 0, "no human head (C01: fox head on the human rig)")
	for p in ["PLACEHOLDER_ear_l", "PLACEHOLDER_tail", "PLACEHOLDER_muzzle", "PLACEHOLDER_scarf"]:
		check(game.player.visual.parts[p].get_parent() is BoneAttachment3D, p + " follows a bone")
	var arms: MeshInstance3D = rig.skeleton.find_child("Male_Ranger_Arms", true, false)
	var fur := Customization.color("fur_shade")
	var skin_is_fur := false
	for i in arms.mesh.get_surface_count():
		var m := arms.get_surface_override_material(i) as StandardMaterial3D
		if m and m.albedo_color.is_equal_approx(fur):
			skin_is_fur = true
	check(skin_is_fur, "exposed skin uses the fur shade")


func test_zotik_animation_follows_state() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var rig: CharacterRig = game.player.visual.rig
	eq(rig.state, "idle", "idle at rest")
	game.player.velocity = Vector3(0, 0, -6)
	game.player.visual.animate(game.player)
	eq(rig.state, "run", "running")
	game.player.attack_cooldown = 0.0
	game.player.attack()
	check(rig.in_action() and rig.anim.current_animation == "Sword_Attack", "attack animation")
	game.player.take_damage(1)
	game.player.dead = true
	game.player.visual.animate(game.player)
	eq(rig.state, "death", "death animation")


func test_companions_and_npcs_use_rigs() -> void:
	for m in ["PARTY_LYRA_001", "PARTY_NIA_001", "PARTY_ROVAN_001"]:
		Effects.apply({"type": "join_party", "id": m})
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await physics_frames(2)
	var lyra: Companion = game.companions["PARTY_LYRA_001"]
	eq(lyra.rig.kind, "human_female_peasant", "Lyra uses a human model (C01)")
	check(lyra.rig.skeleton.find_child("Weapon_staff", true, false) != null, "with her staff")
	check(lyra.rig.anim.has_animation("Idle_Loop") and lyra.rig.state == "idle", "animated from the shared library")
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	check(mira.find_children("*", "CharacterRig", true, false).size() == 1, "NPC rig")
