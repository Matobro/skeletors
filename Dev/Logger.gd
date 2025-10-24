extends Node

class_name DevLogger
enum Level { INFO, WARN, ERROR, DEBUG, OK}

static func write_log(msg: String, level: int = Level.INFO, origin: String = ""):
	var prefix: String
	match level:
		Level.INFO:
			prefix = "[INFO]"
		Level.WARN:
			prefix = "[WARN]"
		Level.ERROR:
			prefix = "[ERROR]"
		Level.DEBUG:
			prefix = "[DEBUG]"
		Level.OK:
			prefix = "[OK]"
		_:
			prefix = "[LOG]"

	var color: String
	match level:
		Level.INFO:
			color = "white"
		Level.WARN:
			color = "yellow"
		Level.ERROR:
			color = "red"
		Level.DEBUG:
			color = "gray"
		Level.OK:
			color = "green"
		_:
			color = "gray"
		
	print_rich("[color=%s]%s %s[/color] %s" % [color, prefix, origin, msg])

static func info(msg: String, origin := ""): write_log(msg, Level.INFO, origin)
static func warn(msg: String, origin := ""): write_log(msg, Level.WARN, origin)
static func error(msg: String, origin := ""): write_log(msg, Level.ERROR, origin)
static func debug(msg: String, origin := ""): write_log(msg, Level.DEBUG, origin)
static func ok(msg: String, origin := ""): write_log(msg, Level.OK, origin)

static func run_logged(method_name: String, callable: Callable, origin := "") -> bool:
	var start_time := Time.get_ticks_usec()
	DevLogger.info("Running %s" % method_name, origin)

	var _ok := true
	var error_message := ""

	if callable.is_valid():
		callable.call()
	else:
		_ok = false
		error_message = "Invalid function"

	var elapsed := (Time.get_ticks_usec() - start_time) / 1000.0

	if _ok:
		DevLogger.ok("%s (%.2f ms)" % [method_name, elapsed], origin)
	else:
		DevLogger.error("%s failed: %s" % [method_name, error_message], origin)

	return _ok