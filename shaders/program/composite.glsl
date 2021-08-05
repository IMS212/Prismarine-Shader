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

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;

#if FOG_MODE == 1 || FOG_MODE == 2
uniform sampler2DShadow shadowtex0;
uniform sampler2DShadow shadowtex1;
uniform sampler2D shadowcolor0;
uniform sampler2D noisetex;
#endif

//Attributes//

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
float GetLuminance(vec3 color) {
	return dot(color,vec3(0.299, 0.587, 0.114));
}

float GetLinearDepth(float depth) {
   return (2.0 * near) / (far + near - depth * (far - near));
}

//Includes//
#include "/lib/color/dimensionColor.glsl"
#include "/lib/color/skyColor.glsl"
#include "/lib/color/waterColor.glsl"
#include "/lib/util/dither.glsl"
#include "/lib/util/spaceConversion.glsl"
#include "/lib/atmospherics/waterFog.glsl"

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
	float isWater = 0.0;

	if (translucent.b > 0.999 && z1 > z0) {
		isWater = 1.0;
		translucent = vec3(1.0);
	}
	
	vec4 screenPos = vec4(texCoord.x, texCoord.y, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef OVERWORLD
		if (isWater > 0.5) {
			vec3 worldPos = ToWorld(viewPos.xyz);
			vec3 refractPos = worldPos.xyz + cameraPosition.xyz;
			refractPos *= 0.005;
			float refractSpeed = 0.0035 * WATER_SPEED;
			vec2 refractPos2 = refractPos.xz + refractPos.y * 0.5 + refractSpeed * frametime;

			vec2 refractNoise = texture2D(noisetex, refractPos2).rg - vec2(0.5);

			float hand = 1.0 - float(z0 < 0.56);
			float d0 = GetLinearDepth(z0);
			//float d1 = GetLinearDepth(z1);
			float distScale0 = max((far - near) * d0 + near, 6.0);
			float fovScale = gbufferProjection[1][1] / 1.37;
			float refractScale = fovScale / distScale0;
			vec2 refractMult = vec2(0.07 * refractScale);
			refractMult *= hand * 2;
			refractNoise *= refractMult;
			
			vec2 refractCoord = texCoord.xy + refractNoise;

			float waterCheck = float(texture2D(colortex1, refractCoord).b > 0.999);
			float depthCheck0 = texture2D(depthtex0, refractCoord).r;
			float depthCheck1 = texture2D(depthtex1, refractCoord).r;
			float depthDif = GetLinearDepth(depthCheck1) - GetLinearDepth(depthCheck0);
			refractNoise *= clamp(depthDif * 150.0, 0.0, 1.0);
			refractCoord = texCoord.xy + refractNoise;
			if (depthCheck0 >= 0.56) {
				if (waterCheck > 0.95) {
					color.rgb = texture2D(colortex0, refractCoord).rgb;
					if (isEyeInWater == 1) {
						translucent = texture2D(colortex1, refractCoord).rgb;
						if (translucent.b > 0.999) translucent = vec3(1.0);
						z0 = texture2D(depthtex0, refractCoord).r;
						z1 = texture2D(depthtex1, refractCoord).r;
					}
				}
			}
		}
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
	float dither = Bayer256(gl_FragCoord.xy);
	vec3 vl = GetLightShafts(z0, z1, translucent, dither);
	#else
	vec3 vl = vec3(0.0);
    #endif
	
    /*DRAWBUFFERS:01*/
	gl_FragData[0] = color;
	gl_FragData[1] = vec4(vl, 1.0);
	
    #ifdef REFLECTION_PREVIOUS
    /*DRAWBUFFERS:015*/
	gl_FragData[2] = vec4(pow(color.rgb, vec3(0.125)) * 0.5, float(z0 < 1.0));
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
