# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
# A target the lasso snaps to. Interacting flicks it to the hand on an arc that lands in about a
# second under gravity, then homes in; restored from sar1_vr_manager's snapping point (d2f7b20^).
extends RigidBody3D
class_name VSKLassoTarget

const GROUP := &"vsk_lasso_targets"

signal snap_hover
signal snap_hover_stop
signal snap_interact
signal snap_interact_stop

@export var snapping_power: float = 1.0
@export var snapping_enabled: bool = true
@export var size: float = 0.3
@export var flick_to_hand: bool = true
@export var flick_power: float = 1.0
@export var lock_snap_on_interact: bool = true

var flick_target: Node3D = null
var interacting: bool = false


func _enter_tree() -> void:
	add_to_group(GROUP)


func _exit_tree() -> void:
	remove_from_group(GROUP)


func hover() -> void:
	snap_hover.emit()


func stop_hover() -> void:
	stop_interact()
	snap_hover_stop.emit()


func interact(p_hand: Node3D) -> void:
	if flick_to_hand:
		flick_target = p_hand
	if not interacting:
		interacting = true
		snap_interact.emit()
	if sleeping:
		sleeping = false
		linear_velocity = flick_velocity()


func stop_interact() -> void:
	if interacting:
		interacting = false
		flick_target = null
		snap_interact_stop.emit()


func flick_velocity() -> Vector3:
	if flick_target == null:
		return Vector3()
	var to: Vector3 = flick_target.global_position
	var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
	var rise: float = to.y - global_position.y
	var across: Vector3 = Vector3(to.x - global_position.x, 0.0, to.z - global_position.z)
	if gravity <= 0.0:
		return Vector3(across.x, rise, across.z).normalized() * flick_power
	var time: float = 1.0
	var vertical: float = 0.0
	var extra: float = 0.0
	if rise > 0.0:
		extra = pow(across.length() / (across.length() + rise), 4) * flick_power
		var climb: float = sqrt(2.0 * gravity * rise)
		vertical = climb + extra * gravity / 2.0
		time = climb / gravity + extra
	else:
		extra = pow(across.length() / (across.length() - rise), 4) / flick_power
		vertical = rise / gravity + rise / maxf(across.length(), 0.001) + extra * gravity / 2.0
		time = sqrt(absf(rise / gravity)) + extra / 1.5
	return across.normalized() * (across.length() / maxf(time, 0.001)) + Vector3(0.0, vertical, 0.0)


func _integrate_forces(p_state: PhysicsDirectBodyState3D) -> void:
	if not (flick_to_hand and interacting and flick_target):
		return
	var to_hand: Vector3 = flick_target.global_position - global_position
	p_state.linear_velocity = flick_velocity() if to_hand.length() > size + 0.001 else to_hand * 10.0
