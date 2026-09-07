PATOGEN MALL V5 — export/integration handoff

Standalone test:
1. Open the project in Godot 4.x.
2. Run res://main.tscn.
3. The yellow diamond is only a map-test placeholder player.

Team integration:
Use res://PatogenMall_MapOnly.tscn inside the project that already contains the real player, sprites, mechanics and HUD.

Do not keep a second copy of this map's collision geometry in the destination project. mall_main.gd creates the collision at runtime.

The actual player should remain a CharacterBody2D with its own CollisionShape2D and should use collision layer 1, or the PLAYER_LAYER constant in mall_layout.gd should be changed accordingly.

The map has no bot NavigationRegion in V5. NavigationMarkers are present so teammate AI can be added later without changing the layout.

For exporting the teammates' final game, keep their existing project.godot/export_presets.cfg. This map package does not require editor plugins or the Summer Engine runtime.
