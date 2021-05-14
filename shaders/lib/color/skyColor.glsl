vec3 SkyC = vec3(SKY_R, SKY_G, SKY_B) * SKY_I / 255.0 * 4;
vec3 skyCol = SkyC * SkyC;
vec3 fogCol = SkyC * SkyC;