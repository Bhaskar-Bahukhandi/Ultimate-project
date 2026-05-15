extends Node
## UIStack — Singleton that prevents multiple modal UIs from opening simultaneously.
##
## Usage:
##   if UIStack.try_open("pause_screen"):
##       # open the pause screen
##   UIStack.close("pause_screen")
##
## Only one modal can be active at a time. Non-modal overlays (HUD, combat)
## are not managed here — this is strictly for full-screen / focus-stealing panels.

## Emitted when the active modal changes (empty string = nothing open).
signal modal_changed(modal_name: String)

## The currently active modal panel name, or "" if none.
var _active_modal: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep running when tree is paused


## Try to open a modal. Returns `true` if the request is granted (nothing
## else is open), or `false` if another modal already has focus.
func try_open(modal_name: String) -> bool:
	if _active_modal != "" and _active_modal != modal_name:
		print("[UIStack] Blocked '%s' — '%s' is already open" % [modal_name, _active_modal])
		return false
	_active_modal = modal_name
	modal_changed.emit(_active_modal)
	return true


## Force-open a modal, closing whatever was open before.
func force_open(modal_name: String) -> void:
	if _active_modal != "" and _active_modal != modal_name:
		print("[UIStack] Force-closing '%s' for '%s'" % [_active_modal, modal_name])
	_active_modal = modal_name
	modal_changed.emit(_active_modal)


## Close the given modal. If it is not the active one, this is a no-op.
func close(modal_name: String) -> void:
	if _active_modal == modal_name:
		_active_modal = ""
		modal_changed.emit(_active_modal)


## Returns `true` when any modal is open.
func is_any_open() -> bool:
	return _active_modal != ""


## Returns `true` when the specified modal is the active one.
func is_open(modal_name: String) -> bool:
	return _active_modal == modal_name


## Returns the name of the currently active modal (empty string if none).
func get_active() -> String:
	return _active_modal
