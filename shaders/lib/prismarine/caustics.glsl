float GetWaterHeightMap(vec3 pos, vec2 offset){
	offset /= 256.0;
	float noiseA = texture2D(noisetex, (pos.xz - frametime * 0.25) / 256.0 + offset).r;
	float noiseB = texture2D(noisetex, (pos.xz + frametime * 0.50) / 96.0 + offset).r;
	noiseA *= noiseA; noiseB *= noiseB;	
	float noise = mix(noiseA, noiseB, WATER_DETAIL);
	
	return noise * 3 * WATER_BUMP;
}

float getCaustics(vec3 pos){
	float normalOffset = WATER_SHARPNESS;

	float h1 = GetWaterHeightMap(pos, vec2( normalOffset, 0.0));
	float h2 = GetWaterHeightMap(pos, vec2(-normalOffset, 0.0));
	float h3 = GetWaterHeightMap(pos, vec2(0.0,  normalOffset));
	float h4 = GetWaterHeightMap(pos, vec2(0.0, -normalOffset));
	
	float caustic = max((1 - (abs(h1 - h2) + abs(h3 - h4))), 0);
	caustic = max(pow(caustic, 3.5), 0);
	
	return caustic;
}