/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord;

varying vec3 sunVec, upVec, lightVec;

//Uniforms//
uniform int isEyeInWater;
uniform int worldTime;
uniform int frameCounter;

uniform float blindFactor;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float frameTimeCounter;
uniform float far, near;
uniform float viewHeight, viewWidth;
uniform float eyeAltitude;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD
uniform sampler2D colortex8;
uniform sampler2D colortex9;
#endif
uniform sampler2D noisetex;

//Optifine Constants//
const bool colortex1MipmapEnabled = true;

//Common Variables//
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif

float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float mefade0 = 1.0 - clamp(abs(timeAngle - 0.5) * 8.0 - 1.5, 0.0, 1.0);
float dfade0 = 1.0 - timeBrightness;

float CalcDayVisibility(float morning, float day, float evening) {
	float me = mix(morning, evening, mefade0);
	return mix(me, day, 1.0 - dfade0 * sqrt(dfade0));
}

float CalcVisibility(float sun, float night) {
	float c = mix(night, sun, sunVisibility);
	return c * c;
}

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/prismarine/functions.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/atmospherics/sky.glsl"

#ifdef PERBIOME_LIGHTSHAFTS
#include "/lib/color/fogColor.glsl"
#endif

#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD
#include "/lib/prismarine/fragPos.glsl"
#include "/lib/prismarine/volumetricClouds.glsl"
#endif

//Program//
void main() {
	#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD
	vec3 aux8 = texture2D(colortex8, texCoord.xy).rgb;
	vec3 aux9 = texture2D(colortex9, texCoord.xy).rgb;
	#endif

	#ifdef VOLUMETRIC_CLOUDS
	vec2 vc = vec2(0.0);
	#endif
	
	vec4 color = texture2D(colortex0, texCoord.xy);
	float pixeldepth0 = texture2D(depthtex0, texCoord.xy).x;

	vec4 viewPos = gbufferProjectionInverse * (vec4(texCoord.xy, pixeldepth0, 1.0) * 2.0 - 1.0);
		 viewPos /= viewPos.w;

	float dayVis0, nightVis0;
	
	#ifdef LIGHTSHAFT_NIGHT
	nightVis0 = 1;
	#endif

	#ifdef LIGHTSHAFT_DAY
	dayVis0 = 1;
	#endif

	if (isEyeInWater == 1){
		dayVis0 = 1;
		nightVis0 = 1;
	}

	float visibility0 = CalcVisibility(CalcDayVisibility(1, dayVis0, 1), nightVis0);

	#if ((FOG_MODE == 1 || FOG_MODE == 2) && defined OVERWORLD) || (defined END_VOLUMETRIC_FOG && defined END)
	vec3 vl = texture2DLod(colortex1, texCoord.xy, 1.5).rgb;
	vl *= vl;

	#ifdef OVERWORLD
	if (isEyeInWater == 1){
		vl *= waterShadowColor.rgb * (timeBrightness + LIGHTSHAFT_WI);
	}
	if (visibility0 > 0){
		#if LIGHTSHAFT_COLOR_MODE == 0
		vl *= lightCol * 0.25;
		#elif LIGHTSHAFT_COLOR_MODE == 1
		vl *= lightshaftCol * 0.25;
		#else
		vec3 lightshaftCol0 = CalcSunColor(GetSkyColor(viewPos.xyz, false), lightshaftDay * 0.25, GetSkyColor(viewPos.xyz, false));
		vec3 skylightshaftCol = CalcLightColor(lightshaftCol0, lightshaftNight * 0.50, waterColor.rgb);
		vl *= skylightshaftCol;
		#endif
		#endif
	}
	#ifdef FIREFLIES
	else {
		float visibility1 = (1 - sunVisibility) * (1 - rainStrength) * (0 + eBS);
		if (visibility1 > 0) vl *= vec3(80, 255, 200) * FIREFLIES_I;
	}		
	#endif

	#ifdef END
    vl *= endCol.rgb * 0.25;
	#endif

    vl *= LIGHT_SHAFT_STRENGTH * (1.0 - rainStrength * eBS * 0.875) * shadowFade *
		  (1.0 - blindFactor);

	color.rgb += vl;
	#endif

	#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD
	float dither = Bayer64(gl_FragCoord.xy);
	float pixeldepth1 = texture2D(depthtex1, texCoord.xy).x;
	vc = getVolumetricCloud(pixeldepth1, pixeldepth0, VCLOUDS_HEIGHT_ADJ_FACTOR, 2, dither);
	#endif

	/* DRAWBUFFERS:0189 */
	gl_FragData[0] = color;
	#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD
	gl_FragData[2] = vec4(aux8, vc.x);
	gl_FragData[3] = vec4(aux9, vc.y);
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
}

#endif