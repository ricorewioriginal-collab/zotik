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
	var head: MeshInstance3D = rig.skeleton.find_child("Rogue_Head", true, false)
	check(head != null and not head.visible, "human head hidden")
	for p in ["PLACEHOLDER_ear_l", "PLACEHOLDER_tail", "PLACEHOLDER_muzzle", "PLACEHOLDER_scarf"]:
		check(game.player.visual.parts[p].get_parent() is BoneAttachment3D, p + " follows a bone")
	var body: MeshInstance3D = rig.skeleton.find_child("Rogue_Body", true, false)
	var tex: Texture2D = (body.get_surface_override_material(0) as StandardMaterial3D).albedo_texture
	var img := tex.get_image()
	var fur := Customization.color("fur_shade")
	check(absf(Color(img.get_pixel(10, 10)).h - fur.h) < 0.03, "skin palette recoloured to the fur shade")


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
	check(rig.in_action() and rig.anim.current_animation == "1H_Melee_Attack_Chop", "attack animation")
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
	eq(lyra.rig.kind, "mage", "Lyra is a mage")
	check(lyra.rig.skeleton.find_child("2H_Staff", true, false).visible, "with her staff")
	check(not lyra.rig.skeleton.find_child("Spellbook", true, false).visible, "other props hidden")
	var mira: Npc = game.area.entities["NPC_MIRA_001"]
	check(mira.find_children("*", "CharacterRig", true, false).size() == 1, "NPC rig")
