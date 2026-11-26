# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
extends SceneTree
## Run: godot --headless --script tests/presence/presence_client_test.gd -- --relay=PATH [--control=half] [--port=N]. See docs/presence.md.

const Client := preload("../../addons/vsk_presence/presence_client.gd")
const RelayProcess := preload("relay_process.gd")
const FRAME_BYTES := 1200
const FRAMES_MAX := 6000


func _initialize() -> void:
	var control := _argument("--control=", "")
	var port := int(_argument("--port=", "48200"))
	var path := _argument("--relay=", "")
	if path.is_empty():
		_finish(false, "--relay=PATH to zone_serve of transport-zone-relay is required")
		return
	var problems := await _run(port, path)
	if control.is_empty():
		_finish(problems.is_empty(), "no problems" if problems.is_empty() else "; ".join(problems))
	else:
		_finish(not problems.is_empty(), "the planted %s defect was %s" % [control, "found: " + problems[0] if not problems.is_empty() else "NOT found"])


func _relay(p_path: String) -> Object:
	var process := RelayProcess.new()
	process.path = p_path
	return process


func _run(p_port: int, p_path: String) -> Array:
	var relay := _relay(p_path)
	if relay.start(p_port) != OK:
		return ["the relay could not start on port %d" % p_port]
	for _frame in FRAMES_MAX:
		if relay.ready():
			break
		await process_frame
	if not relay.ready():
		relay.stop()
		return ["the relay on port %d did not become ready" % p_port]
	var people := [Client.new(), Client.new()]
	var hello := [_frames(0, 0), _frames(1, 0)]
	var sent := [_frames(0, 1), _frames(1, 1)]
	for index in 2:
		people[index].open("127.0.0.1", p_port)
	await _send_and_wait(people, hello, relay, [0, 0], 2)
	var got := await _send_and_wait(people, sent, relay, [2, 2], 0, hello)
	relay.stop()
	for person in people:
		person.close()
	return _compare(got, sent)


func _send_and_wait(p_people: Array, p_sent: Array, p_relay: Object, p_wanted: Array, p_total := 0, p_late := [[], []]) -> Array:
	for index in 2:
		p_people[index].send(p_sent[index][0], p_sent[index][1])
	var got := [[], []]
	for _frame in FRAMES_MAX:
		await process_frame
		p_relay.poll()
		for index in 2:
			for frame in p_people[index].receive():
				if not p_late[1 - index].has(frame.bytes):
					got[index].append(frame)
		if got[0].size() >= p_wanted[0] and got[1].size() >= p_wanted[1] and got[0].size() + got[1].size() >= p_total:
			break
	return got


func _compare(p_got: Array, p_sent: Array) -> Array:
	var problems := []
	for index in 2:
		var expected: Array = p_sent[1 - index]
		var frames: Array = p_got[index]
		if frames.size() != 2:
			problems.append("person %d got %d frames, expected 2" % [index, frames.size()])
			continue
		for frame in frames:
			if frame.bytes != expected[frame.half]:
				problems.append("person %d got a frame of half %d that is not the other person's" % [index, frame.half])
	return problems


func _frames(p_person: int, p_round: int) -> Array:
	var frames := []
	for half in 2:
		var bytes := PackedByteArray()
		bytes.resize(FRAME_BYTES)
		for offset in FRAME_BYTES:
			bytes[offset] = (p_person * 64 + half * 32 + p_round * 16 + offset) % 251
		frames.append(bytes)
	return frames


func _argument(p_prefix: String, p_default: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(p_prefix):
			return argument.trim_prefix(p_prefix)
	return p_default


func _finish(p_ok: bool, p_what: String) -> void:
	print("RESULT: %s: %s" % ["PASS" if p_ok else "FAIL", p_what])
	quit(0 if p_ok else 1)
