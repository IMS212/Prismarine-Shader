uniform float eyeAltitude;
float distx(float dist){
	return(far*(dist-near))/(dist*(far-near));
}

float getDepth(float depth){
	return 2.*near*far/(far+near-(2.*depth-1.)*(far-near));
}

float GetLogarithmicDepth(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
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

vec3 GetLightShafts(float pixeldepth0, float pixeldepth1, vec3 color, float dither) {
	vec3 vl = vec3(0.0);

	#ifdef TAA
	dither = fract(dither + frameCounter / 64.0);
	#endif
	
	//LOLOLOLOLOL
	#ifdef LIGHTSHAFT_CLOUDY_NOISE
	#ifdef END_VOLUMETRIC_FOG
	#ifdef LIGHTSHAFT_PERSISTENCE
	#endif
	#endif
	#endif
	//

	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, pixeldepth0, 1.0) * 2.0 - 1.0);
		 viewPos /= viewPos.w;
	vec3 lightVec 		= sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));
	vec3 nViewPos 		= normalize(viewPos.xyz);
	float VoL 			= dot(nViewPos, lightVec);

	#ifdef OVERWORLD //////////// O V E R W O R L D ////////////
	float persistence   = LIGHTSHAFT_PERSISTENCE_FACTOR;
	float visfactor 	= 0.05 * (-LIGHTSHAFT_TIME_DECREASE_FACTOR * timeBrightness + 1.0) * (1.0 * rainStrength + 0.1) + isEyeInWater;
	float invvisfactor	= 1.0 - visfactor;
	float visibility 	= 0.94 - (rainStrength / 4);

	#ifdef LIGHTSHAFT_PERSISTENCE
	if (isEyeInWater == 0) persistence 	   *= min(2.0 + rainStrength*rainStrength - sunVisibility * sunVisibility, 8.0) - (timeBrightness * LIGHTSHAFT_TIME_DECREASE_FACTOR);
	if (isEyeInWater == 1) persistence     *= min(2.0 + rainStrength*rainStrength - sunVisibility * sunVisibility, 8.0) - (cameraPosition.y * LIGHTSHAFT_ALTITUDE_DECREASE_FACTOR * 0.5) * 0.5;
	if (persistence <= 32.00) {
		if (persistence >= 1.0) visibility *= max((VoL + persistence) / (persistence + 1.0), 0.0);
		else visibility *= pow(max((VoL + 1.0) / 2.0, 0.0), (32.0 - persistence*16.0));
	}
	#endif

	visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = clamp(visibility * 1.015 / invvisfactor - 0.015, 0.0, 1.0);
	visibility = mix(1.0, visibility, 0.25 * eBS + 0.75);
	visibility = visibility - (rainStrength / 4.0) - (cameraPosition.y * LIGHTSHAFT_ALTITUDE_DECREASE_FACTOR * 0.5);
	if (isEyeInWater == 1.0) visibility = visibility * WATER_I;
	if (eyeAltitude < 2.0) visibility *= clamp((eyeAltitude-1.0), 0.0, 1.0);

	#elif defined END //////////// E N D ////////////
	VoL = pow(VoL * 0.5 + 0.5, 16.0) * 0.75 + 0.25;
	float visibility = VoL;
	visibility = visibility / 4;

	#elif defined NETHER //////////// N E T H E R ////////////
	float visibility = .0;
	#endif

	if (visibility > 0.0) {
		vec4 worldposition = vec4(0.0);
		vec4 shadowposition = vec4(0.0);	
		float depth0 = getDepth(pixeldepth0);
		float depth1 = getDepth(pixeldepth1);
		
		vec3 watercol = mix(vec3(1.0), vec3(waterColor.r, waterColor.g * 0.4, waterColor.b * 8) / (waterColor.a * waterColor.a), pow(waterAlpha, 0.5));

		for(int i = 0; i < 9; i++) {
			float maxDist = LIGHTSHAFT_MAX_DISTANCE;
			float minDist = exp2(i + dither) - 0.95 * LIGHTSHAFT_MIN_DISTANCE;

			float breakFactor = 0.0;
			if (minDist >= maxDist) breakFactor = 1.0;
			if (breakFactor > 0.5) break;
			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;

			#ifndef END_VOLUMETRIC_FOG
			#ifdef END
			break;
			#endif
			#endif

			#ifndef LIGHTSHAFT_WATER
			if (isEyeInWater == 1.0) break;
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
				else if (isEyeInWater == 1.0) shadow *= watercol * 0.4 * (1.0 + eBS) * sqrt(minDist / maxDist);

				#if (defined LIGHTSHAFT_CLOUDY_NOISE && defined OVERWORLD) || (defined END && defined END_VOLUMETRIC_FOG)
				vec3 npos = worldposition.xyz + cameraPosition.xyz + vec3(frameTimeCounter * 4.0, 0, 0);
				float n3da = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 3.0) * 0.35).r;
				float n3db = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 3.0 + 1.0) * 0.35).r;
				float noise = mix(n3da, n3db, fract(npos.y / 3.0));
				noise = sin(noise * 28.0 + frameTimeCounter * 2.0) * 0.25 + 0.5;
				shadow *= noise;
				#endif

				vl += shadow;
			} else {
				vl += 1.0;
			}
		}
		if(isEyeInWater==1)	{
			#ifdef LIGHTSHAFT_WATER
			visibility = 0.90;
			vl /= sqrt(vl) * 4.0;
			#else
			visibility = 0.0;
			vl /= sqrt(vl) * 4.0;
			#endif
		}
		vl = sqrt(vl * visibility);
		if(dot(vl, vl) > 0.0) vl += (dither - 0.25) / 128.0;
	}

	return vl;
}