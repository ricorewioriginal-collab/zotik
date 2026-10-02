class_name CharacterRig
extends Node3D
## Animated interim character (graphics pass G02) built on the CC0 KayKit
## Adventurers rigs (assets/characters/kaykit). Shared by Zotik, companions
## and NPCs: scales the model to a target height, turns it to face -Z, plays
## locomotion/action animations and can recolour the palette texture,
## hide body parts and attach extra meshes to bones. Cosmetic only.

const MODELS := {
	"rogue": "res://assets/characters/kaykit/Rogue.glb",
	"rogue_hooded": "res://assets/characters/kaykit/Rogue_Hooded.glb",
	"mage": "res://assets/characters/kaykit/Mage.glb",
	"knight": "res://assets/characters/kaykit/Knight.glb",
	"barbarian": "res://assets/characters/kaykit/Barbarian.glb",
}
## model height in its own units (head top), measured once (G02)
const MODEL_HEIGHT := 2.19
const WEAPON_MESHES := ["Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable", "1H_Sword", "1H_Sword_Offhand", "2H_Sword", "Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield", "1H_Wand", "2H_Staff", "Spellbook", "Spellbook_open", "Axe", "1H_Axe", "1H_Axe_Offhand", "2H_Axe", "Mug", "Barbarian_Round_Shield"]
const STATES := {
	"idle": "Idle", "walk": "Walking_A", "run": "Running_A", "attack": "1H_Melee_Attack_Chop",
	"attack_strong": "2H_Melee_Attack_Spin", "cast": "Spellcast_Shoot", "hit": "Hit_A",
	"dodge": "Dodge_Forward", "block": "Blocking", "death": "Death_A", "cheer": "Cheer", "interact": "Interact",
}
const LOOPING := ["idle", "walk", "run", "block"]

var kind := ""
var model: Node3D
var skeleton: Skeleton3D
var anim: AnimationPlayer
var state := ""
var _action_until := 0.0

static var _palettes := {}


static func create(model_kind: String, height: float) -> CharacterRig:
	var r := CharacterRig.new()
	r.kind = model_kind
	r.name = "Rig"
	var scene: PackedScene = load(MODELS[model_kind])
	r.model = scene.instantiate()
	r.model.name = "Model"
	r.model.scale = Vector3.ONE * (height / MODEL_HEIGHT)
	r.model.rotation.y = PI  # KayKit faces +Z, the game faces -Z
	r.add_child(r.model)
	r.skeleton = r.model.find_children("*", "Skeleton3D", true, false)[0]
	r.anim = r.model.find_children("*", "AnimationPlayer", true, false)[0]
	for a in LOOPING:
		var res := r.anim.get_animation(STATES[a])
		if res:
			res.loop_mode = Animation.LOOP_LINEAR
	r.show_weapons([])
	r.play("idle")
	return r


func meshes() -> Array:
	return skeleton.find_children("*", "MeshInstance3D", true, false)


func show_weapons(names: Array) -> void:
	for mi in meshes():
		if mi.name in WEAPON_MESHES:
			mi.visible = mi.name in names


func hide_parts(names: Array) -> void:
	for mi in meshes():
		if mi.name in names:
			mi.visible = false


## Mesh attached to a bone; position/rotation in model units (before scaling).
func attach(bone: String, node: Node3D) -> BoneAttachment3D:
	var ba := BoneAttachment3D.new()
	ba.name = "Attach_" + bone.replace(".", "_") + "_" + node.name
	ba.bone_name = bone
	skeleton.add_child(ba)
	ba.add_child(node)
	return ba


## Replaces palette colours: rules = [[predicate(Color) -> bool, Color target]]
## applied per pixel, keeping each cell's gradient (value) shape.
func recolor(key: String, rules: Array) -> void:
	var tex: Texture2D
	if _palettes.has(key):
		tex = _palettes[key]
	else:
		var src: Texture2D = _first_material().albedo_texture
		var img := src.get_image()
		if img.is_compressed():
			img.decompress()
		img.convert(Image.FORMAT_RGBA8)
		for y in img.get_height():
			for x in img.get_width():
				var c := img.get_pixel(x, y)
				for r in rules:
					if (r[0] as Callable).call(c):
						var t: Color = r[1]
						img.set_pixel(x, y, Color.from_hsv(t.h, t.s, clampf(t.v * (c.v / 0.9), 0.0, 1.0)))
						break
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
		_palettes[key] = tex
	for mi in meshes():
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.mesh.surface_get_material(s)
			if m is StandardMaterial3D:
				var dup := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_texture = tex
				mi.set_surface_override_material(s, dup)


func tint(c: Color) -> void:
	for mi in meshes():
		for s in mi.mesh.get_surface_count():
			var m: Material = mi.get_active_material(s)
			if m is StandardMaterial3D:
				var dup := (m as StandardMaterial3D).duplicate() as StandardMaterial3D
				dup.albedo_color = c
				mi.set_surface_override_material(s, dup)


func _first_material() -> StandardMaterial3D:
	for mi in meshes():
		if mi.visible and mi.mesh and mi.mesh.get_surface_count() > 0 and mi.mesh.surface_get_material(0) is StandardMaterial3D:
			return mi.mesh.surface_get_material(0)
	return StandardMaterial3D.new()


func play(s: String, speed: float = 1.0) -> void:
	if s == state and anim.is_playing():
		return
	state = s
	anim.play(STATES.get(s, "Idle"), 0.15, speed)


## One-shot action (attack, hit, dodge …); locomotion resumes afterwards.
func action(s: String, speed: float = 1.0) -> void:
	state = ""
	play(s, speed)
	var res := anim.get_animation(STATES.get(s, "Idle"))
	_action_until = Time.get_ticks_msec() / 1000.0 + (res.length / speed if res else 0.4)


func in_action() -> bool:
	return Time.get_ticks_msec() / 1000.0 < _action_until


## Picks idle/walk/run from the horizontal speed unless an action is playing.
func locomotion(speed: float, run_speed: float = 4.0) -> void:
	if in_action() or state == "death":
		return
	if speed < 0.3:
		play("idle")
	elif speed < run_speed * 0.6:
		play("walk")
	else:
		play("run")
