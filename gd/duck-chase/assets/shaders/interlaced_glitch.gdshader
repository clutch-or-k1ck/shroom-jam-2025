shader_type canvas_item;

float rand(float seed) {
	return fract(sin(dot(vec2(seed), vec2(12.9898,78.233))) * 43758.5453);
}

vec2 displace(vec2 co, float seed, float seed2) {
	vec2 shift = vec2(0);
	if (rand(seed) > 0.5) {
		shift += 0.1 * vec2(2. * (0.5 - rand(seed2)));
	}
	if (rand(seed2) > 0.6) {
		if (co.y > 0.5) {
			shift.x *= rand(seed2 * seed);
		}
	}
	return shift;
}

vec4 interlace(vec2 co, vec4 col) {
    if (int(co.y) % 3 == 0) {
        return col * ((sin(TIME * 4.) * 0.1) + 0.75) + (rand(TIME) * 0.05);
    }
    return col;
}

void fragment() {
	// vec2 uv = FRAGCOORD.xy/(1.0/SCREEN_PIXEL_SIZE);
	vec2 uv = UV;
	
	vec2 rDisplace = vec2(0);
	vec2 gDisplace = vec2(0);
	vec2 bDisplace = vec2(0);
	
	if (rand(TIME) > 0.95) {
		rDisplace = displace(uv, TIME * 2., 2. + TIME);
		gDisplace = displace(uv, TIME * 3., 3. + TIME);
		bDisplace = displace(uv, TIME * 5., 5. + TIME);
	}
	
	rDisplace.x += 0.005 * (0.5 - rand(TIME * 37. * uv.y));
    gDisplace.x += 0.007 * (0.5 - rand(TIME * 41. * uv.y));
    bDisplace.x += 0.0011 * (0.5 - rand(TIME * 53. * uv.y));

    rDisplace.y += 0.001 * (0.5 - rand(TIME * 37. * uv.x));
    gDisplace.y += 0.001 * (0.5 - rand(TIME * 41. * uv.x));
    bDisplace.y += 0.001 * (0.5 - rand(TIME * 53. * uv.x));
	
	// Output to screen
    float rcolor = texture(TEXTURE, uv.xy + rDisplace).r;
    float gcolor = texture(TEXTURE, uv.xy + gDisplace).g;
    float bcolor = texture(TEXTURE, uv.xy + bDisplace).b;

    COLOR = interlace(UV, vec4(rcolor, gcolor, bcolor, 1));
}
