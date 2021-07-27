#if (WATER_MODE == 1 || WATER_MODE == 3) && !defined SKY_VANILLA && !defined NETHER
uniform vec3 fogColor;
#endif

void WaterFog(inout vec3 color, vec3 viewPos) {
    float fog = length(viewPos) / waterFogRange;
    fog = 1.0 - exp(-3.0 * fog);
    
    #if WATER_MODE == 0 || WATER_MODE == 2
    vec3 waterFogColor = vec3(WATER_R * 0.25, WATER_G * 0.7, WATER_B * 1.25) / 255 * WATER_I * WATER_I;
    #elif  WATER_MODE == 1 || WATER_MODE == 3
    vec3 waterFogColor = fogColor * fogColor * 0.5;
    #endif
    waterFogColor *= 0.5 * (1.0 - blindFactor);

    #ifdef OVERWORLD
    vec3 waterFogTint = lightCol * shadowFade + 0.05;
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