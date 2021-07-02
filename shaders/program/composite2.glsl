/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

uniform int isEyeInWater;
const bool colortex0MipmapEnabled = false;
const bool colortex1MipmapEnabled = true;

varying vec3 lightVec, sunVec, upVec;

varying vec4 texCoord;

uniform float timeAngle, timeBrightness;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D colortex4;
uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform float rainStrength;
uniform ivec2 eyeBrightnessSmooth;
uniform int worldTime;
uniform float frameTimeCounter;
uniform float viewWidth, viewHeight, aspectRatio;
uniform vec3 cameraPosition, previousCameraPosition;
uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;
uniform float far, near;

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
#include "/lib/prismarine/fragPos.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/prismarine/functions.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/prismarine/volumetricClouds.glsl"
#include "/lib/util/jitter.glsl"
#include "/lib/util/spaceConversion.glsl"

#ifdef OUTLINE_OUTER
#include "/lib/util/outlineOffset.glsl"
#include "/lib/util/outlineDepth.glsl"
#endif

void main() {
	vec3 color = texture2DLod(colortex0, texCoord.st, 0.0).rgb;
	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef MOTION_BLUR
	float z = texture2D(depthtex1, texCoord.st).x;

	#ifdef OUTLINE_OUTER
	DepthOutline(z);
	#endif

	color = MotionBlur(color, z, dither);
	#endif

	float pixeldepth = texture2D(depthtex1,texCoord.xy).x;
	float timeBrightnessLowered = timeBrightness / 1.5;
	vec4 fragpos = getFragPos(texCoord.xy,pixeldepth);
		
	#if defined OVERWORLD && CLOUDS == 3
	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif

	float VoS 		 = dot(normalize(viewPos), sunVec);
	float scattering = pow(VoS * 0.5 * (2.0 * sunVisibility - 1.0) + 0.5, 6.0);

	vec2 vc = vec2(texture2DLod(colortex4,texCoord.xy,float(2.0)).a,texture2DLod(colortex5,texCoord.xy,float(2.0)).a);
	float vcmult = 0.5*(1.0-moonVisibility*0.7)*(1.0-rainStrength*0.5);
	color = mix(color, mix(vcloudsCol.rgb, vcloudsCol.rgb, scattering * scattering) * vcmult * vc.x, vc.x * vc.y * VCLOUDS_OPACITY);
	#endif
		
	/* DRAWBUFFERS:07 */
	gl_FragData[0] = vec4(color, 1.0);
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