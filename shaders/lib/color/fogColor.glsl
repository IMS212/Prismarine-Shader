vec3 vcMorning    = vec3(VCLOUD_MR,   VCLOUD_MG,   VCLOUD_MB)   * VCLOUD_MI / 255;
vec3 vcDay        = vec3(VCLOUD_DR,   VCLOUD_DG,   VCLOUD_DB)   * VCLOUD_DI / 255;
vec3 vcEvening    = vec3(VCLOUD_ER,   VCLOUD_EG,   VCLOUD_EB)   * VCLOUD_EI / 255;
vec3 vcNight      = vec3(VCLOUD_NR,   VCLOUD_NG,   VCLOUD_NB)   * VCLOUD_NI * 0.3 / 255;

vec3 vcSun = CalcSunColor(vcMorning, vcDay, vcEvening);

#ifdef OVERWORLD
vec3 fogcolorMorning    = vec3(FOGCOLOR_MR,   FOGCOLOR_MG,   FOGCOLOR_MB)   * FOGCOLOR_MI / 255.0;
vec3 fogcolorDay        = vec3(FOGCOLOR_DR,   FOGCOLOR_DG,   FOGCOLOR_DB)   * FOGCOLOR_DI / 255.0;
vec3 fogcolorEvening    = vec3(FOGCOLOR_ER,   FOGCOLOR_EG,   FOGCOLOR_EB)   * FOGCOLOR_EI / 255.0;
vec3 fogcolorNight      = vec3(FOGCOLOR_NR,   FOGCOLOR_NG,   FOGCOLOR_NB)   * FOGCOLOR_NI * 0.3 / 255.0;

vec3 fogcolorSun    = CalcSunColor(fogcolorMorning, fogcolorDay, fogcolorEvening);
vec4 fogColorC    	= vec4(CalcLightColor(fogcolorSun, fogcolorNight, weatherCol.rgb), 1);

#if FOG_COLOR_MODE == 2 || defined PERBIOME_LIGHTSHAFTS
vec3 getBiomeFogColor(){
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
		fogColorC,
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
vec3 getBiomeCloudsColor(){
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