vec4 getFragPos(vec2 coord, float depth) {
	vec4 fragpos = gbufferProjectionInverse * vec4(vec3(coord.s, coord.t, depth) * 2.0 - 1.0, 1.0);
	fragpos /= fragpos.w;

	if (isEyeInWater > 0.9){
		float fov = atan(1./gbufferProjection[1][1]);
		float fovUnderWater = fov*0.85;
		fragpos.xy *= gbufferProjection[1][1]*tan(fovUnderWater);
	}

	return fragpos;
}

vec4 getWorldPos(vec4 fragpos) {
	vec4 worldpos = gbufferModelViewInverse * fragpos;

	return worldpos;
}