extends Node

## "Login with Google" — mirrors cashiry's flow (cashiry_next/lib/googleOAuth.ts):
## OpenID Connect IMPLICIT flow (response_type=id_token, no client_secret / no code
## exchange). Google returns the id_token in the URL fragment; we hand it to
## IdmAuth.login_google() -> idm_be POST /api/v1/auth/google (same backend cashiry
## uses, which verifies tokeninfo + aud == GOOGLE_CLIENT_ID + email_verified).
##
## Reuses the SAME web OAuth client id as cashiry (default below). For it to work:
##   * idm_be must run with GOOGLE_CLIENT_ID = this same client id.
##   * This client's "Authorized redirect URIs" in Google Cloud Console must include
##     the loopback this native app uses, e.g. http://127.0.0.1:8780
##     (web OAuth clients allow http://127.0.0.1 / http://localhost redirects).
## Override the id via project setting siktitu/google_client_id if needed.
##
## TEST without any Google setup: set siktitu/google_test_email (or call
## begin_test(email)) and run idm_be with GOOGLE_SSO_DUMMY=1.

signal credential_ready(credential: String)
signal oauth_error(message: String)

const AUTH_ENDPOINT := "https://accounts.google.com/o/oauth2/v2/auth"
const SCOPES := "openid email profile"
# Same web client as cashiry PROD (idm_be GOOGLE_CLIENT_ID_PROD / cashiry_next
# NEXT_PUBLIC_GOOGLE_CLIENT_ID_PROD). Harus cocok dengan GOOGLE_CLIENT_ID yang dipakai
# idm_be yang sedang jalan (aud id_token diperiksa di BE). CATATAN: agar login Google nyata
# berfungsi, client PROD ini WAJIB memuat redirect loopback http://127.0.0.1:8780 di
# "Authorized redirect URIs" Google Cloud Console. Untuk uji tanpa Google, pakai jalur dummy.
const DEFAULT_CLIENT_ID := "933722571245-ijblmgdpa896mnd9ge17j3hh69em5igu.apps.googleusercontent.com"
const REDIRECT_PORT := 8780

var client_id := DEFAULT_CLIENT_ID
var test_email := ""

var _server: TCPServer
var _redirect := ""
var _nonce := ""


func _ready() -> void:
	set_process(false)
	if ProjectSettings.has_setting("siktitu/google_client_id"):
		var v := str(ProjectSettings.get_setting("siktitu/google_client_id"))
		if v != "":
			client_id = v
	if ProjectSettings.has_setting("siktitu/google_test_email"):
		test_email = str(ProjectSettings.get_setting("siktitu/google_test_email"))


## UI entry point. Uses the dummy test path when a test email is configured,
## otherwise launches the real implicit flow.
func begin() -> void:
	if test_email != "":
		begin_test(test_email)
		return
	_start_flow()


func begin_test(email: String) -> void:
	credential_ready.emit("dummy:" + email)


func _start_flow() -> void:
	_server = TCPServer.new()
	if _server.listen(REDIRECT_PORT, "127.0.0.1") != OK:
		oauth_error.emit("Tidak bisa membuka loopback :%d untuk OAuth." % REDIRECT_PORT)
		return
	_redirect = "http://127.0.0.1:%d" % REDIRECT_PORT
	_nonce = _rand_hex(24)
	var state := "login:" + _rand_hex(16)
	var params := [
		"client_id=" + client_id.uri_encode(),
		"redirect_uri=" + _redirect.uri_encode(),
		"response_type=id_token",
		"scope=" + SCOPES.uri_encode(),
		"nonce=" + _nonce,
		"state=" + state,
		"prompt=select_account",
	]
	OS.shell_open(AUTH_ENDPOINT + "?" + "&".join(params))
	set_process(true)


func _process(_delta: float) -> void:
	if _server == null or not _server.is_connection_available():
		return
	var conn := _server.take_connection()
	var req := _read_request_line(conn)
	# Google puts id_token in the URL FRAGMENT, which the browser does NOT send to
	# us. First hit ("GET / ...") gets a tiny page that copies the fragment into a
	# query and reloads to /capture; the second hit carries the id_token.
	if req.find("/capture?") != -1:
		var id_token := _query_value(req, "id_token")
		var err := _query_value(req, "error")
		_respond(conn, "<h2>SikTiTu</h2><p>Login selesai. Kembali ke game.</p>")
		_stop()
		if err != "":
			oauth_error.emit("Google menolak: " + err)
		elif id_token == "":
			oauth_error.emit("Tidak menerima id_token dari Google.")
		else:
			credential_ready.emit(id_token)
	else:
		# Serve the fragment-forwarding page.
		var js := "<script>location.replace('/capture?'+location.hash.substring(1));</script>"
		_respond(conn, js)


# --- helpers ----------------------------------------------------------------

func _read_request_line(conn: StreamPeerTCP) -> String:
	var text := ""
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 1000:
		conn.poll()
		var n := conn.get_available_bytes()
		if n > 0:
			text += conn.get_utf8_string(n)
			if text.find("\r\n") != -1:
				break
	return text

func _respond(conn: StreamPeerTCP, body_html: String) -> void:
	var html := "<html><body style='font-family:sans-serif'>%s</body></html>" % body_html
	var resp := "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [html.length(), html]
	conn.put_data(resp.to_utf8_buffer())
	conn.poll()
	conn.disconnect_from_host()

func _stop() -> void:
	set_process(false)
	if _server != null:
		_server.stop()
		_server = null

func _rand_hex(n: int) -> String:
	var bytes := Crypto.new().generate_random_bytes(n)
	return bytes.hex_encode()

func _query_value(request_line: String, key: String) -> String:
	var q := request_line.find("?")
	if q == -1:
		return ""
	var rest := request_line.substr(q + 1)
	var sp := rest.find(" ")
	if sp != -1:
		rest = rest.substr(0, sp)
	for pair in rest.split("&"):
		var kv := pair.split("=")
		if kv.size() == 2 and kv[0] == key:
			return kv[1].uri_decode()
	return ""
