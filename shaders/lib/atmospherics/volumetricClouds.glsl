//Volumetric clouds and fog from BSL 6.2 (modified)
uniform float frameCounter;

//FUNCTIONS
float distx(float dist){
	return (far * (dist - near)) / (dist * (far - near));
}

float getDepth(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
}

float dither8x8(vec2 pos)
{
	const int ditherPattern[64] = int[64](
		0, 32, 8, 40, 2, 34, 10, 42,
		48, 16, 56, 24, 50, 18, 58, 26,
		12, 44, 4, 36, 14, 46, 6, 38,
		60, 28, 52, 20, 62, 30, 54, 22,
		3, 35, 11, 43, 1, 33, 9, 41,
		51, 19, 59, 27, 49, 17, 57, 25,
		15, 47, 7, 39, 13, 45, 5, 37,
		63, 31, 55, 23, 61, 29, 53, 21);

    vec2 positon = floor(mod(vec2(texcoord.s * viewWidth,texcoord.t * viewHeight), 8.0f));

	int dither = ditherPattern[int(positon.x) + int(positon.y) * 8];

	return float(dither) / 64.0f;
}

//BASIC DIRECTIONAL NOISE
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
	float YOffset = 16.0;
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



//VOLUMETRIC CLOUDS NOISE
float getUltraQualityVCSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, 2.0);
	vec3 wind = vec3(frametime * 0.005 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 3.0;
	float opacity = VCLOUDS_OPACITY + (cameraPosition.y * 0.005);
	
	if (ymult < 2.0){
		noise+= getHorizontalNoise(pos / samples * 1.0 - wind*0.9) * 0.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.5 - wind*0.8) * 0.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.25 - wind*0.7) * 0.5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.125 - wind*0.6) * 0.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.0625 - wind*0.5) * 1.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.03125 - wind*0.4) * 1.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.016125) * 1.5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.00862) * 1.75 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.00431) * 2.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.00216) * 2.25 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.00108) * 2.5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);

	}
	noise = clamp(mix(noise, 21.0, 0.25 * 0.0 * VCLOUDS_AMOUNT) - (10.0 + 5.0 * ymult), 0.0, 1.0) * (opacity - rainStrengthLowered) * far;
	return noise;
}

float getHighQualityVCSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, 2.0);
	vec3 wind = vec3(frametime * 0.005 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 3.0;
	float opacity = VCLOUDS_OPACITY + (cameraPosition.y * 0.005);

	if (ymult < 2.0){
		noise+= getHorizontalNoise(pos / samples * 0.5 - wind*0.5) * 0.5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.25 - wind*0.4) * 1.5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.125 - wind*0.3) * 2.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.0625 - wind*0.2) * 2.5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.03125 - wind*0.1) * 3.0 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
		noise+= getHorizontalNoise(pos / samples * 0.016125) * 3.5 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);

	}
	noise = clamp(mix(noise, 21.0, 0.25 * 0.0 * VCLOUDS_AMOUNT) - (10.0 + 5.0 * ymult), 0.0, 1.0) * (opacity - rainStrengthLowered) * far;
	return noise;
}

float getLowQualityVCSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, 2.0);
	vec3 wind = vec3(frametime * 0.005 * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 3.0;
	float opacity = VCLOUDS_OPACITY + (cameraPosition.y * 0.005);

	if (ymult < 2.0){
		noise+= getHorizontalNoise(pos / samples * 0.1 - wind * 0.3) * 16 * (rainStrengthLowered + VCLOUDS_HORIZONTAL_THICKNESS);
	}

	noise = clamp(mix(noise, 0, 0.25 * 0.0 * VCLOUDS_AMOUNT) - (10.0 + 1.0 * ymult), 0.0, 1.0) * (opacity - rainStrengthLowered);
	return noise;
}



//VOLUMETRIC FOG NOISE
float getHighQualityVFSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, 16.0);
	vec3 wind = vec3(frametime * 0.001 * VFOG_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 2.0;

	if (ymult < 4.0){
		noise+= getHorizontalNoise(pos / samples * 1 - wind * 0.6) * 0.5;
		noise+= getHorizontalNoise(pos / samples * 0.5 - wind * 0.5) * 0.75 * VFOG_HORIZONTAL_THICKNESS;
		noise+= getHorizontalNoise(pos / samples * 0.25 - wind * 0.4) * 1.00 * VFOG_HORIZONTAL_THICKNESS;
		noise+= getHorizontalNoise(pos / samples * 0.125 - wind * 0.3) * 1.25 * VFOG_HORIZONTAL_THICKNESS;
		noise+= getHorizontalNoise(pos / samples * 0.076 - wind * 0.2) * 1.50 * VFOG_HORIZONTAL_THICKNESS;
		noise+= getHorizontalNoise(pos / samples * 0.038 - wind * 0.1) * 1.75 * VFOG_HORIZONTAL_THICKNESS;
		noise+= getHorizontalNoise(pos / samples * 0.016) * 2.00 * VFOG_HORIZONTAL_THICKNESS;
		noise+= getHorizontalNoise(pos / samples * 0.008) * 2.25 * VFOG_HORIZONTAL_THICKNESS;
	}
	noise = clamp(mix(noise, 21.0, 0.25 * 0.0 * VFOG_AMOUNT) - (10.0 + 5.0 * ymult), 0.0, 1.0) * (VFOG_OPACITY - rainStrengthLowered) * far;
	return noise;
}

float getLowQualityVFSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, 16.0);
	vec3 wind = vec3(frametime * 0.001 * VFOG_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 2.0;

	if (ymult < 4.0){
		noise+= getHorizontalNoise(pos / samples * 0.125 - wind * 0.3) * 10 * VFOG_HORIZONTAL_THICKNESS;
	}

	noise = clamp(mix(noise, 20, 0.25 * 0.0 * VFOG_AMOUNT) - (10.0 + 5.0 * ymult), 0.0, 1.0) * (VFOG_OPACITY - rainStrengthLowered);
	return noise;
}



//FINAL

vec2 getVolumetricCloud(float pixeldepth0, float pixeldepth1) {
	vec2 vc 		= vec2(0.0);
	vec4 wpos 		= vec4(0.0);

	float quality	= VCLOUDS_QUALITY / 2;
	float dither 	= Bayer8(gl_FragCoord.xy) * quality;
	float maxDist 	= VCLOUDS_RANGE*far;
	float minDist 	= 0.01f+dither;


	for (minDist; minDist < maxDist; ) {
		if (getDepth(pixeldepth0) < minDist || vc.y > 0.999){
			break;
		}
		wpos = getWorldPos(getFragPos(texCoord.xy, distx(minDist)));
		if (length(wpos.xz) < maxDist){
			float verticalNoise = getVerticalNoise((wpos.xz + cameraPosition.xz + frametime) * 0.0003 * VCLOUDS_SPEED);
			wpos.xyz += cameraPosition.xyz + vec3(frametime*4.0,-verticalNoise*32.0,0.0);

			#ifdef WORLD_CURVATURE
			if (length(wpos.xz) < WORLD_CURVATURE_SIZE) wpos.y += length(wpos.xz) * length(wpos.xyz) / WORLD_CURVATURE_SIZE;
			else break;
			#endif

			#if VCLOUDS_NOISE_QUALITY == 0
			float noise = getLowQualityVCSample(wpos.xyz, VCLOUDS_HEIGHT, VCLOUDS_VERTICAL_THICKNESS, VCLOUDS_AMOUNT);
			#elif VCLOUDS_NOISE_QUALITY == 1
			float noise = getHighQualityVCSample(wpos.xyz, VCLOUDS_HEIGHT, VCLOUDS_VERTICAL_THICKNESS, VCLOUDS_AMOUNT);
			#elif VCLOUDS_NOISE_QUALITY == 2
			float noise = getUltraQualityVCSample(wpos.xyz, VCLOUDS_HEIGHT, VCLOUDS_VERTICAL_THICKNESS, VCLOUDS_AMOUNT);
			#endif
			
			float col = pow(smoothstep(VCLOUDS_HEIGHT - VCLOUDS_VERTICAL_THICKNESS * noise, VCLOUDS_HEIGHT + VCLOUDS_VERTICAL_THICKNESS * noise, wpos.y), dither);
			vc.x 	  = max(noise * col, vc.x);
			vc.y 	  = max(noise, vc.y);
		}
		minDist = minDist + quality;
	}
	return vc;
}

vec2 getVolumetricFog(float pixeldepth0, float pixeldepth1) {
	vec2 vc = vec2(0.0);

	float dither = Bayer64(gl_FragCoord.xy) * VFOG_QUALITY*2;
	#ifdef TAA
		dither = fract(dither + frameCounter / 256.0);
	#endif

	float maxDist = VFOG_RANGE*far;
	float minDist = 0.01+dither;
	vec4 wpos = vec4(0.0);

	for (minDist; minDist < maxDist; ) {
		if (getDepth(pixeldepth0) < minDist || vc.y > 0.999){
			break;
		}
		wpos = getWorldPos(getFragPos(texCoord.xy,distx(minDist)));
		if (length(wpos.xz) < maxDist){
			float verticalNoise = getVerticalNoise((wpos.xz + cameraPosition.xz + frametime) * 0.005 * VFOG_SPEED);
			wpos.xyz += cameraPosition.xyz + vec3(frametime * 1.0, -verticalNoise * 32.0,0.0);

			#ifdef WORLD_CURVATURE
			if (length(wpos.xz) < WORLD_CURVATURE_SIZE) wpos.y += length(wpos.xz) * length(wpos.xyz) / WORLD_CURVATURE_SIZE;
			else break;
			#endif

			#if VFOG_NOISE_QUALITY == 0
			float noise = getLowQualityVFSample(wpos.xyz, VFOG_HEIGHT, VFOG_VERTICAL_THICKNESS, VFOG_AMOUNT);
			#elif VFOG_NOISE_QUALITY == 1
			float noise = getHighQualityVFSample(wpos.xyz, VFOG_HEIGHT, VFOG_VERTICAL_THICKNESS, VFOG_AMOUNT);
			#endif
			
			float col = pow(smoothstep(VFOG_HEIGHT - VFOG_VERTICAL_THICKNESS * noise, VFOG_HEIGHT + VFOG_VERTICAL_THICKNESS * noise, wpos.y), 0.0);
			vc.x = max(noise * col, vc.x);
			vc.y = max(noise, vc.y);
		}
		minDist = minDist + VFOG_QUALITY / 2;
	}
	return vc;
}