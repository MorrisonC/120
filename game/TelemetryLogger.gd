extends Node

var log_file_path: String
var _file: FileAccess

func _ready() -> void:
    var time_dict = Time.get_datetime_dict_from_system()
    var timestamp = "%04d%02d%02d_%02d%02d%02d" % [
        time_dict["year"], time_dict["month"], time_dict["day"],
        time_dict["hour"], time_dict["minute"], time_dict["second"]
    ]
    DirAccess.make_dir_absolute("res://telemetry")
    log_file_path = "res://telemetry/run_%s.jsonl" % timestamp
    _file = FileAccess.open(log_file_path, FileAccess.WRITE)

func log_event(event: String, data: Dictionary = {}) -> void:
    if not _file:
        push_warning("TelemetryLogger: File not open.")
        return
    var entry = {
        "t": Time.get_ticks_msec(),
        "event": event,
        "data": data
    }
    _file.store_line(JSON.stringify(entry))
    _file.flush()

func get_latest_log_path() -> String:
    return log_file_path
