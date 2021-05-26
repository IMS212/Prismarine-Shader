//from PhysicalSL by RRE36 (modified)

float getRayleighScatter(float ct) {
    float phase  = 0.8 * (1.4 + 0.5 * ct);
          phase *= 1/(pi*4);
  	return phase;
}
float getMieScatter(float ct, float g) {
    float MieScatter   = 1.0 + pow2(g) - 2.0* g * ct;
          MieScatter   = (1.0 - pow2(g)) / ((4.0 * pi) * MieScatter * (MieScatter*0.5+0.5));
    return MieScatter;
}
float getDensity(float x) {
    float horizonOffset = HORIZON_OFFSET;
    return ATMOSPHERIC_DENSITY * 1/pow(max(x - horizonOffset, 0.00035), 0.95);
}
vec3 getAbsorption(vec3 x, float y){
	vec3 absorption = x * -y;
	     absorption = exp(absorption) * 2.0;
    return absorption;
}
vec3 getLighting(vec3 lightVec) {
    vec3 oBR1 = vec3(0.2, 0.55, 1) * 0.5;
    vec3 oBR2 = vec3(1.0, 1.5, 1.0);
    vec3 ozone = oBR1 * mix(oBR2, vec3(1.0), ss(lightVec, 0.0, 0.2));
    return getAbsorption(ozone, getDensity(lightVec.y));
}
vec3 calculateAtmosphere(vec3 direction, vec3 sunVec, vec3 moonVec) {
    float rainStrengthLowered   = rainStrength / 2.0;
    float rainStrengthIncreased = rainStrength * 1.5;
    float sunV                  = dot(sunVec, direction);
    float moonV                 = dot(moonVec, direction);
    float horizonBlending       = CHORIZON_BLENDINGFACTOR - (rainStrengthLowered / 8.0);
    float horizonOffset         = HORIZON_OFFSET;

    mat2x3 phase       = mat2x3(getRayleighScatter(sunV), getMieScatter(sunV, 0.74), getMieScatter(sunV, 0.65),
                                getRayleighScatter(moonV), getMieScatter(moonV, 0.74), getMieScatter(moonV, 0.65));
           phase[0].y *= ss(sunVec.y, -0.16, horizonOffset);
           phase[1].y *= ss(sunVec.y, -0.16, horizonOffset);

    vec3 ozone = vec3(0.1, horizonBlending, 1.0) * mix(vec3(1.0, 1.1, 1.0), vec3(1.0), ss(max(sunVec.y, moonVec.y), 0.0, 0.2));

    float sunMultiScatter    = phase[0].x * ss(sunVec.y, horizonOffset, horizonOffset + 0.2) + phase[0].z * 0.5 + 0.1 * 0.5 + ss(sunVec.y, horizonOffset, horizonOffset + 0.4) * 0.5;
          sunMultiScatter   *= .5 + ss(sunVec.y, horizonOffset, horizonOffset + 0.4);

    float moonMultiScatter   = phase[1].x * ss(moonVec.y, horizonOffset, horizonOffset + 0.2) + phase[1].z;
          moonMultiScatter  *= .5 + ss(moonVec.y, horizonOffset, horizonOffset + 0.4);

    float sunlightBlue      = SUNLIGHTCOL_B - rainStrengthLowered;
    float moonlightBlue     = SUNLIGHTCOL_B + (rainStrengthLowered / 2.0);
    float sunlightIntensity = SUNLIGHTCOL_I - (rainStrengthLowered / 1.3);

    #if SKY_MODE == 2
    if (rainStrength != 0){
        sunCol.rgb = weatherCol.rgb / 3;
    }
    #endif

    vec3 sunlight   = getLighting(sunVec) * weatherCol.rgb * sunCol;
    vec3 moonlight  = getLighting(moonVec) * moonCol;

    vec3 sunScatter  = vec3(0.1, horizonBlending, 1.0) * getDensity(direction.y);
         sunScatter  = mix(sunScatter * getAbsorption(ozone, getDensity(direction.y)),
                       mix(1.0 - exp2(-0.5 * sunScatter), 0.5 * ozone / (1.0 + ozone), 1.0 - exp2(-0.25 * getDensity(direction.y))),
                       sqrt(sat(length(max(sunVec.y - horizonOffset, 0.0)))) * 0.9);
         sunScatter *= sunlight * 0.5 + 0.5 * length(sunlight);
         sunScatter += (1.0 - exp(-getDensity(direction.y) * ozone)) * sunMultiScatter * sunlight;
         sunScatter += phase[0].y * sunlight * 1/pi;

    vec3 moonScatter  = vec3(0.1, horizonBlending, 1.0) * getDensity(direction.y);
         moonScatter  = mix(moonScatter * getAbsorption(ozone, getDensity(direction.y)),
                        mix(1.0 - exp2(-0.5 * moonScatter), 0.5 * ozone / (1.0 + ozone), 1.0 - exp2(-0.25 * getDensity(direction.y))),
                        sqrt(sat(length(max(moonVec.y - horizonOffset, 0.0)))) * 0.9);
         moonScatter *= moonlight * 0.5 + 0.5 * length(moonlight);
         moonScatter += (1.0 - exp(-getDensity(direction.y) * ozone)) * moonMultiScatter * moonlight;
         moonScatter += phase[1].y * moonlight * 1/pi;
         moonScatter = mix(moonScatter, dot(moonScatter, vec3(1 / 3)) * vec3(0.2, 0.55, 1.0), 0.8);

    return sunScatter + moonScatter * 1/pi;
}

vec3 renderAtmosphere(vec3 direction, mat2x3 lightVec) {
    return calculateAtmosphere(direction, lightVec[0], lightVec[1]);
}