extends Control

## SikTiTu main menu.
##
## Flow (per design): on open the player is forced to pick a game mode
## (Singleplayer / Multiplayer) and then log in through the idm_be identity
## service before any of the four main options unlock:
##   EXPLORE -> 3D burning-forest exploration scene
##   FIGHT   -> 2D shoto fighting match
##   OPTION  -> options panel (fullscreen + training box toggle)
##   EXIT    -> quit
##
## Login talks to idm_be via the IdmAuth autoload (POST /api/v1/auth/login).
## The UI is built in code so the scene file stays trivial and the layout is
## guaranteed correct regardless of editor state.

const FOREST_SCENE := "res://scenes/exploration/forest_level.tscn"
const FIGHT_SCENE := "res://scenes/main/fight_select.tscn"

var _mode_label := ""
var _main_buttons: Array[Button] = []
var _main_vbox: VBoxContainer
var _mode_panel: Control
var _login_panel: Control
var _options_panel: Control
var _status_label: Label

var _username_edit: LineEdit
var _password_edit: LineEdit
var _login_button: Button
var _login_error: Label

var _is_multiplayer := false
var _net_panel: Control
var _net_status: Label
var _ip_edit: LineEdit


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	IdmAuth.login_succeeded.connect(_on_login_succeeded)
	IdmAuth.login_failed.connect(_on_login_failed)
	GoogleOAuth.credential_ready.connect(_on_google_credential)
	GoogleOAuth.oauth_error.connect(_on_google_error)
	_build_background()
	_build_title()
	_build_main_buttons()
	_build_options_panel()
	_build_login_panel()
	_build_net_panel()
	_build_mode_panel()
	_set_main_enabled(false)
	_show_mode_panel()


# --- Construction -----------------------------------------------------------

func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.07, 0.08, 0.12)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)


func _build_title() -> void:
	var title := Label.new()
	title.text = "SIK TI TU"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER_TOP)
	title.anchor_left = 0.0
	title.anchor_right = 1.0
	title.offset_top = 50.0
	add_child(title)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_status_label.anchor_left = 0.0
	_status_label.anchor_right = 1.0
	_status_label.offset_top = 128.0
	add_child(_status_label)


func _build_main_buttons() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_CENTER)
	vbox.offset_left = -120.0
	vbox.offset_right = 120.0
	vbox.offset_top = -80.0
	vbox.offset_bottom = 120.0
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)
	_main_vbox = vbox

	_main_buttons.append(_make_menu_button("EXPLORE", _on_explore))
	_main_buttons.append(_make_menu_button("FIGHT", _on_fight))
	_main_buttons.append(_make_menu_button("OPTION", _on_option))
	_main_buttons.append(_make_menu_button("EXIT", _on_exit))
	for b in _main_buttons:
		vbox.add_child(b)


func _make_menu_button(text: String, handler: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(240, 48)
	b.add_theme_font_size_override("font_size", 24)
	b.pressed.connect(handler)
	return b


func _build_mode_panel() -> void:
	_mode_panel = _make_centered_panel(Vector2(440, 300))

	var title := Label.new()
	title.text = "CHOOSE MODE"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_vbox_of(_mode_panel).add_child(title)

	_vbox_of(_mode_panel).add_child(_make_menu_button("SINGLEPLAYER", _on_singleplayer))
	_vbox_of(_mode_panel).add_child(_make_menu_button("MULTIPLAYER", _on_multiplayer))

	var note := Label.new()
	note.text = "Both modes require an idm_be login."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_vbox_of(_mode_panel).add_child(note)

	add_child(_mode_panel)


func _build_login_panel() -> void:
	_login_panel = _make_centered_panel(Vector2(440, 340))
	var vbox := _vbox_of(_login_panel)

	var title := Label.new()
	title.text = "LOGIN (idm_be)"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	_username_edit = LineEdit.new()
	_username_edit.placeholder_text = "Username / email"
	_username_edit.custom_minimum_size = Vector2(300, 40)
	vbox.add_child(_username_edit)

	_password_edit = LineEdit.new()
	_password_edit.placeholder_text = "Password"
	_password_edit.secret = true
	_password_edit.custom_minimum_size = Vector2(300, 40)
	_password_edit.text_submitted.connect(func(_t): _on_login_pressed())
	vbox.add_child(_password_edit)

	_login_button = _make_menu_button("LOG IN", _on_login_pressed)
	vbox.add_child(_login_button)

	vbox.add_child(_make_menu_button("LOGIN WITH GOOGLE", _on_google_pressed))

	vbox.add_child(_make_menu_button("BACK", _on_login_back))

	_login_error = Label.new()
	_login_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_login_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_login_error.add_theme_color_override("font_color", Color(1.0, 0.5, 0.5))
	vbox.add_child(_login_error)

	_login_panel.visible = false
	add_child(_login_panel)


func _build_net_panel() -> void:
	_net_panel = _make_centered_panel(Vector2(460, 320))
	var vbox := _vbox_of(_net_panel)

	var title := Label.new()
	title.text = "MULTIPLAYER"
	title.add_theme_font_size_override("font_size", 26)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	vbox.add_child(_make_menu_button("HOST (wait for P2)", _on_host))

	_ip_edit = LineEdit.new()
	_ip_edit.placeholder_text = "Host IP (e.g. 127.0.0.1)"
	_ip_edit.text = "127.0.0.1"
	_ip_edit.custom_minimum_size = Vector2(300, 40)
	vbox.add_child(_ip_edit)

	vbox.add_child(_make_menu_button("JOIN", _on_join))

	_net_status = Label.new()
	_net_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_net_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_net_status)

	vbox.add_child(_make_menu_button("BACK", _on_net_back))

	_net_panel.visible = false
	add_child(_net_panel)

	NetManager.peer_connected.connect(_on_net_peer)
	NetManager.connection_succeeded.connect(_on_net_connected_client)
	NetManager.connection_failed.connect(func(): _net_status.text = "Connection failed.")


func _on_host() -> void:
	var err := NetManager.host()
	_net_status.text = "Hosting on port %d — waiting for Player 2..." % NetManager.DEFAULT_PORT if err == OK else "Host failed (error %d)." % err


func _on_join() -> void:
	var err := NetManager.join(_ip_edit.text.strip_edges())
	_net_status.text = "Connecting to %s..." % _ip_edit.text if err == OK else "Join failed (error %d)." % err


func _on_net_peer(_id: int) -> void:
	# Host side: Player 2 arrived.
	_net_status.text = "Player 2 connected! Entering fight setup..."
	_set_main_enabled(true)
	get_tree().change_scene_to_file("res://scenes/main/fight_select.tscn")


func _on_net_connected_client() -> void:
	# Client side: connected to host.
	_net_status.text = "Connected to host! Entering fight setup..."
	_set_main_enabled(true)
	get_tree().change_scene_to_file("res://scenes/main/fight_select.tscn")


func _on_net_back() -> void:
	NetManager.disconnect_net()
	_show_mode_panel()


func _build_options_panel() -> void:
	_options_panel = _make_centered_panel(Vector2(440, 280))
	var vbox := _vbox_of(_options_panel)

	var title := Label.new()
	title.text = "OPTIONS"
	title.add_theme_font_size_override("font_size", 28)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var fs := CheckButton.new()
	fs.text = "Fullscreen"
	fs.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	fs.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fs)

	var boxes := CheckButton.new()
	boxes.text = "Show hit/hurt boxes (training)"
	boxes.button_pressed = GameConfig.show_boxes
	boxes.toggled.connect(_on_boxes_toggled)
	vbox.add_child(boxes)

	vbox.add_child(_make_menu_button("BACK", _on_options_back))

	_options_panel.visible = false
	add_child(_options_panel)


# --- Panel helpers ----------------------------------------------------------

func _make_centered_panel(size: Vector2) -> Control:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.custom_minimum_size = size
	panel.offset_left = -size.x / 2.0
	panel.offset_right = size.x / 2.0
	panel.offset_top = -size.y / 2.0
	panel.offset_bottom = size.y / 2.0

	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 24.0
	vbox.offset_right = -24.0
	vbox.offset_top = 24.0
	vbox.offset_bottom = -24.0
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	panel.add_child(vbox)
	return panel


func _vbox_of(panel: Control) -> VBoxContainer:
	return panel.get_node("VBox")


func _show_mode_panel() -> void:
	_mode_panel.visible = true
	_login_panel.visible = false
	_status_label.text = "Select a mode to continue"


func _set_main_enabled(enabled: bool) -> void:
	# Hide the main options entirely during the mode/login gate so the overlay
	# panels read cleanly; show + enable them once logged in.
	if _main_vbox != null:
		_main_vbox.visible = enabled
	for b in _main_buttons:
		b.disabled = not enabled


# --- Mode selection ---------------------------------------------------------

func _on_singleplayer() -> void:
	GameConfig.online = false
	GameConfig.p2_is_cpu = true
	_is_multiplayer = false
	_mode_label = "Singleplayer"
	_go_to_login()


func _on_multiplayer() -> void:
	GameConfig.p2_is_cpu = false
	_is_multiplayer = true
	_mode_label = "Multiplayer"
	_go_to_login()


func _go_to_login() -> void:
	_mode_panel.visible = false
	_login_error.text = ""
	if IdmAuth.is_logged_in:
		_finish_login()
		return
	_login_panel.visible = true
	_status_label.text = "Mode: %s — please log in" % _mode_label
	_username_edit.grab_focus()


# --- Login ------------------------------------------------------------------

func _on_login_pressed() -> void:
	_login_error.text = ""
	_login_button.disabled = true
	_login_button.text = "LOGGING IN..."
	IdmAuth.login(_username_edit.text, _password_edit.text)


func _on_google_pressed() -> void:
	_login_error.text = ""
	_login_button.disabled = true
	GoogleOAuth.begin()


func _on_google_credential(credential: String) -> void:
	_login_button.text = "LOGGING IN..."
	IdmAuth.login_google(credential)


func _on_google_error(message: String) -> void:
	_login_button.disabled = false
	_login_error.text = message


func _on_login_succeeded(user: Dictionary) -> void:
	_login_button.disabled = false
	_login_button.text = "LOG IN"
	_finish_login(str(user.get("name", user.get("username", ""))))


func _on_login_failed(reason: String) -> void:
	_login_button.disabled = false
	_login_button.text = "LOG IN"
	_login_error.text = reason


func _finish_login(display_name := "") -> void:
	_login_panel.visible = false
	var who := display_name if display_name != "" else str(IdmAuth.user.get("name", ""))
	_status_label.text = "%s — %s" % [_mode_label, who] if who != "" else _mode_label
	if _is_multiplayer:
		# Multiplayer needs a peer connection before the main options unlock.
		_net_status.text = ""
		_net_panel.visible = true
	else:
		_set_main_enabled(true)


func _on_login_back() -> void:
	_show_mode_panel()


# --- Main menu actions ------------------------------------------------------

func _on_explore() -> void:
	get_tree().change_scene_to_file(FOREST_SCENE)


func _on_fight() -> void:
	get_tree().change_scene_to_file(FIGHT_SCENE)


func _on_option() -> void:
	_options_panel.visible = true


func _on_exit() -> void:
	get_tree().quit()


# --- Options actions --------------------------------------------------------

func _on_fullscreen_toggled(pressed: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)


func _on_boxes_toggled(pressed: bool) -> void:
	GameConfig.show_boxes = pressed


func _on_options_back() -> void:
	_options_panel.visible = false
