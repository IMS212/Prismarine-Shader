float GetLogarithmicDepth2(float dist) {
	return (far * (dist - near)) / (dist * (far - near));
}

float GetLinearDepth3(float depth) {
    return 2.0 * near * far / (far + near - (2.0 * depth - 1.0) * (far - near));
}

vec3 getFireflies(float pixeldepth0, float pixeldepth1, vec3 color, float dither){
    vec3 ff = vec3(0.0);

    float visibility = (1 - sunVisibility) * (1 - rainStrength);

    if (visibility > 0){
        vec4 wpos = vec4(0);

		float maxDist = 512;
		float depth0 = GetLinearDepth3(pixeldepth0);
		float depth1 = GetLinearDepth3(pixeldepth1);

        for (int i; i < 4; i++){
            float minDist = (i + dither) * 8;

			if (minDist >= maxDist) break;
			if (depth1 < minDist || (depth0 < minDist && color == vec3(0.0))) break;
			if (rainStrength == 1) break;

            wpos = GetWorldSpace(GetLogarithmicDepth2(minDist), texCoord.xy);

            if (length(wpos.xz) < maxDist && depth0 > minDist){
                vec3 col = vec3(0);

                if (depth0 < minDist) col = color;

                vec3 npos = wpos.xyz + cameraPosition.xyz + vec3(frametime * 2.0, 0, 0);
				float n3da = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 3.0) * 0.35).r;
				float n3db = texture2D(noisetex, npos.xz / 512.0 + floor(npos.y / 3.0 + 1.0) * 0.35).r;
				float noise = mix(n3da, n3db, fract(npos.y / 3.0));
				noise = sin(noise * 16.0 + frametime) * 0.25 + 0.5;

                col *= noise;

                ff += col;
            }
        }
        ff = sqrt(ff * visibility);
    }
    return ff;
}