# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
class_name VskPresenceClient
extends RefCounted
## One person's end of the zone relay. The contract it keeps is in docs/presence.md.

const FIRST_HALF := 0
const SECOND_HALF := 1
const FRAME_BYTES_MAX := 1472

var _socket := PacketPeerUDP.new()
var _host := ""
var _port := 0


func open(p_host: String, p_port: int) -> Error:
	_host = p_host
	_port = p_port
	return _socket.bind(0)


func send(p_first: PackedByteArray, p_second: PackedByteArray) -> Error:
	var result := _put(p_first, _port)
	if result != OK:
		return result
	return _put(p_second, _port + 1)


func receive() -> Array:
	var frames := []
	while _socket.get_available_packet_count() > 0:
		var bytes := _socket.get_packet()
		var half := _socket.get_packet_port() - _port
		if half == FIRST_HALF or half == SECOND_HALF:
			frames.append({"half": half, "bytes": bytes})
	return frames


func close() -> void:
	_socket.close()


func _put(p_frame: PackedByteArray, p_port: int) -> Error:
	if p_frame.is_empty() or p_frame.size() > FRAME_BYTES_MAX:
		return ERR_INVALID_PARAMETER
	var result := _socket.set_dest_address(_host, p_port)
	if result != OK:
		return result
	return _socket.put_packet(p_frame)
