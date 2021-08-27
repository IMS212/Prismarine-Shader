/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec4 texCoord;

varying vec3 sunVec, upVec, lightVec;

//Uniforms//
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float frameTimeCounter;
uniform float viewHeight, viewWidth, aspectRatio;
uniform float eyeAltitude;
uniform float isTaiga, isJungle, isBadlands, isForest;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferPreviousProjection;

uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex8;
uniform sampler2D colortex9;
uniform sampler2D noisetex;

//Optifine Constants//
const bool colortex1MipmapEnabled = true;
const bool colortex8MipmapEnabled = true;
const bool colortex9MipmapEnabled = true;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif

float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

vec3 MotionBlur(vec3 color, float z, float dither) {
		
	float hand = float(z < 0.56);

	if (hand < 0.5) {
		float mbwg = 0.0;
		vec2 doublePixel = 2.0 / vec2(viewWidth, viewHeight);
		vec3 mblur = vec3(0.0);
			
		vec4 currentPosition = vec4(texCoord.xy, z, 1.0) * 2.0 - 1.0;
			
		vec4 viewPos = gbufferProjectionInverse * currentPosition;
		viewPos = gbufferModelViewInverse * viewPos;
		viewPos /= viewPos.w;
			
		vec3 cameraOffset = cameraPosition - previousCameraPosition;
			
		vec4 previousPosition = viewPos + vec4(cameraOffset, 0.0);
		previousPosition = gbufferPreviousModelView * previousPosition;
		previousPosition = gbufferPreviousProjection * previousPosition;
		previousPosition /= previousPosition.w;

		vec2 velocity = (currentPosition - previousPosition).xy;
		velocity = velocity / (1.0 + length(velocity)) * MOTION_BLUR_STRENGTH * 0.02;
			
		vec2 coord = texCoord.st - velocity * (1.5 + dither);
		for(int i = 0; i < 5; i++, coord += velocity) {
			vec2 sampleCoord = clamp(coord, doublePixel, 1.0 - doublePixel);
			float mask = float(texture2D(depthtex1, sampleCoord).r > 0.56);
			mblur += texture2DLod(colortex0, sampleCoord, 0.0).rgb * mask;
			mbwg += mask;
		}
		mblur /= max(mbwg, 1.0);

		return mblur;
	}
	else return color;
}

#include "/lib/util/dither.glsl"

#ifdef OUTLINE_OUTER
#include "/lib/util/outlineOffset.glsl"
#include "/lib/util/outlineDepth.glsl"
#endif

#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/color/fogColor.glsl"
#endif

void main() {
	vec3 color = texture2DLod(colortex0, texCoord.st, 0.0).rgb;
	float dither = Bayer64(gl_FragCoord.xy);
	float z = texture2D(depthtex1, texCoord.st).x;

	#ifdef MOTION_BLUR

	#ifdef OUTLINE_OUTER
	DepthOutline(z);
	#endif

	color = MotionBlur(color, z, dither);
	#endif

	#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD && SKY_COLOR_MODE == 1
	vec4 currentPosition = vec4(texCoord.xy, z, 1.0) * 2.0 - 1.0;
	vec4 viewPos = gbufferProjectionInverse * currentPosition;
	viewPos = gbufferModelViewInverse * viewPos;
	viewPos /= viewPos.w;

	vec2 vc = vec2(texture2DLod(colortex8, texCoord.xy, float(2.0)).a, texture2DLod(colortex9, texCoord.xy, float(2.0)).a);
	color = mix(color, mix(vcloudsDownCol * getBiomeCloudsColor(viewPos.xyz), vcloudsCol * getBiomeCloudsColor(viewPos.xyz), vc.x) * (1.0 - rainStrength * 0.25), vc.y * vc.y * VCLOUDS_OPACITY);
	#endif

	#if defined VOLUMETRIC_CLOUDS && defined OVERWORLD && SKY_COLOR_MODE != 1
	vec2 vc = vec2(texture2DLod(colortex8, texCoord.xy, float(2.0)).a, texture2DLod(colortex9, texCoord.xy, float(2.0)).a);
	color = mix(color, mix(vcloudsDownCol, vcloudsCol, vc.x) * (1.0 - rainStrength * 0.25), vc.y * vc.y * VCLOUDS_OPACITY);
	#endif

	/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(color, 0.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec4 texCoord;

varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0;
	
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
}

#endif