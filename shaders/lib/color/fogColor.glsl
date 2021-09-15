float mefade1 = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade1 = 1.0 - timeBrightness;

vec3 CalcSunColor1(vec3 morning, vec3 day, vec3 evening) {
	vec3 me = mix(morning, evening, mefade1);
	return mix(me, day, 1.0 - dfade1 * sqrt(dfade1));
}

vec3 CalcLightColor1(vec3 sun, vec3 night, vec3 weatherCol) {
	vec3 c = mix(night, sun, sunVisibility);
	c = mix(c, dot(c, vec3(0.299, 0.587, 0.114)) * weatherCol, 1);
	return c * c;
}

vec3 vcMorning    = vec3(VCLOUD_MR,   VCLOUD_MG,   VCLOUD_MB)   * VCLOUD_MI / 255;
vec3 vcDay        = vec3(VCLOUD_DR,   VCLOUD_DG,   VCLOUD_DB)   * VCLOUD_DI / 255;
vec3 vcEvening    = vec3(VCLOUD_ER,   VCLOUD_EG,   VCLOUD_EB)   * VCLOUD_EI / 255;
vec3 vcNight      = vec3(VCLOUD_NR,   VCLOUD_NG,   VCLOUD_NB)   * VCLOUD_NI * 0.3 / 255;

vec3 vcSun = CalcSunColor1(vcMorning, vcDay, vcEvening);

#ifdef OVERWORLD
vec3 fogcolorMorning    = vec3(FOGCOLOR_MR,   FOGCOLOR_MG,   FOGCOLOR_MB)   * FOGCOLOR_MI / 255.0;
vec3 fogcolorDay        = vec3(FOGCOLOR_DR,   FOGCOLOR_DG,   FOGCOLOR_DB)   * FOGCOLOR_DI / 255.0;
vec3 fogcolorEvening    = vec3(FOGCOLOR_ER,   FOGCOLOR_EG,   FOGCOLOR_EB)   * FOGCOLOR_EI / 255.0;
vec3 fogcolorNight      = vec3(FOGCOLOR_NR,   FOGCOLOR_NG,   FOGCOLOR_NB)   * FOGCOLOR_NI * 0.3 / 255.0;

vec3 fogcolorSun    = CalcSunColor1(fogcolorMorning, fogcolorDay, fogcolorEvening);
vec4 fogColorC    	= vec4(CalcLightColor1(fogcolorSun, fogcolorNight, weatherCol.rgb), 1);

#if FOG_COLOR_MODE == 2 || defined PERBIOME_LIGHTSHAFTS
vec3 getBiomeFogColor(vec3 vpos){
	vec4 fogCold     = vec4(vec3(BIOMEFOG_CR, BIOMEFOG_CG, BIOMEFOG_CB) / 255.0, 1.0) * BIOMEFOG_CI;
	vec4 fogDesert   = vec4(vec3(BIOMEFOG_DR, BIOMEFOG_DG, BIOMEFOG_DB) / 255.0, 1.0) * BIOMEFOG_DI;
	vec4 fogSwamp    = vec4(vec3(BIOMEFOG_SR, BIOMEFOG_SG, BIOMEFOG_SB) / 255.0, 1.0) * BIOMEFOG_SI;
	vec4 fogMushroom = vec4(vec3(BIOMEFOG_MR, BIOMEFOG_MG, BIOMEFOG_MB) / 255.0, 1.0) * BIOMEFOG_MI;
	vec4 fogSavanna  = vec4(vec3(BIOMEFOG_VR, BIOMEFOG_VG, BIOMEFOG_VB) / 255.0, 1.0) * BIOMEFOG_VI;
	vec4 fogForest   = vec4(vec3(BIOMEFOG_FR, BIOMEFOG_FG, BIOMEFOG_FB) / 255.0, 1.0) * BIOMEFOG_FI;
	vec4 fogTaiga    = vec4(vec3(BIOMEFOG_TR, BIOMEFOG_TG, BIOMEFOG_TB) / 255.0, 1.0) * BIOMEFOG_TI;
	vec4 fogJungle   = vec4(vec3(BIOMEFOG_JR, BIOMEFOG_JG, BIOMEFOG_JB) / 255.0, 1.0) * BIOMEFOG_JI;

	float fogWeight = isCold + isDesert + isMesa + isSwamp + isMushroom + isSavanna + isForest + isJungle + isTaiga;

	vec4 biomeFogCol = mix(
		vec4(GetSkyColor(vpos, false), 1.0) * 4 * fogColorC,
		(
			fogCold  * isCold  + fogDesert * isDesert + fogSavanna * isMesa    +
			fogSwamp * isSwamp + fogMushroom * isMushroom + fogSavanna  * isSavanna +
			fogForest * isForest + fogJungle * isJungle + fogTaiga * isTaiga
		) / max(fogWeight, 0.0001),
		fogWeight
	);
	vec3 biomeFogColRGB = biomeFogCol.rgb;
	return biomeFogColRGB;
}
#if defined VOLUMETRIC_CLOUDS && defined PERBIOME_CLOUDS_COLOR
vec3 getBiomeCloudsColor(vec3 vpos){
	vec4 fogCold     = vec4(vec3(BIOMEFOG_CR, BIOMEFOG_CG, BIOMEFOG_CB) / 255.0, 1.0) * BIOMEFOG_CI;
	vec4 fogDesert   = vec4(vec3(BIOMEFOG_DR, BIOMEFOG_DG, BIOMEFOG_DB) / 255.0, 1.0) * BIOMEFOG_DI;
	vec4 fogSwamp    = vec4(vec3(BIOMEFOG_SR, BIOMEFOG_SG, BIOMEFOG_SB) / 255.0, 1.0) * BIOMEFOG_SI;
	vec4 fogMushroom = vec4(vec3(BIOMEFOG_MR, BIOMEFOG_MG, BIOMEFOG_MB) / 255.0, 1.0) * BIOMEFOG_MI;
	vec4 fogSavanna  = vec4(vec3(BIOMEFOG_VR, BIOMEFOG_VG, BIOMEFOG_VB) / 255.0, 1.0) * BIOMEFOG_VI;
	vec4 fogForest   = vec4(vec3(BIOMEFOG_FR, BIOMEFOG_FG, BIOMEFOG_FB) / 255.0, 1.0) * BIOMEFOG_FI;
	vec4 fogTaiga    = vec4(vec3(BIOMEFOG_TR, BIOMEFOG_TG, BIOMEFOG_TB) / 255.0, 1.0) * BIOMEFOG_TI;
	vec4 fogJungle   = vec4(vec3(BIOMEFOG_JR, BIOMEFOG_JG, BIOMEFOG_JB) / 255.0, 1.0) * BIOMEFOG_JI;

	float fogWeight = isCold + isDesert + isMesa + isSwamp + isMushroom + isSavanna + isForest + isJungle + isTaiga;

	vec4 biomeFogCol = mix(
		vec4(vcSun, 1.0),
		(
			fogCold  * isCold  + fogDesert * isDesert + fogSavanna * isMesa    +
			fogSwamp * isSwamp + fogMushroom * isMushroom + fogSavanna  * isSavanna +
			fogForest * isForest + fogJungle * isJungle + fogTaiga * isTaiga
		) / max(fogWeight, 0.0001),
		fogWeight
	);
	vec3 biomeFogColRGB = biomeFogCol.rgb;
	return biomeFogColRGB;
}
#endif

#endif

#endif