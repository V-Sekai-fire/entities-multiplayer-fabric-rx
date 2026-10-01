# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
# The lasso's scrappy CSG props: a ring around the snapped target, a fainter one on the runner-up, and
# a laser from the hand to the snap.
extends Node3D
class_name VSKLassoProps

const SNAPPED := Color(254.0 / 255.0, 95.0 / 255.0, 85.0 / 255.0, 1.0)
const RUNNER_UP := Color(247.0 / 255.0, 247.0 / 255.0, 1.0, 0.35)

var primary := CSGTorus3D.new()
var runner_up := CSGTorus3D.new()
var laser := CSGCylinder3D.new()


func _ready() -> void:
	top_level = true
	for pair: Array in [[primary, SNAPPED], [runner_up, RUNNER_UP], [laser, SNAPPED]]:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = pair[1]
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if pair[1].a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
		pair[0].material = mat
		pair[0].visible = false
		add_child(pair[0])
	laser.radius = 0.004
	laser.sides = 6


func show_snap(p_source: Transform3D, p_first: VSKLassoTarget, p_second: VSKLassoTarget) -> void:
	_ring(primary, p_source.origin, p_first)
	_ring(runner_up, p_source.origin, p_second)
	laser.visible = p_first != null
	if p_first:
		var from: Vector3 = p_source.origin
		var to: Vector3 = p_first.global_position
		laser.height = from.distance_to(to)
		laser.global_transform = _along(from, to)


func _ring(p_ring: CSGTorus3D, p_from: Vector3, p_target: VSKLassoTarget) -> void:
	p_ring.visible = p_target != null
	if p_target:
		p_ring.inner_radius = p_target.size * 0.9
		p_ring.outer_radius = p_target.size * 1.1
		var at: Vector3 = p_target.global_position
		p_ring.global_transform = _along(p_from, at).translated_local(Vector3(0.0, p_from.distance_to(at) * 0.5, 0.0))


## Centred on the segment's midpoint with +y along it, as CSG cylinders and tori stand.
static func _along(p_from: Vector3, p_to: Vector3) -> Transform3D:
	var dir: Vector3 = (p_to - p_from).normalized()
	var side: Vector3 = dir.cross(Vector3.UP if absf(dir.y) < 0.99 else Vector3.RIGHT).normalized()
	return Transform3D(Basis(side, dir, side.cross(dir)), (p_from + p_to) * 0.5)
