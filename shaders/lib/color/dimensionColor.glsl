#ifdef OVERWORLD
#include "lightColor.glsl"
#endif

#ifdef NETHER
#include "netherColor.glsl"
#endif

#ifdef END
#include "endColor.glsl"
#endif

vec3 minLightColSqrt = vec3(MINLIGHT_R, MINLIGHT_G, MINLIGHT_B) * (0.7 * MINLIGHT_I + 0.3) / 255.0;
vec3 minLightCol	 = minLightColSqrt * minLightColSqrt * 0.04;