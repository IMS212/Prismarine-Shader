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

	#ifdef END_VOLUMETRIC_FOG
	#endif

	dither = fract(dither + frameCounter / 4);
	
	vec3 screenPos = vec3(texCoord, pixeldepth0);
	vec4 viewPos = gbufferProjectionInverse * (vec4(screenPos, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;
	
	vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);
	float VoL = dot(normalize(viewPos.xyz), lightVec);

	#ifdef OVERWORLD
	float visfactor = 0.05 * (-0.8 * timeBrightness + 1.0) * (3.0 * rainStrength + 1.0);
	float invvisfactor = 1.0 - visfactor;
	float visibility = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);

	visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = clamp(visibility * 1.015 / invvisfactor - 0.015, 0.0, 1.0);
	visibility = mix(1.0, visibility, 0.25 * eBS + 0.75);
	#endif
	
	#ifdef END
	VoL = pow(VoL * 0.5 + 0.5, 16.0) * 0.75 + 0.25;
	float visibility = VoL;
	#endif

	#ifdef NETHER
	float visibility = 0;
	#endif

	visibility *= 0.2 * float(pixeldepth0 > 0.75);

	if (visibility > 0.0) {
		float maxDist = LIGHTSHAFT_MAX_DISTANCE;
		
		float depth0 = GetLinearDepth2(pixeldepth0);
		float depth1 = GetLinearDepth2(pixeldepth1);
		vec4 worldposition = vec4(0.0);
		vec4 shadowposition = vec4(0.0);
		
		vec3 watercol = lightshaftWater.rgb * LIGHTSHAFT_WI; //don't ask, just don't ask
		
		for(int i = 0; i < LIGHTSHAFT_SAMPLES; i++) {
			float minDist = (exp2(i + dither) - 0.95) * LIGHTSHAFT_MIN_DISTANCE;
			float maxDist = LIGHTSHAFT_MAX_DISTANCE;

			#ifdef END
			maxDist = 128.0;
			minDist = exp2(i + dither) - 0.95;
			#endif

			if (minDist >= maxDist) break;
			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;

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
				else if (isEyeInWater == 1.0) shadow *= watercol * 512 * LIGHTSHAFT_WI * (1.0 + eBS);

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
				if (isEyeInWater != 1){
					vec3 npos = worldposition.xyz + cameraPosition.xyz + vec3(frametime * 4.0, 0, 0);
					float n3da = texture2D(noisetex, npos.xz / 1024.0 + floor(npos.y / 3.0) * 0.35).r;
					float n3db = texture2D(noisetex, npos.xz / 1024.0 + floor(npos.y / 3.0 + 1.0) * 0.35).r;
					float noise = mix(n3da, n3db, fract(npos.y / 3.0));
					noise = sin(noise * 16.0) * 0.25 + 0.5;
					shadow *= noise;
				}
				#endif
				
				vl += shadow;
			}
			else{
				vl += 1.0;
			}
		}
		vl = sqrt(vl * visibility);
		if(dot(vl, vl) > 0.0) vl += (dither - 0.25) / 128.0;
	}
	
	return vl;
}