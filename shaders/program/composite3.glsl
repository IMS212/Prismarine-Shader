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

//Uniforms//
uniform float viewWidth, viewHeight, aspectRatio;
uniform float centerDepthSmooth;

uniform mat4 gbufferProjection, gbufferProjectionInverse, gbufferModelViewInverse, shadowModelView, shadowProjection;

uniform sampler2D colortex0;
uniform sampler2D depthtex1, depthtex0;

//Optifine Constants//
const bool colortex0MipmapEnabled = true;
const float aberrationStrength = float(CHROMATIC_ABERRATION_STRENGTH) / 512;

//Common Variables//
vec2 dofOffsets[60] = vec2[60](
	vec2( 0.0    ,  0.25  ),
	vec2(-0.2165 ,  0.125 ),
	vec2(-0.2165 , -0.125 ),
	vec2( 0      , -0.25  ),
	vec2( 0.2165 , -0.125 ),
	vec2( 0.2165 ,  0.125 ),
	vec2( 0      ,  0.5   ),
	vec2(-0.25   ,  0.433 ),
	vec2(-0.433  ,  0.25  ),
	vec2(-0.5    ,  0     ),
	vec2(-0.433  , -0.25  ),
	vec2(-0.25   , -0.433 ),
	vec2( 0      , -0.5   ),
	vec2( 0.25   , -0.433 ),
	vec2( 0.433  , -0.2   ),
	vec2( 0.5    ,  0     ),
	vec2( 0.433  ,  0.25  ),
	vec2( 0.25   ,  0.433 ),
	vec2( 0      ,  0.75  ),
	vec2(-0.2565 ,  0.7048),
	vec2(-0.4821 ,  0.5745),
	vec2(-0.51295,  0.375 ),
	vec2(-0.7386 ,  0.1302),
	vec2(-0.7386 , -0.1302),
	vec2(-0.51295, -0.375 ),
	vec2(-0.4821 , -0.5745),
	vec2(-0.2565 , -0.7048),
	vec2(-0      , -0.75  ),
	vec2( 0.2565 , -0.7048),
	vec2( 0.4821 , -0.5745),
	vec2( 0.51295, -0.375 ),
	vec2( 0.7386 , -0.1302),
	vec2( 0.7386 ,  0.1302),
	vec2( 0.51295,  0.375 ),
	vec2( 0.4821 ,  0.5745),
	vec2( 0.2565 ,  0.7048),
	vec2( 0      ,  1     ),
	vec2(-0.2588 ,  0.9659),
	vec2(-0.5    ,  0.866 ),
	vec2(-0.7071 ,  0.7071),
	vec2(-0.866  ,  0.5   ),
	vec2(-0.9659 ,  0.2588),
	vec2(-1      ,  0     ),
	vec2(-0.9659 , -0.2588),
	vec2(-0.866  , -0.5   ),
	vec2(-0.7071 , -0.7071),
	vec2(-0.5    , -0.866 ),
	vec2(-0.2588 , -0.9659),
	vec2(-0      , -1     ),
	vec2( 0.2588 , -0.9659),
	vec2( 0.5    , -0.866 ),
	vec2( 0.7071 , -0.7071),
	vec2( 0.866  , -0.5   ),
	vec2( 0.9659 , -0.2588),
	vec2( 1      ,  0     ),
	vec2( 0.9659 ,  0.2588),
	vec2( 0.866  ,  0.5   ),
	vec2( 0.7071 ,  0.7071),
	vec2( 0.5    ,  0.8660),
	vec2( 0.2588 ,  0.9659)
);

//Common Functions//
#ifdef CHROMATIC_ABERRATION
vec2 scaleCoord(vec2 coord, float scale) {
    coord = (coord * scale) - (0.5 * (scale - 1));
    return clamp(coord, 0, 0.999999);
}

vec3 getChromaticAbberation(vec2 coord, float amount, float lod) {
    vec3 col = vec3(0.0);

    amount = distance(coord, vec2(0.5)) * amount;
    #if CA_COLOR == 0
    col.r     = texture2DLod(colortex0, scaleCoord(coord, 1.0 - amount), lod).r;
    col.g     = texture2DLod(colortex0, coord, lod).g;
    col.b     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).b;
    #elif CA_COLOR == 1
    col.r     = texture2DLod(colortex0, coord, lod).r;
    col.g     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).g;
    col.b     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).b;
    #elif CA_COLOR == 2
    col.r     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).r;
    col.g     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).g;
    col.b     = texture2DLod(colortex0, coord, lod).b;
    #elif CA_COLOR == 3
    col.r     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).r;
    col.g     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).g;
    col.b     = texture2DLod(colortex0, scaleCoord(coord, 1.0 + amount), lod).b;
    #endif

    return col;
}
#endif

#include "/lib/util/spaceConversion.glsl"

vec3 DepthOfField(vec3 color, float z, vec4 viewPos) {
	vec3 dof = vec3(0.0);
	float hand = float(z < 0.56);
	
	float fovScale = gbufferProjection[1][1] / 1.37;
	float coc = max(abs(z - centerDepthSmooth) * DOF_STRENGTH - 0.01, 0.0);
	coc = coc / sqrt(coc * coc + 0.1);
	
	#ifdef DISTANT_BLUR
	vec3 worldPos = ToWorld(viewPos.xyz);
	coc = min(length(worldPos) * DISTANT_BLUR_RANGE * 0.00025, DISTANT_BLUR_STRENGTH * 0.025) * DISTANT_BLUR_STRENGTH;
	#endif

	if (coc > 0.0 && hand < 0.5) {
		for(int i = 0; i < 60; i++) {
			vec2 offset = dofOffsets[i] * coc * 0.015 * fovScale * vec2(1.0 / aspectRatio, 1.0);
			float lod = log2(viewHeight * aspectRatio * coc * fovScale / 320.0);
			#ifndef CHROMATIC_ABERRATION
			dof += texture2DLod(colortex0, texCoord + offset, lod).rgb;
			#else
			dof += getChromaticAbberation(texCoord + offset, aberrationStrength, lod).rgb;
			#endif
		}
		dof /= 60.0;
	}
	else dof = color;
	return dof;
}

//Includes//
#ifdef OUTLINE_OUTER
#include "/lib/util/outlineOffset.glsl"
#include "/lib/util/outlineDepth.glsl"
#endif

//Program//
void main() {
	vec3 color = texture2DLod(colortex0, texCoord, 0.0).rgb;
	
	#if defined DOF || defined DISTANT_BLUR
	float z = texture2D(depthtex1, texCoord.st).x;
	float z0 = texture2D(depthtex0, texCoord.xy).r;

	vec4 screenPos = vec4(texCoord.x, texCoord.y, z0, 1.0);
	vec4 viewPos = gbufferProjectionInverse * (screenPos * 2.0 - 1.0);
	viewPos /= viewPos.w;

	#ifdef OUTLINE_OUTER
	DepthOutline(z);
	#endif

	color = DepthOfField(color, z, viewPos);
	#endif

	#ifdef DOF
	#endif //:crong:
	
    /*DRAWBUFFERS:0*/
	gl_FragData[0] = vec4(color,1.0);
}

#endif

//Vertex Shader/////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

//Varyings//
varying vec2 texCoord;

//Program//
void main() {
	texCoord = gl_MultiTexCoord0.xy;
	
	gl_Position = ftransform();
}

#endif