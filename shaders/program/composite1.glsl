#ifdef FSH
	const bool colortex0MipmapEnabled = false;
	const bool colortex1MipmapEnabled = true;

	varying vec3 lightVector;
	varying vec3 upVec;
	varying vec3 sunVec;
	varying vec3 moonVec;
	varying float moonVisibility;
	uniform float shadowFade;
	varying vec4 texcoord;
	varying vec2 texCoord;
	uniform float blindFactor;
	uniform sampler2D colortex0;
	uniform sampler2D colortex1;
	uniform sampler2D colortex2;
	uniform sampler2D colortex3;
	uniform sampler2D colortex4;
	uniform sampler2D colortex5;
	uniform sampler2D depthtex0;
	uniform sampler2D depthtex1;
	uniform sampler2D noisetex;

	uniform mat4 gbufferProjection;
	uniform mat4 gbufferProjectionInverse;
	uniform mat4 gbufferModelViewInverse;
	uniform mat4 gbufferModelView;
	uniform float rainStrength;
	uniform float wetness;
	uniform ivec2 eyeBrightnessSmooth;
	uniform int isEyeInWater;
	uniform float nightVision;
	uniform int worldTime;
	uniform float frameTimeCounter;
	uniform vec3 cameraPosition;
	uniform vec3 sunPosition;
	uniform float viewWidth;
	uniform float viewHeight;
	uniform float far;
	uniform float near;
	uniform float aspectRatio;
	uniform float timeAngle, timeBrightness;

	float eBS = eyeBrightnessSmooth.y / 240.0;
	float sunVisibility = clamp(dot(sunVec, upVec) + 0.05, 0.0, 0.1) * 10.0;

	#ifdef WORLD_TIME_ANIMATION
	float frametime = float(worldTime)/20.0*ANIMATION_SPEED;
	#else
	float frametime = frameTimeCounter*ANIMATION_SPEED;
	#endif

	#include "/lib/util/dither.glsl"
	#include "/lib/util/fragPos.glsl"
	#include "/lib/color/dimensionColor.glsl"
	#include "/lib/atmospherics/volumetricClouds.glsl"

	void main() {
		vec3 aux2 = texture2D(colortex4, texcoord.st).rgb;
		vec3 aux = texture2D(colortex5, texcoord.st).rgb;
		vec4 color = texture2D(colortex0, texcoord.st);
		float alpha = pow(texture2D(colortex1, texcoord.xy).a, 2.2);
		vec3 vl = texture2DLod(colortex1, texCoord.xy, 1.5).rgb;
		vl *= vl;

		#ifdef OVERWORLD
		#ifdef LIGHTSHAFT_AUTOCOLOR
		vl *= lightCol * 0.25;
		#else
		vl *= vec3(LIGHTSHAFT_R, LIGHTSHAFT_G, LIGHTSHAFT_B) * LIGHTSHAFT_I / 255.0 * 0.25;
		#endif
		#endif

		#ifdef END
		vl *= endCol.rgb * 0.025;
		#endif

		vl *= (LIGHT_SHAFT_STRENGTH + isEyeInWater) * (1.0 - rainStrength * eBS * 0.875) * shadowFade *
			(1.0 - blindFactor);

		if (cameraPosition.y < 1.0) vl *= exp(2.0 * cameraPosition.y - 2.0);
		
		color.rgb += vl;

		float pixeldepth0 = texture2D(depthtex0, texcoord.xy).x;
		float pixeldepth1 = texture2D(depthtex1, texcoord.xy).x;

		#if defined OVERWORLD && CLOUDS == 3 && defined LIGHT_SHAFT
		vec2 vc = getVolumetricCloud(pixeldepth1, pixeldepth0);
		//tatsu pls help
		//if (alpha > 0.0001){
			//float opacity = VCLOUDS_OPACITY + (cameraPosition.y * 0.005);
			//float vcmult = opacity * (1.0 - moonVisibility * 0.7) * (1.0 - rainStrength * 0.5);
			//color.rgb += mix(color.rgb, mix(ambientCol * (1.0 - mix(0.25, 0.825, moonVisibility) * rainStrength), lightCol * (1.0 + mix(1.0, -0.75, moonVisibility) * rainStrength), texture2DLod(colortex4, texcoord.xy, float(2.0)).a) * vcmult, texture2DLod(colortex5,texcoord.xy,float(2.0)).a * texture2DLod(colortex5,texcoord.xy,float(2.0)).a);
		//}
		#endif

		#if defined END && defined LIGHT_SHAFT
		#ifdef END_VOLUMETRIC_FOG
		vec2 vc = getVolumetricFog(pixeldepth0, pixeldepth1);
		#endif
		#endif

	/*DRAWBUFFERS:0145*/
		gl_FragData[0] = color;
		#if (defined END_VOLUMETRIC_FOG && defined END) || (CLOUDS == 3 && defined OVERWORLD)
		gl_FragData[2] = vec4(aux2, vc.x);
		gl_FragData[3] = vec4(aux, vc.y);
		#endif
	}
#endif