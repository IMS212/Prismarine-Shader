vec4 waterColorSqrt = vec4(vec3(WATER_R, WATER_G, WATER_B) / 255.0, 1.0) * WATER_I;
vec4 waterColor = waterColorSqrt * waterColorSqrt;

vec4 waterSColorSqrt = vec4(vec3(WATER_R, WATER_G * 0.85, WATER_B) / 255.0, 1.0) * WATER_I;
vec4 waterShadowColor = waterSColorSqrt * waterSColorSqrt;

float uwaterAlpha = isEyeInWater * WATER_A * 1.5;
float waterAlpha = WATER_A + uwaterAlpha;
const float waterFogRange = 64.0 / WATER_FOG_DENSITY;