#version 120
#define NETHER
varying vec4 texcoord;
varying vec2 texCoord;

varying vec3 lightVector;
varying vec3 upVec;
varying vec3 sunVec;
uniform float timeAngle;

varying vec3 moonVec;
varying float sunVisibility;
varying float moonVisibility;

uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;

void main() {
	gl_Position = ftransform();
	texcoord = gl_MultiTexCoord0;
	texCoord = gl_MultiTexCoord0.xy;
	if (worldTime < 12700 || worldTime > 23250) {
		lightVector = normalize(sunPosition);
	}
	else {
		lightVector = normalize(-sunPosition);
	}
	sunVec = normalize(sunPosition);
	moonVec = normalize(-sunPosition);
	upVec = normalize(upPosition);
	
	float SdotU = dot(sunVec,upVec);
	float MdotU = dot(moonVec,upVec);
	sunVisibility = pow(clamp(SdotU+0.1,0.0,0.1)/0.1,2.0);
	moonVisibility = pow(clamp(MdotU+0.1,0.0,0.1)/0.1,2.0);
}
