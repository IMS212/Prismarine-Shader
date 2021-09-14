#if (defined OVERWORLD && FOG_MODE == 1 || FOG_MODE == 2) || (defined END && defined END_VOLUMETRIC_FOG)
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
	float noise = mix(mix(noisedl, noisedr, frc.x), mix(noiseul, noiseur, frc.x), frc.y);
	return noise;
}

float getVolumetricNoise(vec3 pos){
	vec3 flr = floor(pos);
	vec3 frc = fract(pos);
	frc = frc * frc * (3.0-2.0 * frc);
	
	float noisebdl = getNoise(flr.xz + flr.y * 32);
	float noisebdr = getNoise(flr.xz + flr.y * 32 + vec2(1.0,0.0));
	float noisebul = getNoise(flr.xz + flr.y * 32 + vec2(0.0,1.0));
	float noisebur = getNoise(flr.xz + flr.y * 32 + vec2(1.0,1.0));
	float noisetdl = getNoise(flr.xz + flr.y * 32 + 32);
	float noisetdr = getNoise(flr.xz + flr.y * 32 + 32 + vec2(1.0,0.0));
	float noisetul = getNoise(flr.xz + flr.y * 32 + 32 + vec2(0.0,1.0));
	float noisetur = getNoise(flr.xz + flr.y * 32 + 32 + vec2(1.0,1.0));
	float noise= mix(mix(mix(noisebdl, noisebdr, frc.x), mix(noisebul, noisebur, frc.x), frc.z),
				 mix(mix(noisetdl, noisetdr, frc.x), mix(noisetul, noisetur, frc.x), frc.z), frc.y);
	return noise;
}

float getFogSample(vec3 pos, float height, float verticalThickness, float samples){
	float noise = 0.0;
	float ymult = pow(abs(height - pos.y) / verticalThickness, LIGHTSHAFT_VERTICAL_THICKNESS);
	vec3 wind = vec3(frametime * 0.25, 0.0, 0.0);
	
	if (ymult < 2.0){
		noise+= getVolumetricNoise(pos * samples * 0.5 - wind * 0.5) * 5.0 * LIGHTSHAFT_HORIZONTAL_THICKNESS;
		noise+= getVolumetricNoise(pos * samples * 0.25 - wind * 0.3) * 7.0 * LIGHTSHAFT_HORIZONTAL_THICKNESS;
		noise+= getVolumetricNoise(pos * samples * 0.125 - wind * 0.1) * 9.0 * LIGHTSHAFT_HORIZONTAL_THICKNESS;
	}
	noise = clamp(mix(noise * LIGHTSHAFT_AMOUNT, 21.0, 0.25) - (10.0 + 5.0 * ymult), 0.0, 1.0);
	return noise;
}

float GetLogarithmicDepth(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float GetLinearDepth2(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec4 DistortShadow(vec4 shadowpos, float distortFactor) {
	shadowpos.xy *= 1.0 / distortFactor;
	shadowpos.z = shadowpos.z * 0.2;
	shadowpos = shadowpos * 0.5 + 0.5;

	return shadowpos;
}

vec4 GetWorldSpace(float shadowdepth, vec2 texCoord) {
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, shadowdepth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 wpos = gbufferModelViewInverse * viewPos;
	wpos /= wpos.w;
	
	return wpos;
}

vec4 GetShadowSpace(vec4 wpos) {
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;
	
	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	wpos = DistortShadow(wpos,distortFactor);
	
	return wpos;
}

//Light shafts from Robobo1221 (modified)
vec3 GetLightShafts(float pixeldepth0, float pixeldepth1, vec3 color, float dither) {
	vec3 vl = vec3(0.0);

	#ifndef LIGHTSHAFT_DAY
	float visibilityFactor = 1.0 - timeBrightness;
	if (visibilityFactor <= 0.025) visibilityFactor = 1 - eBS;
	if (isEyeInWater == 1) visibilityFactor = 1;
	#endif

	bool isThereADragon = gl_Fog.start / far < 0.5; //yes emin thanks for telling people about this in shaderlabs
	float dragonFactor;
	if (isThereADragon) dragonFactor = 1;
	else dragonFactor = 0;

	#ifdef END_VOLUMETRIC_FOG
	#endif
	
	#ifdef LIGHTSHAFT_CLOUDY_NOISE
	#endif

	vec3 screenPos = vec3(texCoord, pixeldepth0);
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, pixeldepth0, 1.0) * 2.0 - 1.0);
		viewPos /= viewPos.w;
	
	vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));
	vec3 nViewPos = normalize(viewPos.xyz);
	float VoL = dot(nViewPos, lightVec);

	#ifdef OVERWORLD	
	float visfactor = 0.05 * (-0.1 * timeBrightness + 1.0) * (1.0 - rainStrength);
	float invvisfactor = 1.0 - visfactor;
	float visibility = 0.975;

	visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = clamp(visibility * 1.015 / invvisfactor - 0.015, 0.0, 1.0);
	visibility = mix(1.0, visibility, 0.25 * 1 + 0.75) * 0.14285 * float(pixeldepth0 > 0.56);
	
	#ifndef LIGHTSHAFT_NIGHT
	visibility *= 1 - moonVisibility;
	#endif

	#ifndef LIGHTSHAFT_DAY
	visibility *= visibilityFactor;
	#endif
	
	#ifdef LIGHTSHAFT_PERSISTENCE
	float persistence = (LIGHTSHAFT_PERSISTENCE_FACTOR * 2);
	if (persistence <= 6.00) {
		if (persistence >= 1.0) visibility *= max((VoL + persistence) / (persistence + 1.0), 0.0);
		else visibility *= pow(max((VoL + 1.0) / 2.0, 0.0), (32.0 - persistence * 16.0));
	}
	#endif
	#endif
	
	#ifdef END
	VoL = pow(VoL * 0.5 + 0.5, 16.0) * 0.75 + 0.25;
	float visibility = VoL;
	visibility *= (0.5 + dragonFactor);
	#endif

	#ifdef NETHER
	float visibility = 0;
	#endif

	if (visibility > 0.0) {
		float minDistFactor = LIGHTSHAFT_MIN_DISTANCE;
		if (cameraPosition.y > 0) minDistFactor *= 0.5 + (cameraPosition.y * 0.025);
		float maxDist = LIGHTSHAFT_MAX_DISTANCE * 1.5;
		
		float depth0 = GetLinearDepth2(pixeldepth0);
		float depth1 = GetLinearDepth2(pixeldepth1);
		vec4 worldposition = vec4(0.0);
		vec4 shadowposition = vec4(0.0);

		float scattering = pow(VoL * shadowFade * 0.5 + 0.5, 6.0);
		vec3 watercol = lightshaftWater * lightCol.rgb * LIGHTSHAFT_WI * WATER_I; //don't ask, just don't ask
		
		for(int i = 0; i < LIGHTSHAFT_SAMPLES; i++) {
			float minDist = (i + dither) * minDistFactor;

			if (isEyeInWater == 1) minDist = (exp2(i + dither) - 0.95) * 8;
			
			#ifdef END
			minDist = (exp2(i + dither) - 0.95) * 2;
			#endif

			if (minDist >= maxDist) break;
			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;
			if (rainStrength == 1) break;

			#ifndef LIGHTSHAFT_WATER
			if (isEyeInWater == 1.0) break;
			#endif

			#ifndef END_VOLUMETRIC_FOG
			#ifdef END
			break;
			#endif
			#endif

			worldposition = GetWorldSpace(GetLogarithmicDepth(minDist), texCoord.st);
			shadowposition = GetShadowSpace(worldposition);
			shadowposition.z += 0.0512 / shadowMapResolution;

			if (length(shadowposition.xy * 2.0 - 1.0) < 1.0) {
				float shadow0 = shadow2D(shadowtex0, shadowposition.xyz).z;
				
				vec3 shadowCol = vec3(0.0);
				#ifdef SHADOW_COLOR
				if (shadow0 < 1.0) {
					float shadow1 = shadow2D(shadowtex1, shadowposition.xyz).z;
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, shadowposition.xy).rgb;
						shadowCol *= shadowCol * shadow1;
					}
				}
				#endif
				vec3 shadow = clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));

				if (depth0 < minDist) shadow *= color;
				else if (isEyeInWater == 1.0) shadow *= watercol * 1024 * LIGHTSHAFT_WI * (1.0 + eBS);

				#if defined END_VOLUMETRIC_FOG && defined END
				if (isEyeInWater != 1){
					vec3 npos = worldposition.xyz + cameraPosition.xyz + vec3(frametime * 4.0, 0, 0);
					float n3da = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 3.0) * 0.35).r;
					float n3db = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 3.0 + 1.0) * 0.35).r;
					float noise = mix(n3da, n3db, fract(npos.y / 3.0));
					noise = sin(noise * 16.0 + frametime) * 0.25 + 0.5;
					shadow *= noise;
				}
				#elif defined LIGHTSHAFT_CLOUDY_NOISE && defined OVERWORLD
				float timeFactor = 1.0 - timeBrightness;
				if (isEyeInWater != 1 && timeFactor > 0.025){
					vec3 npos = worldposition.xyz + cameraPosition.xyz;

					float vh = getHeightNoise((worldposition.xz + cameraPosition.xz + (frametime * 2)) * 0.005);

					#ifdef WORLD_CURVATURE
					if (length(worldposition.xz) < WORLD_CURVATURE_SIZE) worldposition.y += length(worldposition.xz) * length(worldposition.xyz) / WORLD_CURVATURE_SIZE;
					else break;
					#endif

					npos.xyz += vec3(frametime * 2, -vh * 32, 0.0);

					float noise = getFogSample(npos.xyz, LIGHTSHAFT_HEIGHT / 2, LIGHTSHAFT_VERTICAL_THICKNESS, 0.25);
					shadow *= noise;
				}
				#endif
				
				vl += shadow;
			}
		}
		vl = sqrt(vl * visibility);
		if(dot(vl, vl) > 0.0) vl += (dither - 0.25) / 128.0;
	}
	
	return vl;
}
#endif