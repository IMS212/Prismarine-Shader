vec4 ReadNormal(vec2 coord) {
    coord = fract(coord) * vTexCoordAM.pq + vTexCoordAM.st;
	return texture2DGradARB(normals, coord, dcdx, dcdy);
}

vec2 GetParallaxCoord(float parallaxFade) {
    vec2 coord = vTexCoord.st;

    float sampleStep = 1.0 / PARALLAX_QUALITY;
    float currentStep = 1.0;

    vec2 scaledDir = viewVector.xy * PARALLAX_DEPTH / -viewVector.z;
    vec2 stepDir = scaledDir * sampleStep * (1.0 - parallaxFade);

    vec3 normalMap = ReadNormal(coord).xyz * 2.0 - 1.0;
    float normalCheck = normalMap.x + normalMap.y;
    if (parallaxFade >= 1.0 || normalCheck < -1.999) return texCoord;

    float depth = ReadNormal(coord).a;

    for(int i = 0; i < PARALLAX_QUALITY; i++){
        if (currentStep <= depth) break;
        coord += stepDir;
        depth = ReadNormal(coord).a;
        currentStep -= sampleStep;
    }

    coord = fract(coord.st) * vTexCoordAM.pq + vTexCoordAM.st;

    return coord;
}

float GetParallaxShadow(float parallaxFade, vec2 coord, vec3 lightVec, mat3 tbn) {
    float parallaxshadow = 1.0;

    if(parallaxFade >= 1.0) return 1.0;

    float height = texture2DGradARB(normals, coord, dcdx, dcdy).a;

    if(height > 1.0 - 0.5 / PARALLAX_QUALITY) return 1.0;

    vec3 parallaxdir = tbn * lightVec;
    parallaxdir.xy *= PARALLAX_DEPTH * SELF_SHADOW_ANGLE;
    vec2 newvTexCoord = (coord - vTexCoordAM.st) / vTexCoordAM.pq;
    float step = 0.04;
    
    for(int i = 0; i < 8; i++) {
        float currentHeight = height + parallaxdir.z * step * i;
        vec2 parallaxCoord = fract(newvTexCoord + parallaxdir.xy * i * step) * 
                                vTexCoordAM.pq + vTexCoordAM.st;
        float offsetHeight = texture2DGradARB(normals, parallaxCoord, dcdx, dcdy).a;
        float sampleShadow = clamp(1.0 - (offsetHeight - currentHeight) * 16.0, 0.0, 1.0);
        parallaxshadow = min(parallaxshadow, sampleShadow);
        if (parallaxshadow < 0.01) break;
    }
    parallaxshadow *= parallaxshadow;
    
    parallaxshadow = mix(parallaxshadow, 1.0, parallaxFade);

    return parallaxshadow;
}