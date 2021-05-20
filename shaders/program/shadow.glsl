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

varying vec2 texCoord, lmCoord;
varying vec3 sunVec, upVec, eastVec;
varying vec3 wpos;
varying vec4 color;

//Uniforms//
uniform vec3 cameraPosition;
uniform int blockEntityId;
uniform float isEyeInWater;
uniform sampler2D tex;
uniform sampler2D noisetex;
uniform float frameTimeCounter;
uniform int worldTime;
uniform float viewWidth, viewHeight;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;

float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/util/jitter.glsl"
#include "/lib/prismarine/caustics.glsl"

//Common Functions//

#ifdef TOON_LIGHTMAP
vec2 lightmap = floor(lmCoord * 14.999 * (0.75 + 0.25 * color.a)) / 14.0;
lightmap = clamp(lightmap, vec2(0.0), vec2(1.0));
#else
vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
#endif

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif

#ifdef WATER_TINT
#endif

//Program//
void main() {
    #if MC_VERSION >= 11300
	if (blockEntityId == 10250) discard;
	#endif

    vec4 albedo = texture2D(tex, texCoord.xy);
	albedo.rgb *= color.rgb;

    float premult = float(mat > 0.98 && mat < 1.02);
	float water = float(mat > 8);
	float disable = float(mat > 1.98 && mat < 2.02);
	if (disable > 0.5 || albedo.a < 0.01) discard;

    #ifdef SHADOW_COLOR
	albedo.rgb = mix(vec3(1),albedo.rgb,pow(albedo.a,(1.0-albedo.a)*0.5)*1.05);
	albedo.rgb *= 1.0-pow(albedo.a,32.0);
	if (water > 0.9){
		#if defined OVERWORLD && defined WATER_TINT
		//float caustic = getCausticWaves(wpos);
		//albedo.rgb = vec3(1.0+3.0*caustic);
		albedo.rgb = vec3(waterColor.r, waterColor.g * 0.8, waterColor.b) * WATER_I;
		#endif
		}
	#else
	if ((premult > 0.5 && albedo.a < 0.98)) albedo.a = 0.0;
	#endif
	
	gl_FragData[0] = albedo;
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying float mat;

varying vec2 texCoord, lmCoord;
varying vec3 wpos;
varying vec4 color;

//Uniforms//
uniform int worldTime;

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
	texCoord = gl_MultiTexCoord0.xy;
	vec4 cposition = gl_Position;
	cposition = shadowProjectionInverse * cposition;
	cposition = shadowModelViewInverse * cposition;
	wpos = cposition.xyz*1.1+cameraPosition.xyz;
	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	color = gl_Color;
	
	mat = 0;
	if (mc_Entity.x == 10301) mat = 1;
	if (mc_Entity.x == 10249 || mc_Entity.x == 10252) mat = 2;
	if (mc_Entity.x == 10300) mat = 9.0;
	
	vec4 position = shadowModelViewInverse * shadowProjectionInverse * ftransform();
	
	float istopv = gl_MultiTexCoord0.t < mc_midTexCoord.t ? 1.0 : 0.0;
	position.xyz = WavingBlocks(position.xyz, istopv);

	#ifdef WORLD_CURVATURE
	position.y -= WorldCurvature(position.xz);
	#endif
	
	gl_Position = shadowProjection * shadowModelView * position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = dist * shadowMapBias + (1.0 - shadowMapBias);
	
	gl_Position.xy *= 1.0 / distortFactor;
	gl_Position.z = gl_Position.z * 0.2;
}

#endif