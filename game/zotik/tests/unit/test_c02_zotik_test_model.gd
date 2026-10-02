extends TestCase
## Hunyuan3D test model of Zotik (PLACEHOLDER): static GLB, rigged copy on the
## shared human skeleton, comparison pair next to Zotik in game.

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


func test_static_model_is_marked_placeholder_and_zotik_sized() -> void:
	var t := ZotikTestModel.create_static()
	tree.root.add_child(t)
	check(t.name.begins_with("PLACEHOLDER_"), "marked as placeholder")
	var aabb := t.mesh_instance.get_aabb()
	check(absf(aabb.size.y * t.mesh_instance.scale.y - ZotikTestModel.HEIGHT) < 0.02, "same height as ZotikVisual")
	check(aabb.position.y > -0.01 and aabb.position.y < 0.01, "feet on the ground")
	t.free()


func test_rigged_model_follows_the_human_animations() -> void:
	var t := ZotikTestModel.create_rigged()
	tree.root.add_child(t)
	await frames(2)
	var mi := t.mesh_instance
	check(mi.skin != null and mi.get_parent() == t.rig.skeleton, "skinned to the rig skeleton")
	var human_visible := t.rig.meshes().filter(func(m): return m.visible and m != mi)
	eq(human_visible.size(), 0, "no human body meshes visible")
	var sk := t.rig.skeleton
	var hand := sk.find_bone("hand_r")
	var before := sk.get_bone_global_pose(hand).origin
	t.rig.action("attack", 1.0)
	await physics_frames(20)
	check(sk.get_bone_global_pose(hand).origin.distance_to(before) > 0.05, "attack moves the hand bone")
	eq(str(t.rig.anim.current_animation), "Sword_Attack", "human attack animation plays")
	t.free()


func test_showcase_next_to_zotik_in_game() -> void:
	game.enter_area("AREA_LUN_VILLAGE", "default")
	await frames(2)
	var show: Node3D = game.area.find_child("PLACEHOLDER_ZotikTestShowcase", false, false)
	check(show != null, "comparison pair in the area")
	if show:
		check(show.global_position.distance_to(game.player.global_position) < 0.5, "placed at Zotik")
		eq(show.get_child_count(), 2, "static and rigged copy")
