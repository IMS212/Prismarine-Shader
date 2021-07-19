//FUNCTIONS
float distx(float dist){
	return (far * (dist - near)) / (dist * (far - near));
}

float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

//NOISE
float getVerticalNoise(vec2 pos){
	vec2 flr = floor(pos);
	vec2 frc = fract(pos);
	frc = frc * frc * (3.0 - 2.0 * frc);
	
	float noisedl = GetNoise(flr);
	float noisedr = GetNoise(flr+vec2(1.0,0.0));
	float noiseul = GetNoise(flr+vec2(0.0,1.0));
	float noiseur = GetNoise(flr+vec2(1.0,1.0));

	float noise= mix(mix(noisedl,noisedr,frc.x),mix(noiseul,noiseur,frc.x),frc.y);
	return noise;
}

float getHorizontalNoise(vec3 pos){
	float YOffset = 32.0;
	vec3 flr = floor(pos);
	vec3 frc = fract(pos);
	frc = frc * frc * (3.0 - 2.0 * frc);
	
	float noisebdl  = GetNoise(flr.xz + flr.y * YOffset);
	float noisebdr  = GetNoise(flr.xz + flr.y * YOffset + vec2(1.0,0.0));
	float noisebul  = GetNoise(flr.xz + flr.y * YOffset + vec2(0.0,1.0));
	float noisebur  = GetNoise(flr.xz + flr.y * YOffset + vec2(1.0,1.0));
	float noisetdl  = GetNoise(flr.xz + flr.y * YOffset + YOffset);
	float noisetdr  = GetNoise(flr.xz + flr.y * YOffset + YOffset + vec2(1.0,0.0));
	float noisetul  = GetNoise(flr.xz + flr.y * YOffset + YOffset + vec2(0.0,1.0));
	float noisetur  = GetNoise(flr.xz + flr.y * YOffset + YOffset + vec2(1.0,1.0));

	float noiseMix0 = mix(mix(noisebdl, noisebdr, frc.x), mix(noisebul, noisebur, frc.x), frc.z);
	float noiseMix1 = mix(mix(noisetdl, noisetdr, frc.x), mix(noisetul, noisetur, frc.x), frc.z);
	float noise     = mix(noiseMix0, noiseMix1, frc.y);
	return noise;
}



//VC SAMPLING
float getUltraQualityVCSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, VCLOUDS_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * 0.001 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 8.0;
	
	if (ymult < 1.0){
		noise+= getHorizontalNoise(pos * samples * 0.5 - wind*1) * 0.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.25 - wind*0.9) * 0.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.125 - wind*0.8) * 1.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.0625 - wind*0.7) * 1.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.03125 - wind*0.6) * 2.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.016125 - wind*0.5) * 2.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.00862 - wind*0.4) * 3.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.00431 - wind*0.3) * 3.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.00216 - wind*0.2) * 4.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
	}
	noise = clamp(mix(noise * VCLOUDS_AMOUNT * 0.85, 21.0, 0.25 * rainStrengthLowered) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}

float getHighQualityVCSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, VCLOUDS_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * 0.001 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 6.0;
	
	if (ymult < 1.0){
		noise+= getHorizontalNoise(pos * samples * 0.5 - wind*0.5) * 2 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.25 - wind*0.4) * 3 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.125 - wind*0.3) * 4 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.0625 - wind*0.2) * 5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.03125 - wind*0.1) * 6 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos * samples * 0.016125) * 7 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
	}
	noise = clamp(mix(noise * 0.75 * VCLOUDS_AMOUNT, 21.0, 0.25 * rainStrengthLowered) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}

float getLowQualityVCSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, VCLOUDS_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * 0.001 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 4.0;

	if (ymult < 1.0){
		noise+= getHorizontalNoise(pos * samples * 0.1 - wind * 0.3) * 16 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
	}

	noise = clamp(mix(noise * VCLOUDS_AMOUNT * 0.75, 21.0, 0.25 * rainStrengthLowered) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}



//FINAL
float getVolumetricCloud(float pixeldepthw) {
	float vc	    = 0.0;
	vec4 wpos 		= vec4(0.0);

	float quality	= VCLOUDS_QUALITY / 2;
	float dither 	= (Bayer256(gl_FragCoord.xy) * quality);
	float maxDist 	= VCLOUDS_RANGE;
	float minDist 	= 0.01f + dither;

	for (minDist; minDist < maxDist; ) {
		if (getDepth(pixeldepthw) < minDist || vc > 0.999){
			break;
		}
		wpos = getWorldPos(getFragPos(texCoord.xy,distx(minDist)));
		if (length(wpos.xz) < maxDist && getDepth(pixeldepthw) > minDist){
			float verticalNoise = getVerticalNoise((wpos.xz + cameraPosition.xz + (frametime * VCLOUDS_SPEED * 0.1)) * 0.002);		

			#ifdef WORLD_CURVATURE
			if (length(wpos.xz) < WORLD_CURVATURE_SIZE) wpos.y += length(wpos.xz) * length(wpos.xyz) / WORLD_CURVATURE_SIZE;
			else break;
			#endif

			wpos.xyz += cameraPosition.xyz + vec3(frametime * 4.0 * VCLOUDS_SPEED, -verticalNoise * 32.0, 0.0);
 
			#if VCLOUDS_NOISE_QUALITY == 0
			float noise = getLowQualityVCSample(wpos.xyz, (VCLOUDS_HEIGHT + (timeBrightness * VCLOUDS_HEIGHT_ADJ_FACTOR)), VCLOUDS_VERTICAL_THICKNESS, VCLOUDS_SAMPLES);
			#elif VCLOUDS_NOISE_QUALITY == 1
			float noise = getHighQualityVCSample(wpos.xyz, (VCLOUDS_HEIGHT + (timeBrightness * VCLOUDS_HEIGHT_ADJ_FACTOR)), VCLOUDS_VERTICAL_THICKNESS, VCLOUDS_SAMPLES);
			#elif VCLOUDS_NOISE_QUALITY == 2
			float noise = getUltraQualityVCSample(wpos.xyz, (VCLOUDS_HEIGHT + (timeBrightness * VCLOUDS_HEIGHT_ADJ_FACTOR)), VCLOUDS_VERTICAL_THICKNESS, VCLOUDS_SAMPLES);
			#endif

			vc = max(noise, vc);
		}
		minDist = minDist + quality;
	}
	return vc;
}
