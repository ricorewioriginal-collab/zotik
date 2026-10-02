extends Node
class_name BreakSystem

signal break_started(target)
signal break_completed(target)

var gauges := {}

func register_target(target: Node, value: float = 100.0) -> void:
    gauges[target] = value

func reduce(target: Node, amount: float) -> bool:
    if not gauges.has(target):
        register_target(target)
    gauges[target] -= amount
    if gauges[target] <= 0.0:
        gauges[target] = 0.0
        break_completed.emit(target)
        return true
    return false

func reset(target: Node, value: float = 100.0) -> void:
    gauges[target] = value
