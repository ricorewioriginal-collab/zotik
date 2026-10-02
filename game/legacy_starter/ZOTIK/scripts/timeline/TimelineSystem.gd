extends Node
class_name TimelineSystem

signal action_ready(actor)

# Core Build-01 timing model. Every combatant accumulates readiness.
# Fast actions receive a lower delay; strong actions can later use larger delays.
var readiness := {}

func register_actor(actor: Node, speed: float = 100.0) -> void:
    readiness[actor] = 100.0

func advance(delta: float) -> void:
    for actor in readiness.keys():
        if not is_instance_valid(actor):
            readiness.erase(actor)
            continue
        readiness[actor] += delta * 10.0
        if readiness[actor] >= 100.0:
            readiness[actor] = 0.0
            action_ready.emit(actor)
