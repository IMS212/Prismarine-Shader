#ifdef OVERWORLD
#if SKY_COLOR_MODE == 1
vec3 getBiomeskyColor(){
	vec4 skyCold     = vec4(vec3(BIOMESKY_CR, BIOMESKY_CG, BIOMESKY_CB) / 255.0, 1.0) * BIOMESKY_CI;
	vec4 skyDesert   = vec4(vec3(BIOMESKY_DR, BIOMESKY_DG, BIOMESKY_DB) / 255.0, 1.0) * BIOMESKY_DI;
	vec4 skySwamp    = vec4(vec3(BIOMESKY_SR, BIOMESKY_SG, BIOMESKY_SB) / 255.0, 1.0) * BIOMESKY_SI;
	vec4 skyMushroom = vec4(vec3(BIOMESKY_MR, BIOMESKY_MG, BIOMESKY_MB) / 255.0, 1.0) * BIOMESKY_MI;
	vec4 skySavanna  = vec4(vec3(BIOMESKY_VR, BIOMESKY_VG, BIOMESKY_VB) / 255.0, 1.0) * BIOMESKY_VI;
	vec4 skyForest   = vec4(vec3(BIOMESKY_FR, BIOMESKY_FG, BIOMESKY_FB) / 255.0, 1.0) * BIOMESKY_FI;
	vec4 skyTaiga    = vec4(vec3(BIOMESKY_TR, BIOMESKY_TG, BIOMESKY_TB) / 255.0, 1.0) * BIOMESKY_TI;
	vec4 skyJungle   = vec4(vec3(BIOMESKY_JR, BIOMESKY_JG, BIOMESKY_JB) / 255.0, 1.0) * BIOMESKY_JI;

	float skyWeight = isCold + isDesert + isMesa + isSwamp + isMushroom + isSavanna + isForest + isJungle + isTaiga;

	vec4 biomeskyCol = mix(
		vec4(skyCol, 1.0),
		(
			skyCold * isCold  +  skyDesert * isDesert  +  skySavanna * isMesa    +
			skySwamp * isSwamp  +  skyMushroom * isMushroom  +  skySavanna * isSavanna +
			skyForest * isForest  +  skyJungle * isJungle  +  skyTaiga * isTaiga
		) / max(skyWeight, 0.0001),
		skyWeight
	);
	return biomeskyCol.rgb;
}
#endif

float mefade2 = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade2 = 1.0 - timeBrightness;

vec3 CalcSunSkyColor(vec3 morning, vec3 day, vec3 evening) {
	vec3 me = mix(morning, evening, mefade2);
	return mix(me, day, 1.0 - dfade2 * sqrt(dfade2));
}

vec3 CalcSkyColor(vec3 sun, vec3 night, vec3 weatherCol) {
	vec3 c = mix(night, sun, sunVisibility);
	c = mix(c, dot(c, vec3(0.299, 0.587, 0.114)) * weatherCol, rainStrength);
	return c * c;
}

float CalcSkyDensity(float morning, float day, float evening) {
	float me = mix(morning, evening, mefade2);
	return mix(me, day, 1.0 - dfade2 * sqrt(dfade2));
}

vec3 GetSkyColor(vec3 viewPos, bool isReflection) {
    vec3 nViewPos = normalize(viewPos);

    float VoU = clamp(dot(nViewPos,  upVec), -1.0, 1.0);
    float VoL = clamp(dot(nViewPos, sunVec), -1.5, 1.0);

    float groundDensity = 0.08 * (4.0 - 3.0 * sunVisibility) *
                          (10.0 * rainStrength * rainStrength + 1.0);
    
    float exposure = exp2(CalcSkyDensity(SKY_EXPOSURE_M, SKY_EXPOSURE_D, SKY_EXPOSURE_E));
    float nightExposure = exp2(-3.5 + SKY_EXPOSURE_N);
    float weatherExposure = exp2(SKY_EXPOSURE_W);

    float gradientCurve = mix(SKY_HORIZON_F, SKY_HORIZON_N, VoL);

    #ifdef TF
    gradientCurve = mix(SKY_HORIZON_F, SKY_HORIZON_N, VoU);
    #endif

    float baseGradient = exp(-(1.0 - pow(1.0 - max(VoU, 0.0), gradientCurve)) /
                             (CalcSkyDensity(SKY_DENSITY_M, SKY_DENSITY_D, SKY_DENSITY_E) + 0.025));

    #ifdef TF
    baseGradient = exp(-(1.0 - pow(1.0 - max(VoU, 0.0), gradientCurve)) / 0.75);
    #endif

    #if SKY_GROUND > 0
    float groundVoU = clamp(-VoU * 1.015 - 0.015, 0.0, 1.0);
    float ground = 1.0 - exp(-groundDensity * SKY_GROUND_I / groundVoU);
    #if SKY_GROUND == 1
    if (!isReflection) ground = 1.0;
    #endif
    #else
    float ground = 1.0;
    #endif

    vec3 weatherSky = weatherCol.rgb * weatherCol.rgb * weatherExposure;

    vec3 sky = mix(skyCol * 0.75, skyCol * skyCol, 0.75) * baseGradient;

    #ifdef TF
    sky = mix(tfSkyUp * 0.75, tfSkyUp * tfSkyUp, 0.75) * baseGradient;
    #endif

    #ifndef TF
    #if SKY_COLOR_MODE == 1
    vec3 biomeSky = CalcSkyColor(CalcSunSkyColor(skyCol, getBiomeskyColor() * getBiomeskyColor(), skyCol), skyCol * skylightNight, weatherSky.rgb);
    sky = biomeSky * skyCol * baseGradient / (SKY_I * SKY_I * SKY_I);
    #endif

    #ifdef SKY_VANILLA
    sky = mix(sky, fogCol * baseGradient, pow(1.0 - max(VoU, 0.0), 4.0));
    #endif
    #endif

    sky = sky / sqrt(sky * sky + 1.0) * exposure * sunVisibility * (SKY_I * SKY_I);

    float sunMix = (VoL * 0.5 + 0.5) * pow(clamp(1.0 - VoU, 0.0, 1.0), 2.0 - sunVisibility) *
                   pow(1.0 - timeBrightness * 0.6, 3.0);
    
    #ifdef TF
    sunMix = (VoU * 0.5 + 0.5) * pow(clamp(1.0 - VoU, 0.0, 1.0), 2.0 - sunVisibility) *
                   pow(1.0 - timeBrightness * 0.6, 3.0);   
    #endif

    float horizonMix = pow(1.0 - abs(VoU), 1.0) * HORIZON_EXPONENT * (1.0 - timeBrightness * 0.5);
    float lightMix = (1.0 - (1.0 - sunMix) * (1.0 - horizonMix));

    vec3 lightSky = pow(skylightSun, vec3(4.0 - sunVisibility)) * baseGradient;

    #ifdef TF
    lightSky = pow(tfSkyDown, vec3(4.0 - sunVisibility)) * baseGradient;
    #endif

    lightSky = lightSky / (1.0 + lightSky * rainStrength);

    sky = mix(
        sqrt(sky * (1.0 - lightMix)), 
        sqrt(lightSky) * (2 - VoU), 
        lightMix
    );

    sky *= sky;

    #ifndef TF
    float nightGradient = exp(-max(VoU, 0.0) / SKY_DENSITY_N);
    vec3 nightSky = skylightNight * skylightNight * nightGradient * nightExposure;
    sky = mix(nightSky, sky, sunVisibility * sunVisibility);

    float rainGradient = exp(-max(VoU, 0.0) / SKY_DENSITY_W);
    weatherSky *= GetLuminance(ambientCol / (weatherSky)) * (0.2 * sunVisibility + 0.2);
    sky = mix(sky, weatherSky * rainGradient, rainStrength);
    #endif

    sky *= ground;

    return sky;
}

#endif