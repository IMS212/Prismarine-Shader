float waterH(vec3 pos){
	float noise  = texture2D(noisetex, (pos.xz + vec2(frameTimeCounter) * 0.5 - pos.y) / WATER_CAUSTICS_AMOUNT * 1.5).r;
		  noise += texture2D(noisetex, (pos.xz - vec2(frameTimeCounter) * 0.5 - pos.y) / WATER_CAUSTICS_AMOUNT * 3.0).r*0.8;
		  noise -= texture2D(noisetex, (pos.xz + vec2(frameTimeCounter) * 0.5 + pos.y) / WATER_CAUSTICS_AMOUNT * 4.5).r*0.6;
		  noise += texture2D(noisetex, (pos.xz - vec2(frameTimeCounter) * 0.5 - pos.y) / WATER_CAUSTICS_AMOUNT * 7.0).r*0.4;
		  noise -= texture2D(noisetex, (pos.xz + vec2(frameTimeCounter) * 0.5 + pos.y) / WATER_CAUSTICS_AMOUNT * 14.0).r*0.2;
	
	return noise;
}

float getCaustics(vec3 pos){
	float h0 = waterH(pos);
	float h1 = waterH(pos + vec3(1, 0, 0));
	float h2 = waterH(pos + vec3(-1, 0, 0));
	float h3 = waterH(pos + vec3(0, 0, 1));
	float h4 = waterH(pos + vec3(0, 0, -1));
	
	float caustic = max((1 - abs(0.5 - h0)) * (1 - (abs(h1 - h2) + abs(h3 - h4))), 0);
	caustic = max(pow(caustic, 3.5), 0) * 16;
	
	return caustic;
}