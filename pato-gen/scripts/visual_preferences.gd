extends RefCounted
## Read the live preference without creating or saving another profile.
static func reduced_motion(node: Node) -> bool:
	var boot := node.get_node_or_null("/root/PatogenOnboarding")
	return bool(boot.profile.data.get("reduced_motion", false)) if boot != null else false
