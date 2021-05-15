//Volumetric light from BSL and Complementary Shaders (highly modified)

uniform float eyeAltitude;
float distx(float dist){
	return(far*(dist-near))/(dist*(far-near));
}

float getDepth(float depth){
	return 2.*near*far/(far+near-(2.*depth-1.)*(far-near));
}

vec4 distortShadow(vec4 shadowpos,float distortFactor){
	shadowpos.xy*=1./distortFactor;
	shadowpos.z=shadowpos.z*.2;
	shadowpos=shadowpos*.5+.5;
	
	return shadowpos;
}

vec4 getShadowSpace(float shadowdepth, vec2 texCoord) {
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, shadowdepth, 1.0) * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec4 wpos = gbufferModelViewInverse * viewPos;
	wpos = shadowModelView * wpos;
	wpos = shadowProjection * wpos;
	wpos /= wpos.w;
	
	float distb = sqrt(wpos.x * wpos.x + wpos.y * wpos.y);
	float distortFactor = 1.0 - shadowMapBias + distb * shadowMapBias;
	wpos = distortShadow(wpos,distortFactor);

	return wpos;
}

vec3 GetLightShafts(float pixeldepth0, float pixeldepth1, vec3 color, float dither) {
	vec3 vl = vec3(0.0);

	#ifdef TAA
		dither = fract(dither + frameCounter / 256.0);
	#endif
	
	vec3 screenPos = vec3(texCoord, pixeldepth0);
	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord, pixeldepth0, 1.0) * 2.0 - 1.0);
		viewPos /= viewPos.w;
			
	#ifdef OVERWORLD
	vec3 lightVec 		= sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));
	vec3 nViewPos 		= normalize(viewPos.xyz);
	float VoL 			= dot(nViewPos, lightVec);
	float visfactor 	= 0.05 * (-0.4 * timeBrightness + 1.0) * (1.0 * rainStrength + 0.1);
	float invvisfactor	= 1.0 - visfactor;
	float visibility 	= 0.94 - (moonVisibility * 0.03);
	float cosS 			= dot(nViewPos, lightVec);
	float PERSISTENCE   = LIGHTSHAFT_PERSISTENCE_FACTOR;

	if (rainStrength != 0.0) visibility 	= visibility - (rainStrength / 2.0);
	if (isEyeInWater == 0) PERSISTENCE 	   *= min(2.0 + rainStrength*rainStrength - sunVisibility * sunVisibility, 8.0) - (timeBrightness * LIGHTSHAFT_TIME_DECREASE_FACTOR);
	if (isEyeInWater == 1.0) PERSISTENCE   *= min(2.0 + rainStrength*rainStrength - sunVisibility * sunVisibility, 8.0) - (cameraPosition.y * LIGHTSHAFT_ALTITUDE_DECREASE_FACTOR * 0.5) * 0.5;

	#ifdef LIGHTSHAFT_PERSISTENCE
	if (PERSISTENCE <= 32.00) {
		if (PERSISTENCE >= 1.0) visibility *= max((cosS + PERSISTENCE) / (PERSISTENCE + 1.0), 0.0);
		else visibility *= pow(max((cosS + 1.0) / 2.0, 0.0), (32.0 - PERSISTENCE*16.0));
	}
	#endif

	if (eyeAltitude < 2.0) visibility *= clamp((eyeAltitude-1.0), 0.0, 1.0);
	visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = clamp(visibility * 1.015 / invvisfactor - 0.015, 0.0, 1.0);
	visibility = mix(1.0, visibility, 0.25 * 1 + 0.75) * 0.14285 * float(pixeldepth0 > 0.56) - (timeBrightness * LIGHTSHAFT_TIME_DECREASE_FACTOR);
	if (isEyeInWater == 1.0) visibility = (visibility + 0.1) * WATER_I;
	#endif

	#if defined END || defined NETHER
	float visibility = 0.0;
	#endif

	if (visibility > 0.0) {
		
		float depth0 = getDepth(pixeldepth0);
		float depth1 = getDepth(pixeldepth1);
		vec4 worldposition = vec4(0.0);
		
		vec3 watercol = mix(vec3(1.0), waterColor.rgb / (waterColor.a * waterColor.a), pow(waterAlpha, 0.45));

		float minDistFactor = LIGHTSHAFT_MIN_DISTANCE;
		if (isEyeInWater == 1.0) minDistFactor = 2.0;
		float maxDist = LIGHTSHAFT_MAX_DISTANCE * 1.5;
		if (isEyeInWater == 1.0) maxDist = 256;

		int sampleCount = LIGHTSHAFT_SAMPLES;
		
		for(int i = 0; i < sampleCount; i++) {
			float minDist = (i + dither) * minDistFactor;
			if (isEyeInWater == 1) minDist = (pow(i + dither + 0.5, 2.0)) * minDistFactor * 0.055;

			float breakFactor = 0.0;
			if (minDist >= maxDist) breakFactor = 1.0;
			if (breakFactor > 0.5) break;
			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;

			#ifndef LIGHTSHAFT_WATER
			if (isEyeInWater == 1.0) break;
			#endif

			#if !defined TAA || defined END
			break;
			#endif

			worldposition = getShadowSpace(distx(minDist), texCoord.st);
			worldposition.z+=0.0002;

			if (length(worldposition.xy * 2.0 - 1.0) < 1.0) {
				float shadow0 = shadow2D(shadowtex0, worldposition.xyz).z;
				
				vec3 shadowCol = vec3(0.0);
				#ifdef SHADOW_COLOR
				if (shadow0 < 1.0) {
					float shadow1 = shadow2D(shadowtex1, worldposition.xyz).z;
					if (shadow1 > 0.0) {
						shadowCol = texture2D(shadowcolor0, worldposition.xy).rgb;
						shadowCol *= shadowCol * shadow1;
					}
				}
				#endif
				vec3 shadow = clamp(shadowCol * (1.0 - shadow0) + shadow0, vec3(0.0), vec3(1.0));

				if (depth0 < minDist) shadow *= color;
				else if (isEyeInWater == 1.0) shadow *= watercol * 0.09 * (1.0 + eBS);

				vl += shadow;
			} else {
				vl += 1.0;
			}
			if (breakFactor > 0.5) break;
		}
		vl = vl * visibility;
		if(isEyeInWater==1)	{
			#ifdef LIGHTSHAFT_WATER
			visibility = 0.90;
			vl /= sqrt(vl) * 4.0;
			#else
			visibility = 0.0;
			vl /= sqrt(vl) * 4.0;
			#endif
		}
		vl *= 0.9;
		if (dot(vl, vl) > 0.0) vl += (dither - 0.25) / 256.0;
	}

	return vl;
}