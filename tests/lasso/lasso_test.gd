# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
# The lasso headless: snap and redirect through lasso.elf, and a flicked target's landing at the hand,
# each beside a control that must fail. Needs an engine that loads the godot-sandbox addon.
#   godot --headless --path <project> --script res://tests/lasso/lasso_test.gd
extends SceneTree

var _failed := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(p_name: String, p_ok: bool, p_detail: String) -> void:
	print("%s %s: %s" % ["PASS" if p_ok else "FAIL", p_name, p_detail])
	_failed += 0 if p_ok else 1


func _target(p_at: Vector3, p_frozen: bool) -> VSKLassoTarget:
	var t := VSKLassoTarget.new()
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	t.add_child(shape)
	t.freeze = p_frozen
	t.position = p_at
	root.add_child(t)
	return t


func _run() -> void:
	if not ClassDB.class_exists(&"Sandbox"):
		print("FAIL setup: the godot-sandbox addon is not loaded")
		quit(1)
		return
	var hand := VSKLassoHand.new()
	root.add_child(hand)
	hand.set_process(false)
	var centre := _target(Vector3(0, 0, -5), true)
	var left := _target(Vector3(-2, 0, -5), true)
	var right := _target(Vector3(2, 0, -5), true)
	var targets: Array = [centre, left, right]
	var ahead := Transform3D.IDENTITY

	var picked: Array = hand.snap(ahead, targets, 1.0, false)
	_check("unit snap", picked[0] == centre, "aimed straight ahead, first %s (score %.3f)" % [_name(picked[0], targets), picked[2]])
	hand.current = centre
	var hop: VSKLassoTarget = hand.redirect(ahead, targets, Vector2(1, 0))
	_check("unit redirect", hop == right, "stick right from the centre goes to %s" % _name(hop, targets))

	_check("falsifiable redirect", hop != left, "a wrong expectation (left) is told apart from %s" % _name(hop, targets))
	centre.snapping_enabled = false
	var without: Array = hand.snap(ahead, targets, 1.0, false)
	_check("falsifiable snap", without[0] != centre, "with the centre disabled the first is %s" % _name(without[0], targets))
	centre.snapping_enabled = true
	_check("falsifiable empty", hand.snap(ahead, [], 1.0, false)[0] == null, "no targets snaps to nothing")

	hand.current = null
	var again: Array = hand.snap(ahead, targets, 1.0, false)
	hand.current = centre
	var rest: VSKLassoTarget = hand.redirect(ahead, targets, Vector2())
	_check("identity", again == picked and rest == centre, "the same aim gives %s and %s twice, and a stick at rest stays on the centre" % [_name(again[0], targets), _name(again[1], targets)])

	for t in targets:
		t.queue_free()
	var palm := Node3D.new()
	palm.position = Vector3(0, 1.4, 0)
	root.add_child(palm)
	var flown := await _fly(palm, true)
	var kept := await _fly(palm, false)
	_check("flick lands", flown < 0.05, "after 1.5 s the target is %.0f mm from the hand (%s)" % [flown * 1000.0, _household(flown * 1000.0)])
	_check("flick control", kept > 3.0, "with flicking off it stays %.2f m away" % kept)
	print("RESULT: %s (%d FAIL)" % ["PASS" if _failed == 0 else "FAIL", _failed])
	quit(1 if _failed > 0 else 0)


func _fly(p_palm: Node3D, p_flick: bool) -> float:
	var t := _target(Vector3(0, 0, -4), false)
	t.flick_to_hand = p_flick
	await physics_frame
	for i in 90:
		t.interact(p_palm)
		await physics_frame
	var d: float = t.global_position.distance_to(p_palm.global_position)
	t.queue_free()
	return d


func _name(p_target: Object, p_targets: Array) -> String:
	return ["centre", "left", "right"][p_targets.find(p_target)] if p_target in p_targets else "none"


func _household(p_mm: float) -> String:
	for anchor: Array in [[0.76, "a credit card"], [1.52, "a penny"], [7.0, "a pencil"], [21.2, "a nickel"], [42.7, "a golf ball"]]:
		if p_mm <= anchor[0] * 1.5:
			return "about %s" % anchor[1]
	return "more than a golf ball"
