# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
# The lasso on a canvas plane, headless: it snaps to a button, the stick hops to the next one, and the
# lasso's press clicks it, each beside a control that must fail. Needs the godot-sandbox addon.
#   godot --headless --path <project> --script res://tests/lasso/lasso_canvas_test.gd
extends SceneTree

var _failed := 0
var _pressed := {}


func _initialize() -> void:
	_run.call_deferred()


func _check(p_name: String, p_ok: bool, p_detail: String) -> void:
	print("%s %s: %s" % ["PASS" if p_ok else "FAIL", p_name, p_detail])
	_failed += 0 if p_ok else 1


func _run() -> void:
	if not ClassDB.class_exists(&"Sandbox"):
		print("FAIL setup: the godot-sandbox addon is not loaded")
		quit(1)
		return
	var plane := CanvasPlane.new()
	plane.canvas_width = 400
	plane.canvas_height = 200
	plane.position = Vector3(0, 0, -1)
	var row := HBoxContainer.new()
	row.size = Vector2(400, 200)
	var buttons: Array[Button] = []
	for label in ["left", "right"]:
		var b := Button.new()
		b.text = label
		b.custom_minimum_size = Vector2(160, 120)
		b.pressed.connect(func(): _pressed[label] = _pressed.get(label, 0) + 1)
		row.add_child(b)
		buttons.append(b)
	plane.add_child(row)
	row.owner = plane
	root.add_child(plane)
	var hand := VSKLassoHand.new()
	root.add_child(hand)
	hand.set_process(false)
	for i in 6:
		await process_frame

	var targets: Array = root.get_tree().get_nodes_in_group(Canvas3DAnchor.LASSO_GROUP)
	_check("anchors", targets.size() == 2, "%d lasso targets on the plane for 2 buttons" % targets.size())
	if targets.size() != 2:
		quit(1)
		return
	var left = targets[0] if targets[0].canvas_item == buttons[0] else targets[1]
	var right = targets[1] if left == targets[0] else targets[0]
	var aim := Transform3D.IDENTITY.looking_at(left.global_position, Vector3.UP)
	var picked: Array = hand.snap(aim, targets, 1.0, false)
	_check("unit snap", picked[0] == left, "aimed at the left button, first is %s (score %.3f)" % [_label(picked[0], left, right), picked[2]])
	hand.current = left
	var hop = hand.redirect(aim, targets, Vector2(1, 0))
	_check("unit redirect", hop == right, "stick right goes to %s" % _label(hop, left, right))
	right.interact(hand)
	right.stop_interact()
	await process_frame
	_check("unit click", _pressed.get("right", 0) == 1 and _pressed.get("left", 0) == 0, "the lasso's press clicked right %d time(s), left %d" % [_pressed.get("right", 0), _pressed.get("left", 0)])

	buttons[1].disabled = true
	var without: Array = hand.snap(Transform3D.IDENTITY.looking_at(right.global_position, Vector3.UP), targets, 1.0, false)
	_check("falsifiable disabled", without[0] != right, "with right disabled, aiming at it snaps to %s" % _label(without[0], left, right))
	buttons[1].disabled = false
	var away: Array = hand.snap(Transform3D.IDENTITY.looking_at(Vector3(0, 0, 1), Vector3.UP), targets, 1.0, false)
	_check("falsifiable away", away[2] < hand.min_snap, "aimed away from the plane the best score is %.3f, under %.1f" % [away[2], hand.min_snap])
	var before: int = _pressed.get("left", 0)
	for pressed in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.global_position = plane.global_to_viewport(left.global_position)
		ev.position = ev.global_position
		plane.get_control_viewport().push_unhandled_input(ev)
	await process_frame
	_check("falsifiable unhandled", _pressed.get("left", 0) == before, "the old push_unhandled_input path pressed left %d time(s)" % (_pressed.get("left", 0) - before))

	hand.current = null
	var again: Array = hand.snap(aim, targets, 1.0, false)
	_check("identity", again == picked, "the same aim gives %s twice" % _label(again[0], left, right))
	print("RESULT: %s (%d FAIL)" % ["PASS" if _failed == 0 else "FAIL", _failed])
	quit(1 if _failed > 0 else 0)


func _label(p_target, p_left, p_right) -> String:
	return "left" if p_target == p_left else ("right" if p_target == p_right else "none")
