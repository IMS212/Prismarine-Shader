#version 120
#include "/lib/settings.glsl"
varying vec4 texcoord;
varying vec2 texCoord;
varying vec3 lightVector;
varying vec3 upVec;
varying vec3 sunVec;
varying vec3 moonVec;
varying float sunVisibility;
varying float moonVisibility;
varying float handRecolor;
uniform float timeAngle;

uniform mat4 gbufferModelView;
uniform int worldTime;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 upPosition;
uniform int heldItemId;

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
	vec2 sunRotationData = vec2(cos(sunPathRotation * 0.01745329251994), -sin(sunPathRotation * 0.01745329251994));
	float ang = fract(timeAngle - 0.25);
	ang = (ang + (cos(ang * 3.14159265358979) * -0.5 + 0.5 - ang) / 3.0) * 6.28318530717959;
	sunVec = normalize((gbufferModelView * vec4(vec3(-sin(ang), cos(ang) * sunRotationData) * 2000.0, 1.0)).xyz);
	moonVec = normalize(-sunPosition);
	upVec = normalize(gbufferModelView[1].xyz);
	
	float SdotU = dot(sunVec,upVec);
	float MdotU = dot(moonVec,upVec);
	sunVisibility = pow(clamp(SdotU+0.1,0.0,0.1)/0.1,2.0);
	moonVisibility = pow(clamp(MdotU+0.1,0.0,0.1)/0.1,2.0);
	
	handRecolor = 0.0;
	if (heldItemId == 89 || heldItemId == 138 || heldItemId == 169) handRecolor = 1.0;
}
