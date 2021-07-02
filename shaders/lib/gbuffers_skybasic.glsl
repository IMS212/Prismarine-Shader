/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying float star;
varying vec2 texCoord;
varying vec3 upVec, sunVec;

//Uniforms//
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor;
uniform float frameCounter;
uniform float frameTimeCounter;
uniform float nightVision;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;
uniform float far, near;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform sampler2D colortex8;
uniform sampler2D colortex7;
uniform sampler2D noisetex;

//Common Variables//
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

vec3 lightVec = sunVec * (1.0 - 2.0 * float(timeAngle > 0.5325 && timeAngle < 0.9675));

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

void RoundSunMoon(inout vec3 color, vec3 viewPos, vec3 sunColor, vec3 moonColor) {
	float VoL = dot(normalize(viewPos),sunVec);
	float isMoon = float(VoL < 0.0);
	float sun = pow(abs(VoL), 800.0 * isMoon + 800.0) * (1.0 - sqrt(rainStrength));

	vec3 sunMoonCol = mix(moonColor * moonVisibility, sunColor * sunVisibility, float(VoL > 0.0));
	color += sun * sunMoonCol * 32.0;
}

void SunGlare(inout vec3 color, vec3 viewPos, vec3 lightCol) {
	float VoL = dot(normalize(viewPos), lightVec);
	float visfactor = 0.05 * (-0.8 * timeBrightness + 1.0) * (3.0 * rainStrength + 1.0);
	float invvisfactor = 1.0 - visfactor;

	float visibility = clamp(VoL * 0.5 + 0.5, 0.0, 1.0);
    visibility = visfactor / (1.0 - invvisfactor * visibility) - visfactor;
	visibility = clamp(visibility * 1.015 / invvisfactor - 0.015, 0.0, 1.0);
	visibility = mix(1.0, visibility, 0.25 * eBS + 0.75) * (1.0 - rainStrength * eBS * 0.875);
	visibility *= shadowFade * LIGHT_SHAFT_STRENGTH;
	if (cameraPosition.y < 1.0) visibility *= exp(2.0 * cameraPosition.y - 2.0);

	#ifdef LIGHT_SHAFT
	if (isEyeInWater == 1) color += 0.25 * lightCol * visibility;
	#endif
	#ifdef SUN_GLARE
	color += 0.75 * lightCol * visibility * (1.0 + 0.25 * isEyeInWater) * 0.2;
	#endif
}

//Includes//
#include "/lib/color/endColor.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/prismarine/functions.glsl"
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/prismarine/simpleSky.glsl"

//Program//
void main() {
	vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	vec3 nViewPos = normalize(viewPos.xyz);
	float NdotU = dot(nViewPos, upVec);
	float clampNdotU = x2(x2(clamp(NdotU * 3.0, 0.0, 1.0)));
	float dither = Bayer64(gl_FragCoord.xy);
	vec3 wpos = normalize((gbufferModelViewInverse * viewPos).xyz);

	#ifdef OVERWORLD
	
	#if SKY_MODE == 2
    vec3 worldvec = normalize(mat3(gbufferModelViewInverse) * (viewPos.xyz));
    vec3 sun_vec = normalize(mat3(gbufferModelViewInverse) * sunVec);
    mat2x3 light_vec;
        light_vec[0] = sun_vec;
        light_vec[1] = -sun_vec;

    vec3 albedo = renderAtmosphere(worldvec, light_vec);

	#elif SKY_MODE == 1
	vec3 albedo = GetSkyColor(viewPos.xyz, false);

	#elif SKY_MODE == 0
	vec3 albedo = GetSkyColor(viewPos.xyz, false);

    vec3 worldvec = normalize(mat3(gbufferModelViewInverse) * (viewPos.xyz));
    vec3 sun_vec = normalize(mat3(gbufferModelViewInverse) * sunVec);
    mat2x3 light_vec;
        light_vec[0] = sun_vec;
        light_vec[1] = -sun_vec;
	vec3 atmRain = renderAtmosphere(worldvec, light_vec) * rainStrength;
	albedo += renderAtmosphere(worldvec, light_vec) - atmRain;
	#endif
	
	#ifdef ROUND_SUN_MOON
	vec3 lightMA = mix(lightMorning, lightEvening, mefade);
    vec3 sunColor = mix(lightMA, sqrt(lightDay * lightMA * LIGHT_DI), timeBrightness);
    vec3 moonColor = sqrt(lightNight);

	RoundSunMoon(albedo, viewPos.xyz, sunColor, moonColor);
	#endif

	#ifdef STARS
	DrawStars(albedo.rgb, viewPos.xyz);
	#endif

	#ifdef AURORA
	albedo.rgb += DrawAurora(viewPos.xyz, dither, 24);
	#endif
	
	#if NIGHT_SKY_MODE == 0 || NIGHT_SKY_MODE == 2
		vec3 planeCoord = wpos / (wpos.y + length(wpos.xz) * 0.5);
		vec3 moonPos = vec3(gbufferModelViewInverse * vec4(-sunVec, 1.0));
		vec3 moonCoord = moonPos / (moonPos.y + length(moonPos.xz));
		vec2 hcoord = planeCoord.xz - moonCoord.xz;
		hcoord *= 0.2;

		if (moonVisibility > 0.0 && rainStrength == 0.0){
			vec3 helios = texture2D(colortex8, hcoord * 0.8 + 0.6).rgb;
			helios *= x2(length(helios) + 0.6);
			albedo.rgb += helios * 0.05 * clampNdotU * (1.0 - sunVisibility);
		}
	#endif

	#if NIGHT_SKY_MODE == 1 || NIGHT_SKY_MODE == 2
		vec3 planeCoord2 = wpos / (wpos.y + length(wpos.xz) * 0.5);
		vec3 moonPos2 = vec3(gbufferModelViewInverse * vec4(-sunVec, 1.0));
		vec3 moonCoord2 = moonPos2 / (moonPos2.y + length(moonPos2.xz));
		vec2 ncoord = planeCoord2.xz - moonCoord2.xz;
		ncoord *= 0.2;

		if (moonVisibility > 0.0 && rainStrength == 0.0){
			vec3 nebula = texture2D(colortex7, ncoord * 0.8 + 0.6).rgb;
			nebula *= x2(length(nebula) + 0.6);
			albedo.rgb += nebula * 0.05 * clampNdotU * (1.0 - sunVisibility);
		}
	#endif

	#if CLOUDS == 1
	vec4 cloud = vec4(0.0);
	#ifdef CLOUD_UPPER_LAYER
	cloud += DrawCloud(viewPos.xyz, dither, lightCol, ambientCol);
	albedo.rgb = mix(albedo.rgb, cloud.rgb, cloud.a);
	#endif

	#ifdef CLOUD_LOWER_LAYER
	cloud += DrawLowerCloud(viewPos.xyz, dither, lightCol, ambientCol);
	albedo.rgb = mix(albedo.rgb, cloud.rgb, cloud.a);
	#endif
	#endif

	SunGlare(albedo, viewPos.xyz, lightCol);

	albedo.rgb *= (4.0 - 3.0 * eBS) * (1.0 + nightVision);
	#endif
	
	#ifdef END
	vec3 albedo = vec3(190, 120, 255) / 255;

	#ifndef SKY_DESATURATION
	albedo.rgb = endCol.rgb;
	#endif

	#ifdef STARS
	DrawStars(albedo.rgb, viewPos.xyz);
	#endif

	#if END_SKY == 2 || END_SKY == 3
	vec4 cloud = DrawCloud(viewPos.xyz, dither, lightCol, ambientCol);
	albedo.rgb += mix(albedo.rgb, cloud.rgb, cloud.a);
	#endif

	#if END_SKY == 1 || END_SKY == 3
	albedo.rgb += DrawAurora(viewPos.xyz, dither, 24);
	#endif
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(albedo, 1.0 - star);
    #if (CLOUDS == 1 && defined OVERWORLD) || (CLOUDS == 1 && (defined END_SKY == 2 || defined END_SKY == 3) && defined END)
    /* DRAWBUFFERS:04 */
	gl_FragData[1] = vec4(cloud.a, 0.0, 0.0, 0.0);
    #endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying float star;
varying vec2 texCoord;
varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	
	gl_Position = ftransform();

	star = float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0);
}

#endif