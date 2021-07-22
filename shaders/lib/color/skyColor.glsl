vec3 skyColSqrt = vec3(SKY_R, SKY_G, SKY_B) * SKY_I / 255.0;
vec3 skyCol = skyColSqrt * skyColSqrt;
vec3 fogCol = skyColSqrt * skyColSqrt;

vec3 sunColSqrt = vec3(SUNLIGHTCOL_R, SUNLIGHTCOL_G, SUNLIGHTCOL_B) * SUNLIGHTCOL_I / 255.0;
vec3 moonColSqrt = vec3(MOONLIGHTCOL_R, MOONLIGHTCOL_G, MOONLIGHTCOL_B) * MOONLIGHTCOL_I / 255.0;
vec3 sunCol = sunColSqrt * sunColSqrt;
vec3 moonCol = moonColSqrt * moonColSqrt;