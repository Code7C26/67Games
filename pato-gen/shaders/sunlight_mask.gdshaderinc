uniform bool sunlight_restricted = false;
uniform sampler2D sunlight_mask : filter_nearest, repeat_disable;
uniform vec2 sunlight_grid = vec2(67.0,32.0);
uniform float sunlight_tile_size = 32.0;
uniform float sunlight_edge_fade = 10.0;
float sun_cell(vec2 cell) {
	if (any(lessThan(cell,vec2(0.0))) || any(greaterThanEqual(cell,sunlight_grid))) return 0.0;
	return texture(sunlight_mask,(cell+0.5)/sunlight_grid).r;
}
float sunlight_at(vec2 world_point) {
	if (!sunlight_restricted) return 1.0;
	vec2 cell = floor(world_point/sunlight_tile_size);
	if (sun_cell(cell)<0.5) return 0.0;
	vec2 p = mod(world_point,sunlight_tile_size);
	float edge = sunlight_tile_size;
	if (sun_cell(cell+vec2(-1,0))<0.5) edge=min(edge,p.x);
	if (sun_cell(cell+vec2(1,0))<0.5) edge=min(edge,sunlight_tile_size-p.x);
	if (sun_cell(cell+vec2(0,-1))<0.5) edge=min(edge,p.y);
	if (sun_cell(cell+vec2(0,1))<0.5) edge=min(edge,sunlight_tile_size-p.y);
	return smoothstep(0.0,sunlight_edge_fade,edge);
}
