extends Node
## Fails a self-test run that can't start, instead of letting it hang (T1).
##
## The self-test's own watchdog lives in selftest.gd, and the self-test is started by main.gd: if
## either doesn't parse, nothing starts and Godot sits idle with no output until something outside
## kills it. This autoload depends on nothing else in the project, so it loads even when they don't.
## In a self-test run it loads every script and fails the run at once, naming any that won't parse;
## and if the self-test hasn't started a minute after launch, for any other reason, it fails it.
## Outside a self-test run it does nothing.

const START_LIMIT := 60.0  # seconds from launch for the self-test to report it has started

var _waited := 0.0
var _on := false


func _ready() -> void:
	_on = "--self-test" in OS.get_cmdline_user_args()
	if not _on:
		set_process(false)
		return
	var broken: PackedStringArray = []
	var dir := DirAccess.open("res://scripts")
	if dir:
		for f in dir.get_files():
			if not f.ends_with(".gd") or f == "boot_guard.gd":
				continue
			var sc = load("res://scripts/" + f)
			if sc == null or not (sc as Script).can_instantiate():
				broken.append(f)
	if not broken.is_empty():
		_fail("load: %s won't parse (see the SCRIPT ERROR lines above)" % ", ".join(broken))


func _process(delta: float) -> void:
	_waited += delta
	if _waited > START_LIMIT and not Engine.has_meta("selftest_started"):
		_fail("never started: the self-test didn't begin within %d s of launch" % int(START_LIMIT))


func _fail(why: String) -> void:
	set_process(false)
	print("SELF-TEST FAIL " + why)
	get_tree().quit(1)
