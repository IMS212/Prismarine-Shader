#if (WATER_MODE == 1 || WATER_MODE == 3) && !defined SKY_VANILLA && !defined NETHER
uniform vec3 fogColor;
#endif

void WaterFog(inout vec3 color, vec3 viewPos) {
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-3.0 * fog);
    
    #if WATER_MODE == 0 || WATER_MODE == 2
    vec3 waterFogColor = vec3(waterColor.r, waterColor.g * 0.8, waterColor.b) * waterAlpha;
    #elif  WATER_MODE == 1 || WATER_MODE == 3
    vec3 waterFogColor = fogColor * fogColor * 0.5;
    #endif
    waterFogColor *= 0.5 * (1.0 - blindFactor);

    #ifdef OVERWORLD
    vec3 waterFogTint = lightCol * eBS * shadowFade + 0.05;
    #endif
    #ifdef NETHER
    vec3 waterFogTint = netherCol.rgb;
    #endif
    #ifdef END
    vec3 waterFogTint = endCol.rgb;
    #endif
    waterFogTint = sqrt(waterFogTint * length(waterFogTint));

    color = mix(color, waterFogColor * waterFogTint, fog);
}