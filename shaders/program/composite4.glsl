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

uniform sampler2D colortex0;

//Optifine Constants//
const bool colortex0MipmapEnabled = true;

//Common Variables//
float pw = 1.0/ viewWidth;
float ph = 1.0/ viewHeight;
float pi = 3.1415927;

vec3 makeBloom(float lod, vec2 offset){ //Literally bloom from 7.0. Newer versions are a downgrade :<
	vec3 bloom = vec3(0.0);
	vec3 temp = vec3(0.0);
	float scale = pow(2.0, lod);
	vec2 coord = (texCoord.xy - offset) * scale;
	float padding = 0.005 * scale;

	if (coord.x > -padding && coord.y > -padding && coord.x < 1.0 + padding && coord.y < 1.0 + padding){
	for (int i = 0; i < 7; i++) {
		for (int j = 0; j < 7; j++) {
		float wg = pow((1.0 - length(vec2(i - 3, j - 3)) / 4.0), 2.0) * 14.14;
		vec2 bcoord = (texCoord.xy - offset + vec2(i - 3, j - 3) * pw * vec2(1.0, aspectRatio)) * scale;
		if (wg > 0){
			temp = texture2D(colortex0, bcoord).rgb * wg;
			bloom += temp;
			}
		}
	}
	bloom /= 49;
	}

	return bloom;
}
//Program//
void main() {
	vec3 blur = vec3(0);

	#ifdef BLOOM
	blur += makeBloom(2,vec2(0,0));
	blur += makeBloom(3,vec2(0.3,0));
	blur += makeBloom(4,vec2(0,0.3));
	blur += makeBloom(5,vec2(0.1,0.3));
	blur += makeBloom(6,vec2(0.2,0.3));
	blur += makeBloom(7,vec2(0.3,0.3));
	#endif

	blur = clamp(pow(blur,vec3(1.0/2.2)),0.0,1.0);

    /* DRAWBUFFERS:1 */
	gl_FragData[0] = vec4(blur, 1.0);
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