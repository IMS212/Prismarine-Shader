#ifdef SKY_VANILLA
uniform vec3 skyColor;
uniform vec3 fogColor;

vec3 skyCol = pow(skyColor, vec3(2.2)) * SKY_I * SKY_I;
vec3 fogCol = pow(fogColor, vec3(2.2)) * SKY_I * SKY_I;
#else
vec3 skyColSqrt = vec3(SKY_R, SKY_G, SKY_B) * SKY_I / 255.0;
vec3 skyCol = skyColSqrt * skyColSqrt;
vec3 fogCol = skyColSqrt * skyColSqrt;
#endif

#ifdef TF
vec3 tfSkyUp = vec3(TFSKY_R, TFSKY_G, TFSKY_B) * TFSKY_I / 512;
vec3 tfSkyDown = vec3(TFSKYD_R, TFSKYD_G, TFSKYD_B) * TFSKYD_I / 512;
#endif