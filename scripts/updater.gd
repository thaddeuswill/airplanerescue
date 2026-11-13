extends Node
## Auto-update from GitHub Releases. On launch (installed builds only) it asks GitHub for the
## latest release of the game's repo; if its tag (v1.2.3) is newer than this build's
## application/config/version and it has this platform's download attached ("*-setup.exe" on
## Windows, "*-mac.zip" on a Mac), it offers it. Windows: download the setup into user://update/,
## start it silently, quit. Mac: open the download in the browser (the app is unsigned, so the
## player drags the new one into Applications). Saves are in user://, so updates never touch them.

signal available(version: String, notes: String)  # main shows the offer; call install() on yes

const LATEST := "https://api.github.com/repos/thaddeuswill/airplanerescue/releases/latest"
const ASSET_PREFIX := "https://github.com/thaddeuswill/airplanerescue/releases/download/"  # only ever run files from here

var setup_url := ""
var setup_name := ""
var _http: HTTPRequest


func check() -> void:
	if OS.has_feature("editor"):
		return  # running from the project, not an installed build
	clean()
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_latest)
	_http.request(LATEST, ["User-Agent: AirplaneRescue-updater", "Accept: application/vnd.github+json"])


func _on_latest(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		return  # offline, rate-limited or no releases yet: just play
	var data = JSON.parse_string(body.get_string_from_utf8())
	if not data is Dictionary:
		return
	var tag: String = str(data.get("tag_name", "")).trim_prefix("v")
	var mine: String = ProjectSettings.get_setting("application/config/version", "0.0.0")
	if not newer(tag, mine):
		return
	for a in data.get("assets", []):
		var url: String = str(a.get("browser_download_url", ""))
		if url.begins_with(ASSET_PREFIX) and url.ends_with(asset_suffix()):
			setup_url = url
			setup_name = str(a.get("name", "AirplaneRescue-setup.exe")).get_file()
			available.emit(tag, str(data.get("body", "")))
			return


## The setup that brought us here has done its job: about 90 MB each, and every version has a new name.
static func clean() -> void:
	if DirAccess.dir_exists_absolute("user://update"):
		for f in DirAccess.get_files_at("user://update"):
			DirAccess.remove_absolute("user://update/" + f)


## The release file this platform installs from.
static func asset_suffix() -> String:
	return "-mac.zip" if OS.has_feature("macos") else "-setup.exe"


## True if version a is newer than b ("1.10.0" > "1.9.3"). Missing parts count as 0.
static func newer(a: String, b: String) -> bool:
	var pa := a.split(".")
	var pb := b.split(".")
	for i in maxi(pa.size(), pb.size()):
		var x := int(pa[i]) if i < pa.size() else 0
		var y := int(pb[i]) if i < pb.size() else 0
		if x != y:
			return x > y
	return false


## Downloads the setup and hands over to it. done(ok, message) reports a failure (on success the game quits).
func install(done: Callable) -> void:
	if OS.has_feature("macos"):  # no silent installer for an unsigned app: hand the zip to the browser
		OS.shell_open(setup_url)
		done.call(true, "The new version is downloading in your browser. Unzip it and drag Airplane Rescue into Applications, replacing the old one. Your saved game stays.")
		return
	DirAccess.make_dir_recursive_absolute("user://update")
	var path := ProjectSettings.globalize_path("user://update/" + setup_name)
	var dl := HTTPRequest.new()
	dl.download_file = path
	add_child(dl)
	dl.request_completed.connect(func(result, code, _h, _b):
		if result != HTTPRequest.RESULT_SUCCESS or code != 200 or not FileAccess.file_exists(path):
			done.call(false, "Download failed (%d). Try again later." % code)
			return
		# Silent install over this copy; the setup closes the game and relaunches it once itself.
		var pid := OS.create_process(path, ["/SILENT", "/SP-", "/CLOSEAPPLICATIONS"])
		if pid <= 0:
			done.call(false, "Couldn't start the installer.")
			return
		get_tree().quit())
	dl.request(setup_url, ["User-Agent: AirplaneRescue-updater"])
