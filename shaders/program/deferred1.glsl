/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

//Fragment Shader///////////////////////////////////////////////////////////////////////////////////
#ifdef FSH

//Varyings//
varying vec2 texCoord, lmCoord;

varying vec3 sunVec, upVec, eastVec;

//Uniforms//
uniform int frameCounter;
uniform int isEyeInWater;

uniform float blindFactor, nightVision;
uniform float far, near;
uniform float frameTimeCounter;
uniform float rainStrength;
uniform float shadowFade;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float worldTime;

uniform ivec2 eyeBrightnessSmooth;

uniform vec3 cameraPosition;

uniform mat4 gbufferProjection, gbufferPreviousProjection, gbufferProjectionInverse;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex0;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;

uniform sampler2D noisetex;

#ifdef AO
uniform sampler2D colortex4;
#endif

#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
uniform vec3 previousCameraPosition;

uniform sampler2D colortex5;
uniform sampler2D colortex6;
uniform sampler2D colortex7;
#endif

//Optifine Constants//
#ifdef AO
const bool colortex4MipmapEnabled = true;
#endif

#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
const bool colortex0MipmapEnabled = true;
const bool colortex5MipmapEnabled = true;
const bool colortex6MipmapEnabled = true;
#endif

//Common Variables//
float eBS = eyeBrightnessSmooth.y / 240.0;
float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);
float moonVisibility = clamp((dot(-sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime) * 0.05 * ANIMATION_SPEED;
#else
float frametime = frameTimeCounter * ANIMATION_SPEED;
#endif

vec2 aoOffsets[4] = vec2[4](
	vec2( 1.0,  0.0),
	vec2( 0.0,  1.0),
	vec2(-1.0,  0.0),
	vec2( 0.0, -1.0)
);

vec2 glowOffsets[16] = vec2[16](
    vec2( 0.0, -1.0),
    vec2(-1.0,  0.0),
    vec2( 1.0,  0.0),
    vec2( 0.0,  1.0),
    vec2(-1.0, -2.0),
    vec2( 0.0, -2.0),
    vec2( 1.0, -2.0),
    vec2(-2.0, -1.0),
    vec2( 2.0, -1.0),
    vec2(-2.0,  0.0),
    vec2( 2.0,  0.0),
    vec2(-2.0,  1.0),
    vec2( 2.0,  1.0),
    vec2(-1.0,  2.0),
    vec2( 0.0,  2.0),
    vec2( 1.0,  2.0)
);

vec3 lightVec = sunVec * ((timeAngle < 0.5325 || timeAngle > 0.9675) ? 1.0 : -1.0);

//Common Functions//
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

float InterleavedGradientNoise() {
	float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
	return fract(n + frameCounter / 8.0);
}

#ifdef AO
float GetAmbientOcclusion(float z){
	float ao = 0.0;
	float tw = 0.0;
	float lz = GetLinearDepth(z);
	
	for(int i = 0; i < 4; i++){
		vec2 offset = aoOffsets[i] / vec2(viewWidth, viewHeight);
		float samplez = GetLinearDepth(texture2D(depthtex0, texCoord + offset * 3.0).r);
		float wg = max(1.0 - 2.0 * far * abs(lz - samplez), 0.00001);
		ao += texture2DLod(colortex4, texCoord + offset * 2.0, 1.0).r * wg;
		tw += wg;
	}
	ao /= tw;
	if(tw < 0.0001) ao = texture2DLod(colortex4, texCoord, 2.0).r;
	//if(sin(frameTimeCounter*2.0)+0.5>texCoord.x) ao = 1.0;
	
	//return pow(texture2DLod(colortex4, texCoord, 2.0).r, AO_STRENGTH);
	return pow(ao, AO_STRENGTH);
}
#endif

void GlowOutline(inout vec3 color){
	for(int i = 0; i < 16; i++){
		vec2 glowOffset = glowOffsets[i] / vec2(viewWidth, viewHeight);
		float glowSample = texture2D(colortex3, texCoord.xy + glowOffset).b;
		if(glowSample < 0.5){
			if(i < 4) color.rgb = vec3(0.0);
			else color.rgb = vec3(0.5);
			break;
		}
	}
}

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/blocklightColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/atmospherics/sky.glsl"
#include "/lib/atmospherics/fog.glsl"

#ifdef OUTLINE_ENABLED
#include "/lib/util/outlineOffset.glsl"
#include "/lib/atmospherics/waterFog.glsl"
#include "/lib/post/outline.glsl"
#endif

#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
#include "/lib/util/encode.glsl"
#include "/lib/reflections/raytrace.glsl"
#include "/lib/reflections/complexFresnel.glsl"
#include "/lib/surface/materialDeferred.glsl"
#include "/lib/reflections/roughReflections.glsl"
#endif

//Program//
void main() {
    vec4 color      = texture2D(colortex0, texCoord);
	vec2 lightmap = clamp(lmCoord, vec2(0.0), vec2(1.0));
	float z         = texture2D(depthtex0, texCoord).r;

	float dither = Bayer64(gl_FragCoord.xy);

	#if ALPHA_BLEND == 0
	color.rgb = pow(color.rgb, vec3(2.2));
	#endif
	
	vec4 screenPos = vec4(texCoord, z, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef OUTLINE_ENABLED
	vec4 outerOutline = vec4(0.0), innerOutline = vec4(0.0);
	Outline(color.rgb, false, outerOutline, innerOutline);

	color.rgb = mix(color.rgb, innerOutline.rgb, innerOutline.a);
	#endif

	if (z < 1.0) {
		#if defined ADVANCED_MATERIALS && defined REFLECTION_SPECULAR
		float smoothness = 0.0, skyOcclusion = 0.0;
		vec3 normal = vec3(0.0), fresnel3 = vec3(0.0);

		GetMaterials(smoothness, skyOcclusion, normal, fresnel3, texCoord);

		if (smoothness > 0.0) {
			vec4 reflection = vec4(0.0);
			vec3 skyReflection = vec3(0.0);
			
			float ssrMask = clamp(length(fresnel3) * 400.0 - 1.0, 0.0, 1.0);
			if(ssrMask > 0.0) reflection = RoughReflection(viewPos.xyz, normal, dither, smoothness);
			reflection.a *= ssrMask;

			if (reflection.a < 1.0) {
				#ifdef OVERWORLD
				vec3 skyRefPos = reflect(normalize(viewPos.xyz), normal);
				skyReflection = GetSkyColor(skyRefPos, true);
				
				#ifdef REFLECTION_ROUGH
				float cloudMixRate = smoothness * smoothness * (3.0 - 2.0 * smoothness);
				#else
				float cloudMixRate = 1.0;
				#endif

				#ifdef AURORA
				skyReflection += DrawAurora(skyRefPos * 100.0, dither, 8) * cloudMixRate;
				#endif

				#if NIGHT_SKY_MODE == 1
				skyReflection += DrawRift(skyRefPos * 100.0, dither, 6, 1) * cloudMixRate;
				skyReflection += DrawRift(skyRefPos * 100.0, dither, 6, 0) * cloudMixRate;
				#endif

				float NoU = clamp(dot(normal, upVec), -1.0, 1.0);
				float NoE = clamp(dot(normal, eastVec), -1.0, 1.0);
				float vanillaDiffuse = (0.25 * NoU + 0.75) +
									   (0.5 - abs(NoE)) * (1.0 - abs(NoU)) * 0.1;
				vanillaDiffuse *= vanillaDiffuse;

				skyReflection = mix(
					vanillaDiffuse * minLightCol,
					skyReflection * eBS,
					skyOcclusion
				);
				#endif

				#ifdef NETHER
				skyReflection = netherCol.rgb * 0.04;
				#ifdef NETHER_SMOKE
				skyReflection.rgb += DrawRift(viewPos.xyz, dither, 4, 1);
				skyReflection.rgb += DrawRift(viewPos.xyz, dither, 4, 0);
				#endif
				#endif
				
				#ifdef END
				skyReflection = endCol.rgb * 0.025;

				#if END_SKY == 1
				skyReflection += DrawRift(viewPos.xyz, dither, 4, 1);
				skyReflection += DrawRift(viewPos.xyz, dither, 4, 0);
				#endif

				#endif
			}

			reflection.rgb = max(mix(skyReflection, reflection.rgb, reflection.a), vec3(0.0));
			
			color.rgb += reflection.rgb * fresnel3;
		}
		#endif

		#ifdef AO
		color.rgb *= GetAmbientOcclusion(z);
		#endif

		#if FOG_MODE == 0 || FOG_MODE == 2
		Fog(color.rgb, viewPos.xyz);
		#endif
	} else {
		#ifdef TF
		color.rgb = GetSkyColor(viewPos.xyz, false);
		#endif

		#ifdef NETHER
		color.rgb = netherCol.rgb * 0.04;
		#ifdef NETHER_SMOKE
		color.rgb += DrawRift(viewPos.xyz, dither, 4, 1);
		color.rgb += DrawRift(viewPos.xyz, dither, 4, 0);
		#endif
		#endif

		#if defined END && FOG_MODE == 0
		float VoL = dot(normalize(viewPos.xyz), lightVec);
		VoL = pow(VoL * 0.5 + 0.5, 16.0) * 0.75 + 0.25;
		color.rgb += endCol.rgb * 0.04 * VoL;
		#endif

		if (isEyeInWater == 2) {
			#ifdef EMISSIVE_RECOLOR
			color.rgb = pow(blocklightCol / BLOCKLIGHT_I, vec3(4.0)) * 2.0;
			#else
			color.rgb = vec3(1.0, 0.3, 0.01);
			#endif
		}

		if (blindFactor > 0.0) color.rgb *= 1.0 - blindFactor;
	}

	#ifdef OUTLINE_ENABLED
	color.rgb = mix(color.rgb, outerOutline.rgb, outerOutline.a);
	#endif

	#if MC_VERSION >= 10900
	float isGlowing = texture2D(colortex3, texCoord).b;
	if (isGlowing > 0.5) GlowOutline(color.rgb);
	#endif

	vec3 reflectionColor = pow(color.rgb, vec3(0.125)) * 0.5;

	#if ALPHA_BLEND == 0
	color.rgb = pow(color.rgb, vec3(1.0 / 2.2));
	#endif
    
    /* DRAWBUFFERS:0 */
    gl_FragData[0] = color;
	#ifndef REFLECTION_PREVIOUS
	/*DRAWBUFFERS:05*/
	gl_FragData[1] = vec4(reflectionColor, float(z < 1.0));
	#endif
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord, lmCoord;

varying vec3 sunVec, upVec, eastVec;

//Uniforms//
uniform float timeAngle;

uniform mat4 gbufferModelView;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;

	lmCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	lmCoord = clamp((lmCoord - 0.03125) * 1.06667, vec2(0.0), vec2(0.9333, 1.0));
	
	gl_Position = ftransform();

	const vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);

	upVec = normalize(gbufferModelView[1].xyz);
	eastVec = normalize(gbufferModelView[0].xyz);
}

#endif
