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

varying vec3 upVec, sunVec, lightVec;

varying vec4 color;

//Uniforms//
uniform float nightVision;
uniform float rainStrength;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight;
uniform float shadowFade;

uniform ivec2 eyeBrightnessSmooth;

uniform mat4 gbufferProjectionInverse;

uniform sampler2D texture;
uniform sampler2D gaux1;

#ifdef END
uniform float frameTimeCounter;
uniform float worldTime;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform sampler2D noisetex;
#endif

//Common Variables//
#if defined END && defined CLOUDS
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

//Includes//
#ifdef OVERWORLD
#include "/lib/color/lightColor.glsl"
#endif
#if defined CLOUDS && defined END
#include "/lib/prismarine/functions.glsl"
#include "/lib/color/endColor.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/clouds.glsl"
#include "/lib/atmospherics/sky.glsl"
#endif

//Program//
void main() {
	vec4 albedo = texture2D(texture, texCoord);
	vec4 screenPos = vec4(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef OVERWORLD
	albedo *= color;
	albedo.rgb = pow(albedo.rgb,vec3(2.2)) * SKYBOX_BRIGHTNESS * albedo.a;

	#if CLOUDS == 1
	if (albedo.a > 0.0) {
		float cloudAlpha = texture2D(gaux1, gl_FragCoord.xy / vec2(viewWidth, viewHeight)).r;
		float alphaMult = 1.0 - 0.6 * rainStrength;
		albedo.a *= 1.0 - cloudAlpha / (alphaMult * alphaMult);
	}
	#endif
	#endif

	#ifdef END
	albedo.rgb = pow(albedo.rgb,vec3(2.2));

	vec3 nViewPos = normalize(viewPos.xyz);
	float NdotU = dot(nViewPos, upVec);
	float dither = Bayer64(gl_FragCoord.xy);
	vec3 wpos = normalize((gbufferModelViewInverse * viewPos).xyz);
	
	#ifdef STARS
	DrawStars(albedo.rgb, viewPos.xyz);
	DrawBigStars(albedo.rgb, viewPos.xyz);
	#endif

	#if END_SKY == 2 || END_SKY == 3
	vec4 cloud = DrawCloud(viewPos.xyz, dither, lightCol, ambientCol);
	albedo.rgb += mix(albedo.rgb, cloud.rgb, cloud.a);
	#endif

	#if END_SKY == 1 || END_SKY == 3
	albedo.rgb += DrawRift(viewPos.xyz, dither, 32);
	#endif

	#ifdef SKY_DESATURATION
	#ifdef END
	albedo.rgb = GetLuminance(albedo.rgb) * endCol.rgb;
	#endif
	#endif

	albedo.rgb *= SKYBOX_BRIGHTNESS * 0.02;
	#endif
	
    /* DRAWBUFFERS:0 */
	gl_FragData[0] = albedo;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

varying vec3 sunVec, upVec;

varying vec4 color;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

#ifdef TAA
uniform int frameCounter;

uniform float viewWidth;
uniform float viewHeight;
#include "/lib/util/jitter.glsl"
#endif

//Program//
void main() {
	texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;

	color = gl_Color;
	
	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	
	gl_Position = ftransform();
	
	#ifdef TAA
	gl_Position.xy = TAAJitter(gl_Position.xy, gl_Position.w);
	#endif
}

#endif