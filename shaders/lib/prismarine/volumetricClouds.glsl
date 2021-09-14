#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD
float mefade0 = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade0 = 1.0 - timeBrightness;

float CalcDayAmount(float morning, float day, float evening) {
	float me = mix(morning, evening, mefade0);
	return mix(me, day, 1.0 - dfade0 * sqrt(dfade0));
}

float CalcCloudAmount(float sun, float night) {
	float c = mix(night, sun, sunVisibility);
	return c * c;
}

float GetLogarithmicDepth(float dist){
	return (far * (dist - near)) / (dist * (far - near));
}

float GetLinearDepth2(float depth) {
  return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

float getNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

float getHeightNoise(vec2 pos){
	vec2 flr = floor(pos);
	vec2 frc = fract(pos);
	frc = frc * frc * (3 - 2 * frc);
	
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
	frc = frc * frc * (3.0 - 2.0 * frc);
	
	float noisebdl = getNoise(flr.xz + flr.y * 32);
	float noisebdr = getNoise(flr.xz + flr.y * 32 + vec2(1.0,0.0));
	float noisebul = getNoise(flr.xz + flr.y * 32 + vec2(0.0,1.0));
	float noisebur = getNoise(flr.xz + flr.y * 32 + vec2(1.0,1.0));
	float noisetdl = getNoise(flr.xz + flr.y * 32);
	float noisetdr = getNoise(flr.xz + flr.y * 32 + vec2(1.0,0.0));
	float noisetul = getNoise(flr.xz + flr.y * 32 + vec2(0.0,1.0));
	float noisetur = getNoise(flr.xz + flr.y * 32 + vec2(1.0,1.0));
	float noise = mix(mix(mix(noisebdl, noisebdr, frc.x),
				  mix(noisebul, noisebur, frc.x), frc.z),
				  mix(mix(noisetdl, noisetdr, frc.x),
				  mix(noisetul, noisetur, frc.x), frc.z), frc.y);
	return noise;
}

float getCloudSample(vec3 pos, float height, float verticalThickness, float samples, float quality){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, VCLOUDS_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * VCLOUDS_SPEED, 0.0, 0.0);
	float rainStrengthLowered = rainStrength / 8.0;
	float amount = CalcCloudAmount(CalcDayAmount(VCLOUDS_AMOUNT_MORNING, VCLOUDS_AMOUNT_DAY, VCLOUDS_AMOUNT_EVENING), VCLOUDS_AMOUNT_NIGHT);
	float thickness = VCLOUDS_HORIZONTAL_THICKNESS + (VCLOUDS_THICKNESS_FACTOR * timeBrightness);

	if (ymult < 2.0){
		if (quality == 2){
			noise += getVolumetricNoise(pos * samples * 0.5 - wind * 1) * 0.25 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.25 - wind * 0.9) * 0.75 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.125 - wind * 0.8) * 1.0 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.0625 - wind * 0.7) * 1.75 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.03125 - wind * 0.6) * 2.0 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.016125 - wind * 0.5) * 2.75 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.00862 - wind * 0.4) * 3.0 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.00431 - wind * 0.3) * 3.25 * thickness;
			noise += getVolumetricNoise(pos * samples * 0.00216 - wind * 0.2) * 4.0 * thickness;
		}else if (quality == 1){
			thickness *= 2.75;
			noise+= getVolumetricNoise(pos * samples * 0.5 - wind * 0.5) * 0.5 * thickness;
			noise+= getVolumetricNoise(pos * samples * 0.25 - wind * 0.4) * 2.0 * thickness;
			noise+= getVolumetricNoise(pos * samples * 0.125 - wind * 0.3) * 3.5 * thickness;
			noise+= getVolumetricNoise(pos * samples * 0.0625 - wind * 0.2) * 5.0 * thickness;
			noise+= getVolumetricNoise(pos * samples * 0.03125 - wind * 0.1) * 6.5 * thickness;
			noise+= getVolumetricNoise(pos * samples * 0.016125) * 8 * thickness;
			amount *= 0.25;
		} else if (quality == 0){
			noise+= getVolumetricNoise(pos * samples * 0.125 - wind * 0.3) * 16 * thickness;
		}
	}
	noise = clamp(mix(noise * amount, 21.0, 0.25 * rainStrengthLowered) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}

vec2 getVolumetricCloud(float pixeldepth1, float pixeldepth0, float heightAdjFactor, float vertThicknessFactor, vec3 viewPos) {
	vec2 vc = vec2(0.0);
	float quality = VCLOUDS_QUALITY / 2;
	float dither = Bayer64(gl_FragCoord.xy) * quality;

	float maxDist = 2.0 * VCLOUDS_RANGE * far;
	float minDist = (0.01f + dither);

	for (minDist; minDist < maxDist; ) {
		if (GetLinearDepth2(pixeldepth1) < minDist || vc.y > 0.999){
			break;
		}
		vec4 wpos = getWorldPos(getFragPos(texCoord.xy, GetLogarithmicDepth(minDist)));
		if (length(wpos.xz) < maxDist && GetLinearDepth2(pixeldepth0) > minDist){
			float vh = getHeightNoise((wpos.xz + cameraPosition.xz + (frametime * VCLOUDS_SPEED)) * 0.005);

			#ifdef WORLD_CURVATURE
			if (length(wpos.xz) < WORLD_CURVATURE_SIZE) wpos.y += length(wpos.xz) * length(wpos.xyz) / WORLD_CURVATURE_SIZE;
			else break;
			#endif

			wpos.xyz += cameraPosition.xyz + vec3(frametime * VCLOUDS_SPEED, -vh * 32, 0.0);

			float height = VCLOUDS_HEIGHT + (heightAdjFactor * timeBrightness);
			float vertThickness = VCLOUDS_VERTICAL_THICKNESS * vertThicknessFactor + timeBrightness;
			float noise = getCloudSample(wpos.xyz, height, vertThickness, VCLOUDS_SAMPLES, VCLOUDS_NOISE_QUALITY);

			float col = pow(smoothstep(height - vertThickness * noise, height + vertThickness * noise, wpos.y), 2);
			vc.x = max(noise * col, vc.x);
			vc.y = max(noise, vc.y);
		}
		minDist = minDist + quality;
	}
	return vc;
}
#endif