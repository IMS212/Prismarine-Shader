vec3 lightMorning    = vec3(LIGHT_MR,   LIGHT_MG,   LIGHT_MB)   * LIGHT_MI / 255.0;
vec3 lightDay        = vec3(LIGHT_DR,   LIGHT_DG,   LIGHT_DB)   * LIGHT_DI / 255.0;
vec3 lightEvening    = vec3(LIGHT_ER,   LIGHT_EG,   LIGHT_EB)   * LIGHT_EI / 255.0;
vec3 lightNight      = vec3(LIGHT_NR,   LIGHT_NG,   LIGHT_NB)   * LIGHT_NI * 0.3 / 255.0;

vec3 vcMorning    = vec3(VCLOUD_MR,   VCLOUD_MG,   VCLOUD_MB)   * VCLOUD_MI / 255;
vec3 vcDay        = vec3(VCLOUD_DR,   VCLOUD_DG,   VCLOUD_DB)   * VCLOUD_DI / 255;
vec3 vcEvening    = vec3(VCLOUD_ER,   VCLOUD_EG,   VCLOUD_EB)   * VCLOUD_EI / 255;
vec3 vcNight      = vec3(VCLOUD_NR,   VCLOUD_NG,   VCLOUD_NB)   * VCLOUD_NI * 0.3 / 255;

vec3 vcDownMorning    = vec3(VCLOUDDOWN_MR,   VCLOUDDOWN_MG,   VCLOUDDOWN_MB)   * VCLOUDDOWN_MI / 255;
vec3 vcDownDay        = vec3(VCLOUDDOWN_DR,   VCLOUDDOWN_DG,   VCLOUDDOWN_DB)   * VCLOUDDOWN_DI / 255;
vec3 vcDownEvening    = vec3(VCLOUDDOWN_ER,   VCLOUDDOWN_EG,   VCLOUDDOWN_EB)   * VCLOUDDOWN_EI / 255;
vec3 vcDownNight      = vec3(VCLOUDDOWN_NR,   VCLOUDDOWN_NG,   VCLOUDDOWN_NB)   * VCLOUDDOWN_NI * 0.3 / 255;

vec3 ambientMorning  = vec3(AMBIENT_MR, AMBIENT_MG, AMBIENT_MB) * AMBIENT_MI / 255.0;
vec3 ambientDay      = vec3(AMBIENT_DR, AMBIENT_DG, AMBIENT_DB) * AMBIENT_DI / 255.0;
vec3 ambientEvening  = vec3(AMBIENT_ER, AMBIENT_EG, AMBIENT_EB) * AMBIENT_EI / 255.0;
vec3 ambientNight    = vec3(AMBIENT_NR, AMBIENT_NG, AMBIENT_NB) * AMBIENT_NI * 0.3 / 255.0;

vec3 distfadeMorning    = vec3(DISTFADE_MR,   DISTFADE_MG,   DISTFADE_MB)   * DISTFADE_MI / 255.0;
vec3 distfadeDay        = vec3(DISTFADE_DR,   DISTFADE_DG,   DISTFADE_DB)   * DISTFADE_DI / 255.0;
vec3 distfadeEvening    = vec3(DISTFADE_ER,   DISTFADE_EG,   DISTFADE_EB)   * DISTFADE_EI / 255.0;
vec3 distfadeNight      = vec3(DISTFADE_NR,   DISTFADE_NG,   DISTFADE_NB)   * DISTFADE_NI * 0.3 / 255.0;

vec3 skylightMorning    = vec3(SKYLIGHT_MR,   SKYLIGHT_MG,   SKYLIGHT_MB)   * SKYLIGHT_MI / 255.0;
vec3 skylightDay        = vec3(SKYLIGHT_DR,   SKYLIGHT_DG,   SKYLIGHT_DB)   * SKYLIGHT_DI / 255.0;
vec3 skylightEvening    = vec3(SKYLIGHT_ER,   SKYLIGHT_EG,   SKYLIGHT_EB)   * SKYLIGHT_EI / 255.0;
vec3 skylightNight      = vec3(SKYLIGHT_NR,   SKYLIGHT_NG,   SKYLIGHT_NB)   * SKYLIGHT_NI * 0.3 / 255.0;

vec3 lightshaftMorning  = vec3(LIGHTSHAFT_MR, LIGHTSHAFT_MG, LIGHTSHAFT_MB) * LIGHTSHAFT_MI / 255.0;
vec3 lightshaftDay      = vec3(LIGHTSHAFT_DR, LIGHTSHAFT_DG, LIGHTSHAFT_DB) * LIGHTSHAFT_DI / 255.0;
vec3 lightshaftEvening  = vec3(LIGHTSHAFT_ER, LIGHTSHAFT_EG, LIGHTSHAFT_EB) * LIGHTSHAFT_EI / 255.0;
vec3 lightshaftNight    = vec3(LIGHTSHAFT_NR, LIGHTSHAFT_NG, LIGHTSHAFT_NB) * LIGHTSHAFT_NI * 0.3 / 255.0;
vec3 lightshaftWater    = vec3(LIGHTSHAFT_WR, LIGHTSHAFT_WG, LIGHTSHAFT_WB) * LIGHTSHAFT_WI / 255.0;

vec3 cloudlightMorning    = vec3(CLOUDLIGHT_MR,   CLOUDLIGHT_MG,   CLOUDLIGHT_MB)   * CLOUDLIGHT_MI / 255.0;
vec3 cloudlightDay        = vec3(CLOUDLIGHT_DR,   CLOUDLIGHT_DG,   CLOUDLIGHT_DB)   * CLOUDLIGHT_DI / 255.0;
vec3 cloudlightEvening    = vec3(CLOUDLIGHT_ER,   CLOUDLIGHT_EG,   CLOUDLIGHT_EB)   * CLOUDLIGHT_EI / 255.0;
vec3 cloudlightNight      = vec3(CLOUDLIGHT_NR,   CLOUDLIGHT_NG,   CLOUDLIGHT_NB)   * CLOUDLIGHT_NI * 0.3 / 255.0;

vec3 cloudambientMorning  = vec3(CLOUDAMBIENT_MR, CLOUDAMBIENT_MG, CLOUDAMBIENT_MB) * CLOUDAMBIENT_MI / 255.0;
vec3 cloudambientDay      = vec3(CLOUDAMBIENT_DR, CLOUDAMBIENT_DG, CLOUDAMBIENT_DB) * CLOUDAMBIENT_DI / 255.0;
vec3 cloudambientEvening  = vec3(CLOUDAMBIENT_ER, CLOUDAMBIENT_EG, CLOUDAMBIENT_EB) * CLOUDAMBIENT_EI / 255.0;
vec3 cloudambientNight    = vec3(CLOUDAMBIENT_NR, CLOUDAMBIENT_NG, CLOUDAMBIENT_NB) * CLOUDAMBIENT_NI * 0.3 / 255.0;

vec3 cloudlightEnd      = vec3(CLOUDS_END_R,   CLOUDS_END_G,   CLOUDS_END_B)   * CLOUDS_END_I / 64.0;
vec3 cloudambientEnd    = vec3(CLOUDS_END_R,   CLOUDS_END_G,   CLOUDS_END_B)   * CLOUDS_END_I * 0.2 / 64.0;

#ifdef WEATHER_PERBIOME
uniform float isDesert, isMesa, isCold, isSwamp, isMushroom, isSavanna;

vec4 weatherRain     = vec4(vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0, 1.0) * WEATHER_RI;
vec4 weatherCold     = vec4(vec3(WEATHER_CR, WEATHER_CG, WEATHER_CB) / 255.0, 1.0) * WEATHER_CI;
vec4 weatherDesert   = vec4(vec3(WEATHER_DR, WEATHER_DG, WEATHER_DB) / 255.0, 1.0) * WEATHER_DI;
vec4 weatherBadlands = vec4(vec3(WEATHER_BR, WEATHER_BG, WEATHER_BB) / 255.0, 1.0) * WEATHER_BI;
vec4 weatherSwamp    = vec4(vec3(WEATHER_SR, WEATHER_SG, WEATHER_SB) / 255.0, 1.0) * WEATHER_SI;
vec4 weatherMushroom = vec4(vec3(WEATHER_MR, WEATHER_MG, WEATHER_MB) / 255.0, 1.0) * WEATHER_MI;
vec4 weatherSavanna  = vec4(vec3(WEATHER_VR, WEATHER_VG, WEATHER_VB) / 255.0, 1.0) * WEATHER_VI;

float weatherWeight = isCold + isDesert + isMesa + isSwamp + isMushroom + isSavanna;

vec4 weatherCol = mix(
	weatherRain,
	(
		weatherCold  * isCold  + weatherDesert   * isDesert   + weatherBadlands * isMesa    +
		weatherSwamp * isSwamp + weatherMushroom * isMushroom + weatherSavanna  * isSavanna
	) / max(weatherWeight, 0.0001),
	weatherWeight
);

#else
vec4 weatherCol = vec4(vec3(WEATHER_RR, WEATHER_RG, WEATHER_RB) / 255.0, 1.0) * WEATHER_RI;
#endif

float mefade = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade = 1.0 - timeBrightness;

vec3 CalcSunColor(vec3 morning, vec3 day, vec3 evening) {
	vec3 me = mix(morning, evening, mefade);
	return mix(me, day, 1.0 - dfade * sqrt(dfade));
}

vec3 CalcLightColor(vec3 sun, vec3 night, vec3 weatherCol) {
	vec3 c = mix(night, sun, sunVisibility);
	c = mix(c, dot(c, vec3(0.299, 0.587, 0.114)) * weatherCol, rainStrength);
	return c * c;
}

vec3 lightSun     	   = CalcSunColor(lightMorning, lightDay, lightEvening);
vec3 ambientSun   	   = CalcSunColor(ambientMorning, ambientDay, ambientEvening);
vec3 distfadeSun       = CalcSunColor(distfadeMorning, distfadeDay, distfadeEvening);
vec3 skylightSun       = CalcSunColor(skylightMorning, skylightDay, skylightEvening);
vec3 lightshaftSun     = CalcSunColor(lightshaftMorning, lightshaftDay, lightshaftEvening);
vec3 vcSun     		   = CalcSunColor(vcMorning, vcDay, vcEvening);
vec3 vcDownSun     	   = CalcSunColor(vcDownMorning, vcDownDay, vcDownEvening);
vec3 cloudlightSun     = CalcSunColor(cloudlightMorning, cloudlightDay, cloudlightEvening);
vec3 cloudambientSun   = CalcSunColor(cloudambientMorning, cloudambientDay, cloudambientEvening);

vec3 distfadeCol    = CalcLightColor(distfadeSun, distfadeNight, weatherCol.rgb);
vec3 lightCol       = CalcLightColor(lightSun, lightNight, weatherCol.rgb);
vec3 ambientCol     = CalcLightColor(ambientSun, ambientNight, weatherCol.rgb);
vec3 lightshaftCol  = CalcLightColor(lightshaftSun, lightshaftNight, weatherCol.rgb);
vec3 vcloudsCol     = CalcLightColor(vcSun, vcNight, weatherCol.rgb * 0.4);
vec3 vcloudsDownCol = CalcLightColor(vcDownSun, vcDownNight, weatherCol.rgb * 0.4);
vec3 cloudUpCol     = CalcLightColor(cloudlightSun, cloudlightNight, weatherCol.rgb);
vec3 cloudDownCol   = CalcLightColor(cloudambientSun, cloudambientNight, weatherCol.rgb);
