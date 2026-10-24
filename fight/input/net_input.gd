class_name NetInput
extends InputSource

## Input source fed by frames received over the network (NetManager.remote_frame).
## Used for the remote-controlled fighter during an online match.

func poll() -> InputFrame:
	var f := InputFrame.new()
	var d: Dictionary = NetManager.remote_frame
	if d.is_empty():
		return f
	f.left = d.get("left", false)
	f.right = d.get("right", false)
	f.up = d.get("up", false)
	f.down = d.get("down", false)
	f.lp = d.get("lp", false)
	f.mp = d.get("mp", false)
	f.hp = d.get("hp", false)
	f.lk = d.get("lk", false)
	f.mk = d.get("mk", false)
	f.hk = d.get("hk", false)
	return f

## Serialize a local InputFrame to a dict for NetManager.send_frame().
static func to_dict(f: InputFrame) -> Dictionary:
	return {
		"left": f.left, "right": f.right, "up": f.up, "down": f.down,
		"lp": f.lp, "mp": f.mp, "hp": f.hp, "lk": f.lk, "mk": f.mk, "hk": f.hk,
	}
