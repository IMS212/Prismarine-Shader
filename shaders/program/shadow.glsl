/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying float mat;
varying vec4 texCoord, position;

varying vec3 sunVec, upVec, eastVec;

uniform vec3 cameraPosition;
varying vec4 color;

//Uniforms//
uniform float rainStrength;
uniform float frameTimeCounter;
uniform float timeAngle, timeBrightness;
uniform int blockEntityId;
uniform int isEyeInWater;
uniform int worldTime;

uniform sampler2D noisetex;
uniform sampler2D tex;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

#include "/lib/color/waterColor.glsl"
#include "/lib/color/lightColor.glsl"
#include "/lib/prismarine/functions.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/prismarine/caustics.glsl"

//Program//
void main() {
    #if MC_VERSION >= 11300
	if (blockEntityId == 10250) discard;
	#endif

    vec4 albedo = texture2D(tex, texCoord.xy);
	albedo.rgb *= color.rgb;

    float premult = float(mat > 0.98 && mat < 1.02);
	float disable = float(mat > 1.98 && mat < 2.02);
	float water = float (mat > 2.98);

	if (disable > 0.5 || albedo.a < 0.01) discard;

    #ifdef SHADOW_COLOR
	albedo.rgb = mix(vec3(1), albedo.rgb, pow(albedo.a, (1.0 - albedo.a) * 0.5) * COLORED_SHADOW_OPACITY * 2);
	albedo.rgb *= 1.0 - pow(albedo.a, 128.0);
	#else
	if ((premult > 0.5 && albedo.a < 0.98)) albedo.a = 0.0;
	#endif
	
	#ifdef WATER_TINT
	if (water > 0.9){
		albedo.rgb = waterShadowColor.rgb * lightshaftWater.rgb * lightCol.rgb * (WATER_I * 16 - isEyeInWater - isEyeInWater - isEyeInWater - isEyeInWater);
	}
	#endif

	#ifdef PROJECTED_CAUSTICS
	if (water > 0.9){
		vec3 caustic = (getCaustics(position.xyz+cameraPosition.xyz) * WATER_CAUSTICS_STRENGTH) * waterShadowColor.rgb * lightshaftWater.rgb * lightCol.rgb * WATER_I * (0.5 + isEyeInWater);
		albedo.rgb *= caustic;
	}
	#endif

	gl_FragData[0] = albedo;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying float mat;

varying vec4 texCoord, position;
varying vec3 sunVec, upVec, eastVec;
varying vec4 color;

//Uniforms//
uniform int worldTime;
uniform float timeAngle;
uniform float frameTimeCounter;

uniform vec3 cameraPosition;

uniform mat4 gbufferModelView, gbufferModelViewInverse;
uniform mat4 shadowProjection, shadowProjectionInverse;
uniform mat4 shadowModelView, shadowModelViewInverse;

//Attributes//
attribute vec4 mc_Entity;
attribute vec4 mc_midTexCoord;

//Common Variables//
#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

//Includes//
#include "/lib/vertex/waving.glsl"

#ifdef WORLD_CURVATURE
#include "/lib/vertex/worldCurvature.glsl"
#endif

//Program//
void main() {
	texCoord = gl_MultiTexCoord0;

	color = gl_Color;
	
	mat = 0;
	if (mc_Entity.x == 10301) mat = 1;
	if (mc_Entity.x == 10249 || mc_Entity.x == 10252) mat = 2;
	if (mc_Entity.x == 10300) mat = 3;
	
	position = shadowModelViewInverse * shadowProjectionInverse * ftransform();
	
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = WavingBlocks(position.xyz, istopv);

	#ifdef WORLD_CURVATURE
	position.y -= WorldCurvature(position.xz);
	#endif

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
	
	gl_Position = shadowProjection * shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif