
	
/* 
BSL Shaders v7.2.01 by Capt Tatsu 
https://bitslablab.com 
*/ 

//Settings//
#include "/lib/settings.glsl"

#ifdef FSH
varying vec3 wpos;
uniform sampler2D noisetex;
uniform float rainStrength;
varying vec3 sunVec, upVec, eastVec;
uniform float timeAngle, timeBrightness;
varying vec4 texcoord;
uniform vec3 cameraPosition;
uniform float isEyeInWater;
uniform sampler2D tex;
uniform sampler2D gaux1;
varying float mat;
uniform int worldTime;
uniform float frameTimeCounter;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelView;
uniform float viewWidth, viewHeight;

float sunVisibility  = clamp((dot( sunVec, upVec) + 0.05) * 10.0, 0.0, 1.0);

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif

#include "/lib/color/waterColor.glsl"
#include "/lib/lighting/caustics.glsl"

#ifdef TAA
#include "/lib/util/jitter.glsl"
#include "/lib/util/spaceConversion.glsl"
#endif

void main() {
	vec3 shadow = vec3(0.0);
	float water       = float(mat > 0.98 && mat < 1.02);
	vec4 albedo = texture2D(tex,texcoord.xy);
	vec3 screenPos = vec3(gl_FragCoord.xy / vec2(viewWidth, viewHeight), gl_FragCoord.z);
	#ifdef TAA
	vec3 viewPos = ToNDC(vec3(TAAJitter(screenPos.xy, -0.5), screenPos.z));
	#else
	vec3 viewPos = ToNDC(screenPos);
	#endif
	vec3 worldPos = ToWorld(viewPos);

	#ifdef SHADOW_COLOR
	//albedo.a = fract(wpos.x*0.5-0.5);
	albedo.rgb = mix(vec3(1),albedo.rgb,pow(albedo.a,(0.0-albedo.a)*0.5)*1.05);
	albedo.rgb *= 1.0-pow(albedo.a, 16.0);
	//if ((checkalpha > 0.9 && albedo.a > 0.98) || checkalpha < 0.9) albedo.rgb *= 0.0;
	#endif
	
	#ifdef SHADOW_COLOR
	if (water > 0.9 && isEyeInWater == 0){
		//vec3 causticpos = cameraPosition.xyz;
		albedo.rgb = vec3(waterColor.r, waterColor.g * 0.7, waterColor.b) * 16 * WATER_I;
		//albedo.rgb *= getCausticWaves(causticpos) * 0.1;
		}
	#endif
	
	gl_FragData[0] = vec4(albedo.rgb, albedo.a);
	
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

const float PI = 3.1415927;

varying vec4 texcoord;

attribute vec4 mc_midTexCoord;
attribute vec4 mc_Entity;
varying float mat;
uniform mat4 shadowProjectionInverse;
uniform mat4 shadowProjection;
uniform mat4 shadowModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform int worldTime;
uniform float frameTimeCounter;
uniform vec3 cameraPosition;

#ifdef SHADOW_COLOR
varying vec3 wpos;
varying float water;
#endif

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif

float pi2wt = PI*2*(frametime*24);

vec3 calcWave(in vec3 pos, in float fm, in float mm, in float ma, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5) {
    vec3 ret;
    float magnitude,d0,d1,d2,d3;
    magnitude = sin(pi2wt*fm + pos.x*0.5 + pos.z*0.5 + pos.y*0.5) * mm + ma;
    d0 = sin(pi2wt*f0);
    d1 = sin(pi2wt*f1);
    d2 = sin(pi2wt*f2);
    ret.x = sin(pi2wt*f3 + d0 + d1 - pos.x + pos.z + pos.y) * magnitude;
    ret.z = sin(pi2wt*f4 + d1 + d2 + pos.x - pos.z + pos.y) * magnitude;
	ret.y = sin(pi2wt*f5 + d2 + d0 + pos.z + pos.y - pos.y) * magnitude;
    return ret;
}

vec3 calcMove(in vec3 pos, in float f0, in float f1, in float f2, in float f3, in float f4, in float f5, in vec3 amp1, in vec3 amp2) {
    vec3 move1 = calcWave(pos      , 0.0027, 0.0400, 0.0400, 0.0127, 0.0089, 0.0114, 0.0063, 0.0224, 0.0015) * amp1;
	vec3 move2 = calcWave(pos+move1, 0.0348, 0.0400, 0.0400, f0, f1, f2, f3, f4, f5) * amp2;
    return move1+move2;
}

vec3 calcWaterMove(in vec3 pos)
{
	float fy = fract(pos.y + 0.001);
	if (fy > 0.002)
	{
		float wave = 0.05 * sin(2*PI/4*frametime + 2*PI*2/16*pos.x + 2*PI*5/16*pos.z)
				   + 0.05 * sin(2*PI/3*frametime - 2*PI*3/16*pos.x + 2*PI*4/16*pos.z);
		return vec3(0, clamp(wave, -fy, 1.0-fy), 0);
	}
	else
	{
		return vec3(0);
	}
}

void main() {
	
	gl_Position = ftransform();
	float istopv = 0.0;
	if (gl_MultiTexCoord0.t < mc_midTexCoord.t) istopv = 1.0;
	vec4 position = gl_Position;
	position = shadowProjectionInverse * position;
	position = shadowModelViewInverse * position;
	
	#ifdef SHADOW_COLOR
	wpos = position.xyz*1.1+cameraPosition.xyz;
	#endif
	
	position.xyz += cameraPosition.xyz;
	
	if (istopv > 0.9) {
	#ifdef WAVING_PLANT
	if ( mc_Entity.x == 31.0 )
			position.xyz += calcMove(position.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0063, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	
	#ifdef WAVING_PLANT
	if (mc_Entity.x == 37.0 || mc_Entity.x == 38.0 )
			position.xyz += calcMove(position.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WAVING_PLANT
	if ( mc_Entity.x == 59.0 || mc_Entity.x == 141 || mc_Entity.x == 142 || mc_Entity.x == 207 )
			position.xyz += calcMove(position.xyz, 0.0041, 0.0070, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.0,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WAVING_EXTRA
	if ( mc_Entity.x == 51.0 )
			position.xyz += calcMove(position.xyz, 0.0105, 0.0096, 0.0087, 0.0063, 0.0097, 0.0156, vec3(1.2,0.4,1.2), vec3(0.8,0.8,0.8));
	#endif
	}
	
	#ifdef WAVING_PLANT
	if (mc_Entity.x == 175.0 )
			position.xyz += calcMove(position.xyz, 0.0041, 0.005, 0.0044, 0.0038, 0.0240, 0.0000, vec3(0.8,0.1,0.8), vec3(0.4,0.0,0.4));
	#endif
	#ifdef WAVING_LEAF
	if ( mc_Entity.x == 18.0 || mc_Entity.x == 161.0 )
			position.xyz += calcMove(position.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.5,0.5,0.5), vec3(0.25,0.25,0.25));
	#endif
	#ifdef WAVING_PLANT
	if ( mc_Entity.x == 106.0 )
			position.xyz += calcMove(position.xyz, 0.0040, 0.0064, 0.0043, 0.0035, 0.0037, 0.0041, vec3(0.05,0.4,0.05), vec3(0.05,0.3,0.05));
	#endif
	#ifdef WAVING_LIQUID
	if ( mc_Entity.x == 10.0 || mc_Entity.x == 11.0 )
			position.xyz += calcWaterMove(position.xyz) * 0.25;
	#endif
	#ifdef WAVING_PLANT
	if ( mc_Entity.x == 111.0 )
			position.xyz += calcWaterMove(position.xyz);
	#endif
	
	position.xyz -= cameraPosition.xyz;
	
	#ifdef WORLD_CURVATURE
	position.y -= (length(position.xz)*length(position.xz))/WORLD_CURVATURE_SIZE;
	#endif
	
	mat = 0.0;
	
	if (mc_Entity.x == 10300 || mc_Entity.x == 10302) mat = 1.0;
	if (mc_Entity.x == 10301 || mc_Entity.x == 10303) mat = 2.0;
	
	position = shadowModelView * position;
	position = shadowProjection * position;
	gl_Position = position;

	float dist = sqrt(gl_Position.x * gl_Position.x + gl_Position.y * gl_Position.y);
	float distortFactor = (1.0f - shadowMapBias) + dist * shadowMapBias;
	
	gl_Position.xy *= (1.0f / distortFactor);
	gl_Position.z = gl_Position.z*0.2;
	
	texcoord = gl_MultiTexCoord0;

	gl_FrontColor = gl_Color;
}


#endif