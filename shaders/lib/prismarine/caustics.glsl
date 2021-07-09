float h(vec3 pos){
	float noise  = texture2D(noisetex, (pos.xz + vec2(frametime) * 0.5 - pos.y) / WATER_CAUSTICS_AMOUNT * 1.5).r;
		  noise += texture2D(noisetex, (pos.xz - vec2(frametime) * 0.5 - pos.y) / WATER_CAUSTICS_AMOUNT * 3.0).r*0.8;
		  noise -= texture2D(noisetex, (pos.xz + vec2(frametime) * 0.5 + pos.y) / WATER_CAUSTICS_AMOUNT * 4.5).r*0.6;
		  noise += texture2D(noisetex, (pos.xz - vec2(frametime) * 0.5 - pos.y) / WATER_CAUSTICS_AMOUNT * 7.0).r*0.4;
		  noise -= texture2D(noisetex, (pos.xz + vec2(frametime) * 0.5 + pos.y) / WATER_CAUSTICS_AMOUNT * 14.0).r*0.2;
	
	return noise;
}

float getCaustics(vec3 pos){
	float h0 = h(pos);
	float h1 = h(pos + vec3(1, 0, 0));
	float h2 = h(pos + vec3(-1, 0, 0));
	float h3 = h(pos + vec3(0, 0, 1));
	float h4 = h(pos + vec3(0, 0, -1));
	
	float caustic = max((1 - abs(0.5 - h0)) * (1 - (abs(h1 - h2) + abs(h3 - h4))), 0);
	caustic = max(pow(caustic, 3.5), 0) * 16;
	
	return caustic;
}

float getFlickering(vec3 pos){
	float h0 = h(pos);
	float h1 = h(pos + vec3(1, 0, 0));
	float h2 = h(pos + vec3(-1, 0, 0));
	
	float flicker = max((1 - abs(0.5 - h0)) * (1 - (abs(h1 - h2))), 0);
	flicker = max(pow(flicker, 3.5), 0) * BLOCKLIGHT_FLICKERING_STRENGTH;
	
	return flicker;
}

float getDistribution(vec3 pos){
	float h0 = h(pos);
	float h1 = h(pos + vec3(1, 0, 0));
	float h2 = h(pos + vec3(-1, 0, 0));
	
	float distribution = max((1 - abs(0.5 - h0)) * (1 - (abs(h1 - h2))), 0);
	distribution = max(pow(distribution, 4), 0) * 8;
	
	return distribution;
}