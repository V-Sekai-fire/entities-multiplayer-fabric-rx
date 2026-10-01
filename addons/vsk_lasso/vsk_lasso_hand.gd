# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
# The lasso on one controller, on lasso.elf: the trigger arms a pointing cone that snaps to the best
# target in the lasso group (a VSKLassoTarget or a canvas plane's control anchor), this hand's stick hops the
# snap to a neighbour, and grab acts on it: a target flies to the hand, a control is pressed.
extends Node3D
class_name VSKLassoHand

const ELF := preload("res://addons/vsk_lasso/lasso.elf")

@export var controller: XRController3D
@export var arm_action: StringName = &"interact"
@export var flick_action: StringName = &"grab"
@export var redirect_action: StringName = &"rotate"
@export var min_snap: float = 0.5
@export var snap_increase: float = 2.0
@export var haptic_amplitude: float = 1.0
@export var haptic_seconds: float = 0.01

var current = null
var secondary = null
var props: VSKLassoProps = null
var _sandbox: Object = null
var _redirect_ready: bool = true


func _ready() -> void:
	if controller == null and get_parent() is XRController3D:
		controller = get_parent()
		redirect_action = &"move" if String(controller.tracker).contains("left") else &"rotate"
	if not ClassDB.class_exists(&"Sandbox"):
		push_error("VSKLassoHand: the godot-sandbox addon is not loaded, so the lasso stays off")
		set_process(false)
		return
	_sandbox = ClassDB.instantiate(&"Sandbox")
	_sandbox.set_program(ELF)
	add_child(_sandbox)
	props = VSKLassoProps.new()
	add_child(props)


static func transform12(p_transform: Transform3D) -> PackedFloat64Array:
	var b: Basis = p_transform.basis
	var o: Vector3 = p_transform.origin
	return PackedFloat64Array([b.x.x, b.x.y, b.x.z, b.y.x, b.y.y, b.y.z, b.z.x, b.z.y, b.z.z, o.x, o.y, o.z])


static func pack(p_targets: Array, p_locked: Object) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for t in p_targets:
		var p: Vector3 = t.global_position
		var shown: float = 1.0 if t.snapping_enabled and t.is_visible_in_tree() else 0.0
		out.append_array([p.x, p.y, p.z, t.size, t.snapping_power, shown, 1.0 if t == p_locked else 0.0])
	return out


## The cone from `p_source` (pointing along -z): [first, second, first score, second score].
func snap(p_source: Transform3D, p_targets: Array, p_strength: float, p_lock: bool) -> Array:
	var locked: Object = current if p_lock else null
	var r: PackedFloat32Array = _sandbox.vmcall("lasso_snap", transform12(p_source), pack(p_targets, locked),
			p_targets.find(current), snap_increase, p_strength, p_lock)
	if r.size() < 4:
		return [null, null, 0.0, 0.0]
	return [_at(p_targets, int(r[0])), _at(p_targets, int(r[1])), r[2], r[3]]


## The target the stick moves the snap to, seen from `p_view`; the current one when none qualifies.
func redirect(p_view: Transform3D, p_targets: Array, p_stick: Vector2):
	var i: int = _sandbox.vmcall("lasso_redirect", p_targets.find(current), transform12(p_view),
			pack(p_targets, null), p_stick.x, p_stick.y)
	var hop = _at(p_targets, i)
	return hop if hop else current


func set_snap(p_first, p_second) -> void:
	if p_first != current:
		if current:
			current.stop_hover()
		if p_first:
			p_first.hover()
			if controller:
				controller.trigger_haptic_pulse(&"haptic", 0.0, haptic_amplitude, haptic_seconds, 0.0)
	current = p_first
	secondary = p_second


func _process(_delta: float) -> void:
	var strength: float = 0.0
	if controller:
		strength = controller.get_float(arm_action)
		if strength <= 0.0 and controller.is_button_pressed(arm_action):
			strength = 1.0
	var targets: Array = get_tree().get_nodes_in_group(VSKLassoTarget.GROUP)
	if strength <= 0.0 or targets.is_empty():
		set_snap(null, null)
		props.show_snap(global_transform, null, null)
		return
	var stick: Vector2 = controller.get_vector2(redirect_action)
	var hopped: bool = false
	if _redirect_ready and current and stick.length() > 0.5:
		var camera: Camera3D = get_viewport().get_camera_3d()
		set_snap(redirect(camera.global_transform if camera else global_transform, targets, stick), secondary)
		hopped = true
	_redirect_ready = stick.length() < 0.2
	if not hopped:
		var holding: bool = current != null and current.interacting and current.lock_snap_on_interact
		var picked: Array = snap(controller.global_transform, targets, strength, holding)
		set_snap(picked[0] if picked[0] and picked[2] > min_snap else null, picked[1])
	if current:
		if controller.is_button_pressed(flick_action):
			current.interact(controller)
		else:
			current.stop_interact()
	props.show_snap(controller.global_transform, current, secondary)


static func _at(p_targets: Array, p_index: int):
	return p_targets[p_index] if p_index >= 0 and p_index < p_targets.size() else null
