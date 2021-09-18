/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying float isWater;

varying vec2 texCoord, lmCoord;

varying vec3 sunVec, upVec;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;
uniform int worldTime;

uniform float blindFactor, nightVision;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;
uniform mat4 gbufferProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;

#ifdef REFRACTION
uniform sampler2D texture;
#endif

uniform sampler2D colortex0, noisetex;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#if FOG_MODE == 1 || FOG_MODE == 2
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
#endif

//Optifine Constants//
const bool colortex5Clear = false;

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

//Common Functions//
vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
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

#ifdef REFRACTION
float waterH(vec3 pos) {
	float noise  = texture2D(noisetex, (pos.xz + vec2(frametime) * 0.025 + pos.y) / 512 * 1).r;
		  noise += texture2D(noisetex, (pos.xz - vec2(frametime) * 0.075 - pos.y) / 512 * 2).r;
		  noise -= texture2D(noisetex, (pos.xz + vec2(frametime) * 0.100 + pos.y) / 512 * 4).r;
		  noise += texture2D(noisetex, (pos.xz - vec2(frametime) * 0.025 - pos.y) / 512 * 7).r;
		  noise -= texture2D(noisetex, (pos.xz + vec2(frametime) * 0.075 + pos.y) / 512 * 11).r;
		  noise += texture2D(noisetex, (pos.xz - vec2(frametime) * 0.100 - pos.y) / 512 * 15).r;

	noise /= pow(max(length(pos), 4.0), 0.35);
	return noise;
}

vec2 getRefract(vec2 coord, vec3 posxz){
	float deltaPos = 0.1;
	float h0 = waterH(posxz);
	float h1 = waterH(posxz + vec3(deltaPos, 0.0,0.0));
	float h2 = waterH(posxz + vec3(-deltaPos, 0.0,0.0));
	float h3 = waterH(posxz + vec3(0.0,0.0, deltaPos));
	float h4 = waterH(posxz + vec3(0.0,0.0, -deltaPos));

	float xDelta = ((h1-h0)+(h0-h2))/deltaPos;
	float yDelta = ((h3-h0)+(h0-h4))/deltaPos;

	vec2 newcoord = coord + vec2(xDelta,yDelta) * 0.0075;

	return mix(newcoord, coord, 0);
}
#endif

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/waterFog.glsl"

#ifdef REFRACTION
#include "/lib/util/spaceConversion.glsl"
#endif

#if FOG_MODE == 1 || FOG_MODE == 2
#include "/lib/prismarine/functions.glsl"
#include "/lib/atmospherics/volumetricLight.glsl"
#endif

#ifdef OUTLINE_ENABLED
#include "/lib/color/blocklightColor.glsl"
#include "/lib/util/outlineOffset.glsl"
#include "/lib/util/outlineMask.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/color/fogColor.glsl"
#include "/lib/atmospherics/fog.glsl"
#include "/lib/post/outline.glsl"
#endif

//Program//
void main() {
    vec4 color = texture2D(colortex0, texCoord);
    vec3 translucent = texture2D(colortex1, texCoord).rgb;
	float z0 = texture2D(depthtex0, texCoord).r;
	float z1 = texture2D(depthtex1, texCoord).r;
	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
	
	vec4 screenPos = vec4(texCoord.x, texCoord.y, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;
	
	#if ALPHA_BLEND == 0
	color.rgb = pow(color.rgb, vec3(2.2));
	#endif

	#ifdef OUTLINE_ENABLED
	vec4 outerOutline = vec4(0.0), innerOutline = vec4(0.0);
	float outlineMask = GetOutlineMask();
	if (outlineMask > 0.5 || isEyeInWater > 0.5)
		Outline(color.rgb, true, outerOutline, innerOutline);

	if(z1 > z0) color.rgb = mix(color.rgb, innerOutline.rgb, innerOutline.a);
	#endif

	if (isEyeInWater == 1.0) {
        vec4 screenPos = vec4(texCoord.x, texCoord.y, z0, 1.0);
		vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
		viewPos /= viewPos.w;

		vec4 waterFog = GetWaterFog(viewPos.xyz);
		color.rgb = mix(color.rgb, waterFog.rgb, waterFog.a);
	}

	#ifdef OUTLINE_ENABLED
	color.rgb = mix(color.rgb, outerOutline.rgb, outerOutline.a);
	#endif
	
	#if FOG_MODE == 1 || FOG_MODE == 2
	float dither = Bayer64(gl_FragCoord.xy);
	vec3 vl = GetLightShafts(z0, z1, translucent, dither);
	#else
	vec3 vl = vec3(0.0);
    #endif
	
	#ifdef REFRACTION
	float depth = z1 - z0;
	vec3 worldPos = ToWorld(viewPos.xyz);
	if (depth > 0){
		vec2 refractionCoord = getRefract(texCoord.xy, worldPos + cameraPosition);
		color = texture2D(colortex0, refractionCoord);
	}
	#endif

	vec3 reflectionColor = pow(color.rgb, vec3(0.125)) * 0.5;

    /*DRAWBUFFERS:01*/
	gl_FragData[0] = color;
	#if ((FOG_MODE == 1 || FOG_MODE == 2) && defined OVERWORLD) || (defined END_VOLUMETRIC_FOG && defined END)
	gl_FragData[1] = vec4(vl, 1.0);
	#endif
	
    #ifdef REFLECTION_PREVIOUS
    /*DRAWBUFFERS:015*/
	gl_FragData[2] = vec4(reflectionColor, float(z0 < 1.0));
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying float isWater;

varying vec2 texCoord, lmCoord;

varying vec3 sunVec, upVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Attributes//
attribute vec4 mc_Entity;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();

	isWater = 0;
	if (mc_Entity.x == 10300 || mc_Entity.x == 10303) isWater = 1;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
}

#endif