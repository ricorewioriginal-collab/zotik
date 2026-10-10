extends SceneTree
## Bakes the procedural music into assets/music/<mood>.wav (run when MusicSynth changes):
## Copy this file to game/zotik/tests/, run
##   godot --headless --path game/zotik -s res://tests/bake_music.gd
## remove the copy, then import once more; the .wav.import files keep edit/loop_mode=2 (forward).
func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute("res://assets/music")
	for id in MusicSynth.MOODS:
		var s := MusicSynth.new(id)
		var stream := MusicSynth.build_loop(id)
		var err := stream.save_to_wav("res://assets/music/%s.wav" % id)
		print("BAKED ", id, " ", err, " ", stream.data.size() / 2, " samples")
	quit()
