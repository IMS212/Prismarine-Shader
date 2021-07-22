//FUNCTIONS
float distx(float dist){
	return (far * (dist - near)) / (dist * (far - near));
}

float getDepth(float depth) {
  return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float getNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

float hnoise(vec2 pos){
	vec2 flr = floor(pos);
	vec2 frc = fract(pos);
	frc = frc * frc * (3-2 * frc);
	
	float noisedl = getNoise(flr);
	float noisedr = getNoise(flr + vec2(1.0,0.0));
	float noiseul = getNoise(flr + vec2(0.0,1.0));
	float noiseur = getNoise(flr + vec2(1.0,1.0));
	float noise= mix(mix(noisedl,noisedr,frc.x),mix(noiseul,noiseur,frc.x),frc.y);
	return noise;
}

float getVolumetricNoise(vec3 pos){
	vec3 flr = floor(pos);
	vec3 frc = fract(pos);
	float yadd = 32.0;
	frc = frc * frc * (3.0-2.0 * frc);
	
	float noisebdl = getNoise(flr.xz + flr.y * yadd);
	float noisebdr = getNoise(flr.xz + flr.y * yadd + vec2(1.0,0.0));
	float noisebul = getNoise(flr.xz + flr.y * yadd + vec2(0.0,1.0));
	float noisebur = getNoise(flr.xz + flr.y * yadd + vec2(1.0,1.0));
	float noisetdl = getNoise(flr.xz + flr.y * yadd + yadd);
	float noisetdr = getNoise(flr.xz + flr.y * yadd + yadd + vec2(1.0,0.0));
	float noisetul = getNoise(flr.xz + flr.y * yadd + yadd + vec2(0.0,1.0));
	float noisetur = getNoise(flr.xz + flr.y * yadd + yadd + vec2(1.0,1.0));
	float noise= mix(mix(mix(noisebdl,noisebdr,frc.x),mix(noisebul,noisebur,frc.x),frc.z),mix(mix(noisetdl,noisetdr,frc.x),mix(noisetul,noisetur,frc.x),frc.z),frc.y);
	return noise;
}

float getHQSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, VCLOUDS_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * 0.001 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 8.0;
	
	if (ymult < 2.0){
		noise += getVolumetricNoise(pos * samples * 0.5 - wind * 1) * 0.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.25 - wind * 0.9) * 0.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.125 - wind * 0.8) * 1.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.0625 - wind * 0.7) * 1.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.03125 - wind * 0.6) * 2.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.016125 - wind * 0.5) * 2.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.00862 - wind * 0.4) * 3.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.00431 - wind * 0.3) * 3.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise += getVolumetricNoise(pos * samples * 0.00216 - wind * 0.2) * 4.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
	}
	noise = clamp(mix(noise * VCLOUDS_AMOUNT * 0.85, 21.0, 0.25 * rainStrengthLowered) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}

float getMQSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, VCLOUDS_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * 0.001 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 8.0;
	if (ymult < 2.0){
		noise+= getVolumetricNoise(pos * samples * 0.5 - wind * 0.5) * VCLOUDS_HORIZONTAL_THICKNESS;
		noise+= getVolumetricNoise(pos * samples * 0.25 - wind * 0.4) * 2.0 * VCLOUDS_HORIZONTAL_THICKNESS;
		noise+= getVolumetricNoise(pos * samples * 0.125 - wind * 0.3) * 3.0 * VCLOUDS_HORIZONTAL_THICKNESS;
		noise+= getVolumetricNoise(pos * samples * 0.0625 - wind * 0.2) * 4.0 * VCLOUDS_HORIZONTAL_THICKNESS;
		noise+= getVolumetricNoise(pos * samples * 0.03125 - wind * 0.1) * 5.0 * VCLOUDS_HORIZONTAL_THICKNESS;
		noise+= getVolumetricNoise(pos * samples * 0.016125) * 6.0 * VCLOUDS_HORIZONTAL_THICKNESS;
	}
	noise = clamp(mix(noise * VCLOUDS_AMOUNT * 0.5, 21.0, 0.25 * rainStrengthLowered) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}

float getLQSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, VCLOUDS_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * 0.001 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 8.0;
	
	if (ymult < 4.0){
		noise+= getVolumetricNoise(pos * samples * 0.125 - wind * 0.3) * 16 * VCLOUDS_HORIZONTAL_THICKNESS;
	}

	noise = clamp(mix(noise * VCLOUDS_AMOUNT, 21.0, 0.25 * rainStrengthLowered) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}

vec2 getVolumetricCloud(float pixeldepth, float pixeldepthw, float heightAdjFactor, float vertThicknessFactor) {
	vec2 vc = vec2(0.0);
	float quality = VCLOUDS_QUALITY / 2;
	float dither = Bayer64(gl_FragCoord.xy) * quality; //useless

	float maxDist = 2.0 * VCLOUDS_RANGE * far;
	float minDist = 0.01f + dither;
	vec4 wpos = vec4(0.0);

	for (minDist; minDist < maxDist; ) {
		if (getDepth(pixeldepth) < minDist || vc.y > 0.999){
			break;
		}
		wpos = getWorldPos(getFragPos(texCoord.xy,distx(minDist)));
		if (length(wpos.xz) < maxDist && getDepth(pixeldepthw) > minDist){
			float vh = hnoise((wpos.xz + cameraPosition.xz + (frametime * VCLOUDS_SPEED)) * 0.005);

			#ifdef WORLD_CURVATURE
			if (length(wpos.xz) < WORLD_CURVATURE_SIZE) wpos.y += length(wpos.xz) * length(wpos.xyz) / WORLD_CURVATURE_SIZE;
			else break;
			#endif

			wpos.xyz += cameraPosition.xyz + vec3(frametime * 4.0 * VCLOUDS_SPEED, -vh * 32.0, 0.0);

			float height = VCLOUDS_HEIGHT + (heightAdjFactor * timeBrightness);
			float vertThickness = VCLOUDS_VERTICAL_THICKNESS * vertThicknessFactor;

			float noise = getHQSample(wpos.xyz, height, vertThickness, VCLOUDS_SAMPLES);
			float col = pow(smoothstep(height - vertThickness * noise, height + vertThickness * noise, wpos.y), 1.5);
			vc.x = max(noise * col, vc.x);
			vc.y = max(noise, vc.y);
		}
		minDist = minDist + quality;
	}
	return vc;
}
