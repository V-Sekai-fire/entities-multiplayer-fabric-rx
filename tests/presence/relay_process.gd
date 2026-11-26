# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
class_name PresenceRelayProcess
extends RefCounted
## The real zone relay as a child process. See docs/presence.md.

const TICKS := "640"

var path := ""
var _pid := -1
var _port := 0


func start(p_port: int) -> Error:
	_port = p_port
	if not _free(p_port) or not _free(p_port + 1):
		return ERR_ALREADY_IN_USE
	_pid = OS.create_process(path, [str(p_port), TICKS, "0"])
	return OK if _pid > 0 else ERR_CANT_CREATE


func poll() -> void:
	pass


func ready() -> bool:
	return OS.is_process_running(_pid) and not _free(_port) and not _free(_port + 1)


func _free(p_port: int) -> bool:
	var probe := PacketPeerUDP.new()
	var bound := probe.bind(p_port, "127.0.0.1") == OK
	probe.close()
	return bound


func stop() -> void:
	if _pid > 0:
		OS.kill(_pid)
