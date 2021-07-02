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
uniform float far, near;
uniform float viewHeight, viewWidth;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferModelView;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

uniform sampler2D depthtex0, depthtex1;
uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex4;
uniform sampler2D colortex5;

//Optifine Constants//
const bool colortex1MipmapEnabled = true;
const bool colortex4MipmapEnabled = true;
const bool colortex5MipmapEnabled = true;

//Common Variables//

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif

float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/jitter.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/prismarine/fragPos.glsl"
#include "/lib/prismarine/volumetricClouds.glsl"

//Program//
void main() {
	vec3 aux = texture2D(colortex5, texCoord.st).rgb;
	vec3 aux2 = texture2D(colortex4, texCoord.st).rgb;
	vec4 color = texture2D(colortex0, texCoord.st);
	float pixeldepth0 = texture2D(depthtex0, texCoord.xy).x;
	float pixeldepth1 = texture2D(depthtex1, texCoord.xy).x;
	float dither = Bayer64(gl_FragCoord.xy);

	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif

	vec3 vl = texture2DLod(colortex1, texCoord.xy, 1.5).rgb;
	vl *= vl;

	#ifdef OVERWORLD
	if (isEyeInWater == 0){
		#ifdef LIGHTSHAFT_AUTOCOLOR
		vl *= lightCol * 0.5;
		#else
		vl *= lightshaftCol * 0.5;
		#endif
	}
	#endif

	#ifdef END
    vl *= endCol.rgb * 0.1;
	#endif

    vl *= LIGHT_SHAFT_STRENGTH * (1.0 - rainStrength * eBS * 0.875) * shadowFade *
		  (1.0 - blindFactor);

	color.rgb += vl;

	#if defined OVERWORLD && CLOUDS == 3
	vec2 vc = vec2(0.0);
	vc = getVolumetricCloud(pixeldepth1, pixeldepth0);
	#endif

	/* DRAWBUFFERS:0145 */
	gl_FragData[0] = color;
	#if defined OVERWORLD && CLOUDS == 3
	gl_FragData[2] = vec4(aux2, vc.x);
	gl_FragData[3] = vec4(aux, vc.y);
	#endif
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