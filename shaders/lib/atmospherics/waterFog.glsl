#if (WATER_MODE == 1 || WATER_MODE == 3) && !defined SKY_VANILLA && (!defined NETHER || !defined NETHER_VANILLA)
uniform vec3 fogColor;
#endif

vec4 GetWaterFog(vec3 viewPos) {
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-3.0 * fog);
    
    #if WATER_MODE == 0 || WATER_MODE == 2
    vec3 waterFogColor = vec3(WATER_R * 0.2, WATER_G * 0.6, WATER_B * 1.3) / 255 * WATER_I * WATER_I;
    #elif  WATER_MODE == 1 || WATER_MODE == 3
    vec3 waterFogColor = fogColor * fogColor * 0.5;
    #endif
    waterFogColor *= 0.5 * (1.0 - blindFactor);

    #ifdef OVERWORLD
    vec3 waterFogTint = lightCol * shadowFade * 0.9 + 0.1;
    #endif
    #ifdef NETHER
    vec3 waterFogTint = netherCol.rgb;
    #endif
    #ifdef END
    vec3 waterFogTint = endCol.rgb;
    #endif
    waterFogTint = sqrt(waterFogTint * length(waterFogTint));

    return vec4(waterFogColor * waterFogTint, fog);
}