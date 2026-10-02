extends Node
class_name CombatController

signal attack_started
signal damage_dealt(amount: int)

@export var attack_damage: int = 8
@export var attack_cooldown: float = 0.55
var cooldown := 0.0

func _process(delta: float) -> void:
    cooldown = maxf(0.0, cooldown - delta)

func try_attack(target: Node3D) -> bool:
    if cooldown > 0.0 or target == null:
        return false
    cooldown = attack_cooldown
    attack_started.emit()
    if target.has_method("take_damage"):
        target.take_damage(attack_damage)
        damage_dealt.emit(attack_damage)
    return true
