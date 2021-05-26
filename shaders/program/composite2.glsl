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

//Uniforms//
uniform float frameTimeCounter;
uniform float timeAngle, timeBrightness;
uniform float viewWidth, viewHeight, aspectRatio;
uniform float far, near;
uniform float rainStrength;
uniform float isEyeInWater;

varying vec3 sunVec, upVec;
uniform vec3 cameraPosition, previousCameraPosition;

uniform mat4 gbufferPreviousProjection, gbufferProjectionInverse, gbufferProjection;
uniform mat4 gbufferModelView, gbufferPreviousModelView, gbufferModelViewInverse;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex2;
uniform sampler2D colortex3;
uniform sampler2D depthtex0;
uniform sampler2D depthtex1;
uniform sampler2D noisetex;

float moonVisibility = clamp(dot(-sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;
float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

#ifdef WORLD_TIME_ANIMATION
float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
#else
float frametime = frameTimeCounter*ANIMATION_SPEED;
#endif

//Optifine Constants//
const bool colortex0MipmapEnabled = false;
const bool colortex1MipmapEnabled = true;

//Common Functions//
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


//Includes//
#include "/lib/util/dither.glsl"
#include "/lib/color/dimensionColor.glsl"

#ifdef OUTLINE_OUTER
#include "/lib/util/outlineOffset.glsl"
#include "/lib/util/outlineDepth.glsl"
#endif

//Program//
void main() {
    vec3 color = texture2DLod(colortex0, texCoord.xy, 0.0).rgb;
	float dither = Bayer64(gl_FragCoord.xy);

	#ifdef MOTION_BLUR
	float z = texture2D(depthtex1, texCoord.st).x;

	#ifdef OUTLINE_OUTER
	DepthOutline(z);
	#endif

	color = MotionBlur(color, z, dither);
	#endif

	/*DRAWBUFFERS:07*/
	gl_FragData[0] = vec4(color,1.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec4 texCoord;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0;
	
	gl_Position = ftransform();
}

#endif