extends Node

## Login client for the idm_be identity service (Go backend, port 7700).
##
## Contract (from idm_be controllers/auth_c.go):
##   POST {base_url}/api/v1/auth/login
##     body: {"app_id": "...", "username": "...", "password": "..."}
##     200  -> {"status":200,"message":"success","data":{"token","name","username",...}}
##     4xx  -> {"status":4xx,"message":"error","data":"<reason string>"}
## Username/password are sent as plaintext; idm_be accepts plaintext (its AES
## decrypt falls back to the raw value for non-encrypted callers).
##
## Configure base_url / app_id via the exported-like vars below or the project
## setting "siktitu/idm_base_url" if you deploy idm_be elsewhere.

signal login_succeeded(user: Dictionary)
signal login_failed(reason: String)

const LOGIN_PATH := "/api/v1/auth/login"
const GOOGLE_PATH := "/api/v1/auth/google"

## Sesi disimpan lokal supaya tak perlu login ulang tiap buka aplikasi. File ada di
## user:// (Android/desktop: lokasi data app-private). Berisi {token, user}. Token JWT
## punya exp — saat restore, sesi kedaluwarsa dibuang agar user login lagi dengan bersih.
const SESSION_PATH := "user://idm_session.json"

var base_url := "http://127.0.0.1:7700"
var app_id := "scm_app"   # siktitu lives under the SCM app family in idm_be

var token := ""
var user := {}
var is_logged_in := false

var _http: HTTPRequest
var _busy := false


func _ready() -> void:
	# Allow overriding the backend location without editing code.
	if ProjectSettings.has_setting("siktitu/idm_base_url"):
		base_url = str(ProjectSettings.get_setting("siktitu/idm_base_url"))
	if ProjectSettings.has_setting("siktitu/idm_app_id"):
		app_id = str(ProjectSettings.get_setting("siktitu/idm_app_id"))
	_http = HTTPRequest.new()
	add_child(_http)
	_http.request_completed.connect(_on_request_completed)
	_load_session()


## Begin a login. Emits login_succeeded(user) or login_failed(reason).
func login(username: String, password: String) -> void:
	if _busy:
		login_failed.emit("Login sedang berjalan, tunggu sebentar.")
		return
	if username.strip_edges() == "" or password == "":
		login_failed.emit("Username dan password wajib diisi.")
		return
	_busy = true
	var url := base_url.rstrip("/") + LOGIN_PATH
	var body := JSON.stringify({
		"app_id": app_id,
		"username": username,
		"password": password,
	})
	var headers := ["Content-Type: application/json"]
	var err := _http.request(url, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		_busy = false
		login_failed.emit("Tidak bisa menghubungi server (error %d)." % err)


## Log in with a Google credential (an OpenID id_token from Google, or a
## "dummy:<email>" string when idm_be runs with GOOGLE_SSO_DUMMY=1 for testing).
## idm_be verifies it and resolves the user by email. Emits the same signals.
func login_google(credential: String) -> void:
	if _busy:
		login_failed.emit("Login sedang berjalan, tunggu sebentar.")
		return
	if credential.strip_edges() == "":
		login_failed.emit("Kredensial Google kosong.")
		return
	_busy = true
	var url := base_url.rstrip("/") + GOOGLE_PATH
	var body := JSON.stringify({"credential": credential, "app_id": app_id})
	var err := _http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)
	if err != OK:
		_busy = false
		login_failed.emit("Tidak bisa menghubungi server (error %d)." % err)


func logout() -> void:
	token = ""
	user = {}
	is_logged_in = false
	_clear_session()


# --- Persistensi sesi lokal -------------------------------------------------

func _save_session() -> void:
	var f := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if f == null:
		push_warning("IdmAuth: gagal menyimpan sesi (%d)" % FileAccess.get_open_error())
		return
	f.store_string(JSON.stringify({"token": token, "user": user}))
	f.close()


func _clear_session() -> void:
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(SESSION_PATH)


## Muat sesi tersimpan saat start. Sesi dengan token kedaluwarsa (atau korup) dibuang
## supaya pengguna login ulang alih-alih membawa token mati.
func _load_session() -> void:
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var f := FileAccess.open(SESSION_PATH, FileAccess.READ)
	if f == null:
		return
	var raw := f.get_as_text()
	f.close()
	var parsed = JSON.parse_string(raw)
	if typeof(parsed) != TYPE_DICTIONARY:
		_clear_session()
		return
	var tok := str(parsed.get("token", ""))
	if tok == "" or _token_expired(tok):
		_clear_session()
		return
	token = tok
	var u = parsed.get("user", {})
	user = u if typeof(u) == TYPE_DICTIONARY else {}
	is_logged_in = true


## true bila JWT sudah lewat exp (atau tak bisa dibaca). Hanya mengecek payload `exp`;
## verifikasi tanda tangan tetap di idm_be saat token dipakai untuk request terproteksi.
func _token_expired(jwt: String) -> bool:
	var parts := jwt.split(".")
	if parts.size() < 2:
		return true
	var payload_b64 : String = parts[1]
	# base64url -> base64 standar + padding.
	payload_b64 = payload_b64.replace("-", "+").replace("_", "/")
	while payload_b64.length() % 4 != 0:
		payload_b64 += "="
	var bytes := Marshalls.base64_to_raw(payload_b64)
	if bytes.is_empty():
		return true
	var parsed = JSON.parse_string(bytes.get_string_from_utf8())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("exp"):
		return false  # tak ada exp → anggap tak kedaluwarsa, biar BE yang memutuskan
	return Time.get_unix_time_from_system() >= float(parsed["exp"])


func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	_busy = false
	if result != HTTPRequest.RESULT_SUCCESS:
		login_failed.emit("Gagal terhubung ke idm_be (%s). Pastikan server jalan di %s." % [result, base_url])
		return
	var text := body.get_string_from_utf8()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		login_failed.emit("Respons server tidak valid (HTTP %d)." % response_code)
		return
	var data = parsed.get("data")
	if response_code == 200 and typeof(data) == TYPE_DICTIONARY and str(data.get("token", "")) != "":
		token = str(data.get("token", ""))
		user = data
		is_logged_in = true
		_save_session()
		login_succeeded.emit(user)
	else:
		# idm_be puts the human-readable reason in `data` (string) on failure.
		var reason := str(data) if typeof(data) == TYPE_STRING and str(data) != "" else str(parsed.get("message", "Login gagal"))
		login_failed.emit(reason)
