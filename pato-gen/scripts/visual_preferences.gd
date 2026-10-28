extends RefCounted
## Read the live preference without creating or saving another profile.
static func reduced_motion(node: Node) -> bool:
	if node == null or not node.is_inside_tree(): return false
	var boot := node.get_node_or_null("/root/PatogenOnboarding")
	return bool(boot.profile.data.get("reduced_motion", false)) if boot != null else false
