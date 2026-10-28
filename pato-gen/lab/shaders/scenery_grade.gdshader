shader_type canvas_item;
uniform float ambient : hint_range(0.0, 1.0) = 0.64;
uniform vec3 shadow_tint = vec3(-0.035, 0.025, 0.05);
uniform vec3 highlight_tint = vec3(0.045, 0.02, -0.025);
uniform float saturation : hint_range(0.0, 1.5) = 0.88;
uniform bool clouds = false;
uniform float cloud_intensity : hint_range(0.0, 0.5) = 0.28;
uniform float effect_time = 0.0;
uniform float cloud_speed = 12.0;
uniform vec4 cloud_a = vec4(550.0,430.0,380.0,180.0);
uniform vec4 cloud_b = vec4(1670.0,790.0,350.0,170.0);
uniform float sheen_intensity : hint_range(0.0,0.5) = 0.0;
uniform float sheen_speed = 10.0;
uniform float sheen_width = 65.0;
uniform float sheen_spacing = 900.0;
uniform vec3 sheen_color : source_color = vec3(0.55,0.78,0.88);
varying vec2 world;
varying vec4 tint;
void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy; tint = COLOR; }
void fragment() {
	vec4 c=texture(TEXTURE,UV) * tint;
	float v=dot(c.rgb,vec3(0.2126,0.7152,0.0722));
	c.rgb = mix(vec3(v), c.rgb, saturation);
	c.rgb += shadow_tint*(1.0-smoothstep(0.08,0.45,v));
	c.rgb += highlight_tint*smoothstep(0.50,0.95,v);
	c.rgb = max(c.rgb, vec3(0.0)) * ambient;
	float stripe = abs(mod(world.x+world.y*0.55-effect_time*sheen_speed,sheen_spacing)-sheen_spacing*0.5);
	float sheen = (1.0-smoothstep(sheen_width*0.35,sheen_width,stripe))*smoothstep(0.28,0.7,v)*sheen_intensity;
	c.rgb += sheen_color*sheen;
	if (clouds) {
		vec2 p = world + vec2(effect_time * cloud_speed, 0.0);
		p.x = mod(p.x, 2400.0);
		float a = 1.0-smoothstep(0.45, 1.0, length((p-cloud_a.xy)/cloud_a.zw));
		float b = 1.0-smoothstep(0.45, 1.0, length((p-cloud_b.xy)/cloud_b.zw));
		c.rgb *= 1.0-max(a,b)*cloud_intensity;
	}
	COLOR=c;
}
