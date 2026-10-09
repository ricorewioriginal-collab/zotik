extends SceneTree
## One-off bake: extracts the five weapon meshes the human characters hold
## out of the KayKit adventurer models (about 3.6 MB each, with skeleton and
## animations) into small standalone resources under assets/characters/weapons/.
## The web and Android builds then no longer need the KayKit models at all
## (see export_presets.cfg, exclude_filter).
##
## Run once after changing the sources:
##   godot --headless --path game/zotik -s res://tools/bake_weapon_meshes.gd

const KAYKIT := "res://assets/characters/kaykit/%s.glb"
const OUT_DIR := "res://assets/characters/weapons/"
## weapon key -> [source model, mesh node name]
const SOURCES := {
	"staff": ["Mage", "2H_Staff"],
	"crossbow": ["Rogue", "2H_Crossbow"],
	"axe": ["Barbarian", "1H_Axe"],
	"shield": ["Barbarian", "Barbarian_Round_Shield"],
	"sword": ["Knight", "1H_Sword"],
}


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	var failed := 0
	for key in SOURCES:
		var src: Array = SOURCES[key]
		var scene: Node = (load(KAYKIT % src[0]) as PackedScene).instantiate()
		var found: Array = scene.find_children(src[1], "MeshInstance3D", true, false)
		if found.is_empty():
			push_error("weapon mesh %s not found in %s" % [src[1], src[0]])
			failed += 1
			scene.free()
			continue
		# deep copy so that nothing keeps pointing into the imported .glb
		var mesh := (found[0] as MeshInstance3D).mesh.duplicate(true) as Mesh
		mesh.resource_path = ""
		var path: String = OUT_DIR + str(key) + ".res"
		var err: int = ResourceSaver.save(mesh, path, ResourceSaver.FLAG_COMPRESS)
		var deps: PackedStringArray = ResourceLoader.get_dependencies(path)
		var leaks: Array = Array(deps).filter(func(d): return str(d).contains("kaykit"))
		print("%s -> %s (%s, %d surface(s), kaykit references: %d)" % [key, path, error_string(err), mesh.get_surface_count(), leaks.size()])
		if err != OK or not leaks.is_empty():
			failed += 1
		scene.free()
	quit(1 if failed > 0 else 0)
