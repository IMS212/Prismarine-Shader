#ifdef OVERWORLD
vec3 GetFogColor(vec3 viewPos) {
	vec3 nViewPos = normalize(viewPos);
	float lViewPos = length(viewPos) / 64.0;
	lViewPos = 1.0 - exp(-lViewPos * lViewPos);

    float VoU = clamp(dot(nViewPos,  upVec), -1.0, 1.0);
    float VoL = clamp(dot(nViewPos, sunVec), -1.0, 1.0);

	float density = 0.4 + (cameraPosition.y * FOG_ALTITUDE_INCREASE_FACTOR);
    float nightDensity = 0.35;
    float weatherDensity = 1.5;
    float groundDensity = 0.08 * (4.0 - 3.0 * sunVisibility) *
                          (10.0 * rainStrength * rainStrength + 1.0);
    
    float exposure = exp2(timeBrightness * 0.75 - 1.00);
    float nightExposure = exp2(-3.5);

	float baseGradient = exp(-(VoU * 0.5 + 0.5) * 0.5 / density);

	float groundVoU = clamp(-VoU * 0.5 + 0.5, 0.0, 1.0);
    float ground = 1.0 - exp(-groundDensity / groundVoU);

    vec3 fog = fogCol * baseGradient / (SKY_I * SKY_I);
    fog = fog / sqrt(fog * fog + 1.0) * exposure * sunVisibility * (SKY_I * SKY_I);

	float sunMix = (VoL * 0.5 + 0.5) * pow(clamp(1.0 - VoU, 0.0, 1.0), 2.0 - sunVisibility) *
                   pow(1.0 - timeBrightness * 0.6, 3.0);
    float horizonMix = pow(1.0 - abs(VoU), 2.5) * 0.125 * (1.0 - timeBrightness * 0.5);
    float lightMix = (1.0 - (1.0 - sunMix) * (1.0 - horizonMix)) * lViewPos;

	vec3 lightFog = pow(lightSun / 2 * vec3(FOG_R, FOG_G, FOG_B) * FOG_I, vec3(4.0 - sunVisibility)) * baseGradient;
	lightFog = lightFog / (1.0 + lightFog * rainStrength);

    fog = mix(
        sqrt(fog * (1.0 - lightMix)), 
        sqrt(lightFog), 
        lightMix
    );
    fog *= fog;

	float nightGradient = exp(-(VoU * 0.5 + 0.5) * 0.35 / nightDensity);
    vec3 nightFog = lightNight * lightNight * nightGradient * nightExposure;
    fog = mix(nightFog, fog, sunVisibility * sunVisibility);

    float rainGradient = exp(-(VoU * 0.5 + 0.5) * 0.125 / weatherDensity);
    vec3 weatherFog = weatherCol.rgb * weatherCol.rgb;
    weatherFog *= GetLuminance(ambientCol / (weatherFog)) * (0.2 * sunVisibility + 0.2);
    fog = mix(fog, weatherFog * rainGradient, rainStrength);

    if (cameraPosition.y < 1.0) fog *= exp(2.0 * cameraPosition.y - 2.0);

	return fog;
}
#endif

void NormalFog(inout vec3 color, vec3 viewPos) {
	#ifdef OVERWORLD
	float fog = length(viewPos) * FOG_DENSITY / 256.0;
	float clearDay = sunVisibility * (1.0 - rainStrength);
	fog *= (0.5 * rainStrength + 1.0) / (4.0 * clearDay + 1.0);
	fog = 1.0 - exp(-2.0 * pow(fog, 0.15 * clearDay + 1.25) * eBS);
	vec3 fogColor = GetFogColor(viewPos);

	#if DISTANT_FADE > 0
	if(isEyeInWater == 0.0){
		#if DISTANT_FADE == 1
		float fogFactor = length(viewPos);
		#else
		vec4 worldPos = gbufferModelViewInverse * vec4(viewPos, 1.0);
		worldPos.xyz /= worldPos.w;
		float fogFactor = length(worldPos.xz);
		#endif
		float vanillaFog = 1.0 - (far - (fogFactor + 20.0)) * 5.0 / (FOG_DENSITY * far);
		vanillaFog = clamp(vanillaFog, 0.0, 1.0);
		if(vanillaFog > 0.0){
			vec3 vanillaFogColor = GetSkyColor(viewPos, false);
			vanillaFogColor *= (4.0 - 3.0 * eBS) * (1.0 + nightVision);

			fogColor *= fog;
			
			fog = mix(fog, 1.0, vanillaFog);
			if(fog > 0.0) fogColor = mix(fogColor, vanillaFogColor, vanillaFog) / fog;
		}
	}
	#endif
	#endif

	#ifdef NETHER
	float viewLength = length(viewPos);
	float fog = 2.0 * pow(viewLength * FOG_DENSITY / 256.0, 1.5) + 
				6.0 * pow(viewLength * 1.5 / far, 4.0);
	fog = 1.0 - exp(-fog);
	vec3 fogColor = netherCol.rgb * 0.04;
	#endif

	#ifdef END
	float fog = length(viewPos) * FOG_DENSITY / 128.0;
	fog = 1.0 - exp(-0.8 * fog * fog);
	vec3 fogColor = endCol.rgb * 0.007;
	#endif

	color = mix(color, fogColor, fog);
}

void BlindFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * (blindFactor * 0.2);
	fog = (1.0 - exp(-6.0 * fog * fog * fog)) * blindFactor;
	color = mix(color, vec3(0.0), fog);
}

void LavaFog(inout vec3 color, vec3 viewPos) {
	float fog = length(viewPos) * 0.5;
	fog = (1.0 - exp(-4.0 * fog * fog * fog));
	#ifdef EMISSIVE_RECOLOR
	color = mix(color, pow(blocklightCol / BLOCKLIGHT_I, vec3(4.0)) * 2.0, fog);
	#else
	color = mix(color, vec3(1.0, 0.3, 0.01), fog);
	#endif
}

void Fog(inout vec3 color, vec3 viewPos) {
	NormalFog(color, viewPos);
	if (isEyeInWater == 2) LavaFog(color, viewPos);
	if (blindFactor > 0.0) BlindFog(color, viewPos);
}