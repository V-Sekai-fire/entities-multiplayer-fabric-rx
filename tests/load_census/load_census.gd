# SPDX-License-Identifier: MIT
# Copyright (c) 2026 K. S. Ernest (iFire) Lee
extends SceneTree
## Loads every script, scene and resource and fails on any error, naming the file that printed it.
## With `-- --control`, a planted parse error must be caught and named instead.

const _OWN_DIR := "res://tests/load_census"
const _PLANTED := "res://tests/load_census_planted.gd"
const _EXTENSIONS := ["gd", "tscn", "tres"]
const _AFTER_LOADS := "(after the loads)"
const _FRAMES_AFTER_LOADS := 2


class CensusLogger extends Logger:
	var current := ""
	var errors := {}
	var warnings := {}
	var _mutex := Mutex.new()

	func record(p_into: Dictionary, p_text: String) -> void:
		_mutex.lock()
		if not p_into.has(current):
			p_into[current] = []
		p_into[current].append(p_text)
		_mutex.unlock()

	func _log_error(_function: String, p_file: String, p_line: int, p_code: String, p_rationale: String,
			_editor_notify: bool, p_error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		var text := p_code if p_rationale.is_empty() else "%s: %s" % [p_code, p_rationale]
		record(warnings if p_error_type == ERROR_TYPE_WARNING else errors, "%s (%s:%d)" % [text, p_file, p_line])

	func _log_message(_message: String, _error: bool) -> void:
		pass


var _logger := CensusLogger.new()
var _files := PackedStringArray()
var _ignored := PackedStringArray()
var _counts := {}
var _frames := 0
var _control := false


func _walk(p_dir: String) -> void:
	for directory in DirAccess.get_directories_at(p_dir):
		var path := p_dir.path_join(directory)
		if FileAccess.file_exists(path.path_join(".gdignore")):
			_ignored.append(path)
		elif not directory.begins_with(".") and path != _OWN_DIR:
			_walk(path)
	for file in DirAccess.get_files_at(p_dir):
		if file.get_extension() in _EXTENSIONS:
			_files.append(p_dir.path_join(file))


func _initialize() -> void:
	_control = "--control" in OS.get_cmdline_user_args()
	if _control:
		var planted := FileAccess.open(_PLANTED, FileAccess.WRITE)
		planted.store_string("extends Node\nfunc planted(:\n")
		planted.close()
	OS.add_logger(_logger)
	_walk("res://")
	_files.sort()
	for path in _files:
		_logger.current = path
		_counts[path.get_extension()] = _counts.get(path.get_extension(), 0) + 1
		var resource := ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if resource == null:
			_logger.record(_logger.errors, "the load returned null")
		elif resource is PackedScene and not (resource as PackedScene).can_instantiate():
			_logger.record(_logger.errors, "the scene cannot be instantiated")
	_logger.current = _AFTER_LOADS


func _process(_delta: float) -> bool:
	_frames += 1
	if _frames < _FRAMES_AFTER_LOADS:
		return false
	OS.remove_logger(_logger)
	if _control:
		for path in [_PLANTED, _PLANTED + ".uid"]:
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	quit(_report())
	return false


func _report() -> int:
	for path in _logger.errors:
		print("FAIL %s" % path)
		for text in _logger.errors[path]:
			print("     %s" % text)
	var warning_count := 0
	for path in _logger.warnings:
		warning_count += _logger.warnings[path].size()
		print("warn %s" % path)
		for text in _logger.warnings[path]:
			print("     %s" % text)
	print("skipped %d directories with .gdignore: %s" % [_ignored.size(), ", ".join(_ignored)])
	print("checked %s: %d with errors, %d warnings" % [_counts, _logger.errors.size(), warning_count])
	if _control:
		var caught: bool = _logger.errors.has(_PLANTED)
		print("%s control: the planted parse error is caught and named" % ("ok  " if caught else "FAIL"))
		return 0 if caught else 1
	print("RESULT: %s" % ("PASS" if _logger.errors.is_empty() else "FAIL"))
	return 0 if _logger.errors.is_empty() else 1
