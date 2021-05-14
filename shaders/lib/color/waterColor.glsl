vec4 waterColorSqrt = vec4(vec3(WATER_R, WATER_G * 1.3, WATER_B) / 255.0, 1.0) * (WATER_I / 1.5);
vec4 waterColor = waterColorSqrt * waterColorSqrt;

#ifdef END
float waterEnd = 0.15;
#else
float waterEnd = 0.0;
#endif

float waterAlpha = WATER_A - waterEnd;
const float waterFogRange = 64.0 / WATER_FOG_DENSITY;