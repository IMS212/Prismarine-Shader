#ifdef OVERWORLD
//Complex sky from RRE36's PhysicalSL edit and robobo1221 (modified).
#include "/lib/functions.glsl"
float getRayleigh(float cosTheta) {
    float phase  = 0.8 * (1.4 + 0.5 * cosTheta);
          phase *= rcp(pi*4);
  	return phase;
}
float getMie(float cosTheta, float g) {
    float mie   = 1.0 + pow2(g) - 2.0*g*cosTheta;
          mie   = (1.0 - pow2(g)) / ((4.0*pi) * mie*(mie*0.5+0.5));
    return mie;
}
float getDensity(float x) {
    float horizonOffset = HORIZON_OFFSET;
    return ATMOSPHERIC_DENSITY * rcp(pow(max(x - horizonOffset, 0.35e-3), 0.95));
}
vec3 getAbsorbtion(vec3 x, float y){
	vec3 absorption = x * -y;
	     absorption = exp(absorption) * 2.0;
    return absorption;
}
vec3 getLighting(vec3 lightvec) {
    vec3 ozone = vec3(0.3, 0.55, 1.0) * mix(vec3(1.0, 1.5, 1.0), vec3(1.0), sstep(lightvec, 0.0, 0.2));
    return getAbsorbtion(ozone, getDensity(lightvec.y));
}
vec3 calculateAtmosphere(vec3 dir, vec3 sunVec, vec3 moonVec) {
    float rainStrengthLowered   = rainStrength / 2.0;
    float rainStrengthIncreased = rainStrength * 1.5;
    float horizonBlending       = CHORIZON_BLENDINGFACTOR - (rainStrengthLowered / 8.0);
    float vDotS                 = dot(sunVec, dir);
    float vDotM                 = dot(moonVec, dir);

    float horizonOffset = HORIZON_OFFSET;

    mat2x3 phase       = mat2x3(getRayleigh(vDotS), getMie(vDotS, 0.74), getMie(vDotS, 0.65),
                                getRayleigh(vDotM), getMie(vDotM, 0.74), getMie(vDotM, 0.65));
           phase[0].y *= sstep(sunVec.y, -0.16, horizonOffset);
           phase[1].y *= sstep(sunVec.y, -0.16, horizonOffset);

    vec3 ozone = vec3(0.1, horizonBlending, 1.0) * mix(vec3(1.0, 1.1, 1.0), vec3(1.0), sstep(max(sunVec.y, moonVec.y), 0.0, 0.2));

    float sunMultiscattering    = phase[0].x * sstep(sunVec.y, horizonOffset, horizonOffset + 0.2) * 1.5 + phase[0].z * 0.5 + 0.1 * 0.5 + sstep(sunVec.y, horizonOffset, horizonOffset + 0.4) * 0.5;
          sunMultiscattering   *= 0.5 + sstep(sunVec.y, horizonOffset, horizonOffset + 0.4) * 0.5;

    float moonMultiscattering   = phase[1].x * sstep(moonVec.y, horizonOffset, horizonOffset + 0.2) * 1.5 + phase[1].z;
          moonMultiscattering  *= 0.5 + sstep(moonVec.y, horizonOffset, horizonOffset + 0.4) * 0.5;

    float sunlightBlue      = SUNLIGHTCOL_B - rainStrengthLowered;
    float moonlightBlue     = SUNLIGHTCOL_B + (rainStrengthLowered / 2.0);
    float sunlightIntensity = SUNLIGHTCOL_I - (rainStrengthLowered / 1.3);

    vec3 sunlight   = getLighting(sunVec) * vec3(SUNLIGHTCOL_R, SUNLIGHTCOL_G, sunlightBlue) * weatherCol.rgb * sunlightIntensity;
    vec3 moonlight  = getLighting(moonVec) * vec3(MOONLIGHTCOL_R, MOONLIGHTCOL_G, moonlightBlue) * MOONLIGHTCOL_I;

    vec3 sunScattering  = vec3(0.1, horizonBlending, 1.0) * getDensity(dir.y);
         sunScattering  = mix(sunScattering * getAbsorbtion(ozone, getDensity(dir.y)), mix(1.0 - exp2(-0.5 * sunScattering), 0.5 * ozone / (1.0 + ozone), 1.0 - exp2(-0.25 * getDensity(dir.y))), sqrt(saturate(length(max(sunVec.y - horizonOffset, 0.0)))) * 0.9);
         sunScattering *= sunlight * 0.5 + 0.5 * length(sunlight);
         sunScattering += (1.0 - exp(-getDensity(dir.y) * ozone)) * sunMultiscattering * sunlight;
         sunScattering += phase[0].y * sunlight * rcp(pi);

    vec3 moonScattering  = vec3(0.1, horizonBlending, 1.0) * getDensity(dir.y);
         moonScattering  = mix(moonScattering * getAbsorbtion(ozone, getDensity(dir.y)), mix(1.0 - exp2(-0.5 * moonScattering), 0.5 * ozone / (1.0 + ozone), 1.0 - exp2(-0.25 * getDensity(dir.y))), sqrt(saturate(length(max(moonVec.y - horizonOffset, 0.0)))) * 0.9);
         moonScattering *= moonlight * 0.5 + 0.5 * length(moonlight);
         moonScattering += (1.0 - exp(-getDensity(dir.y) * ozone)) * moonMultiscattering * moonlight;
         moonScattering += phase[1].y * moonlight * rcp(pi);
         moonScattering = mix(moonScattering, dot(moonScattering, vec3(1.0/3.0)) * vec3(0.2, 0.55, 1.0), 0.8);

    return (sunScattering) + (moonScattering) * rcp(pi);
}

vec3 renderAtmosphere(vec3 dir, mat2x3 lightvec) {
    return calculateAtmosphere(dir, lightvec[0], lightvec[1]);
}

//Modified simple sky from BSL by Capt Tatsu (just like most of stuff in this shader lol)
vec3 GetSkyColor(vec3 viewPos, vec3 lightCol, bool isReflection) {
    vec3 sky = skyCol;
    vec3 nViewPos = normalize(viewPos);

    float VoU = clamp(dot(nViewPos, upVec), 0.0, 1.0);
    float invVoU = clamp(dot(nViewPos, -upVec) * 1.015 - 0.015, 0.0, 1.0);
    float VoL = clamp(dot(nViewPos, sunVec) * 0.5 + 0.5, 0.0, 1.0);

    float horizonExponent = 1.5 * ((1.0 - VoL) * sunVisibility * (1.0 - rainStrength) *
                            (1.0 - 0.5 * timeBrightness)) + HORIZON_DISTANCE;
    float horizon = pow(1.0 - VoU, horizonExponent);
    horizon *= (0.5 * sunVisibility + 0.3) * (1 - rainStrength * 0.75) / HORIZON_HORIZONTAL_EXPONENT;
    
    float lightmix = VoL * VoL * (1.0 - VoU) * pow(1.0 - timeBrightness, 3.0) +
                     horizon * 0.1 * timeBrightness;
    lightmix *= sunVisibility * (1.0 - rainStrength);

    #ifdef SKY_VANILLA
    sky = mix(fogCol, sky, VoU);
    #endif

    #if SKY_GROUND > 0
    float groundFactor = 0.5 * (11.0 * rainStrength * rainStrength + 1.0) * 
                         (-5.0 * sunVisibility + 6.0);
    float ground = 1.0 - exp(-(groundFactor * SKY_GROUND_BRIGHTNESS) / (invVoU * 8.0));
    #if SKY_GROUND == 1
    if (!isReflection) ground = 1.0;
    #endif
    #else
    float ground = 1.0;
    #endif

    float mult = (0.5 * (1.0 + rainStrength) + horizon) * ground;

    sky = mix(
        sky * pow(max(1.0 - lightmix, 0.0), 2.0 * sunVisibility),
        vec3(lightCol.r, lightCol.g * 1.1, lightCol.b) * sqrt(vec3(lightCol.r, lightCol.g * 1.1, lightCol.b)) * HORIZON_VERTICAL_EXPONENT,
        lightmix
    ) * sunVisibility + (lightNight * lightNight * 0.4);
    
    vec3 weatherSky = weatherCol.rgb * weatherCol.rgb;
    weatherSky *= GetLuminance(ambientCol / (weatherSky)) * 1.4;
    sky = mix(sky, weatherSky, rainStrength) * mult;

    return pow(sky, vec3(1.125));
}

vec3 GetSkyColor(vec3 viewPos, bool isReflection) {
    vec3 nViewPos = normalize(viewPos);

    float VoU = clamp(dot(nViewPos,  upVec), -1.0, 1.0);
    float VoL = clamp(dot(nViewPos, sunVec), -1.0, 1.0);

    float density = 0.375;
    float nightDensity = 0.65;
    float weatherDensity = 1.5;
    float groundDensity = 0.08 * (4.0 - 3.0 * sunVisibility) *
                          (10.0 * rainStrength * rainStrength + 1.0);
    
    float exposure = exp2(timeBrightness * 0.75 - 0.75);
    float nightExposure = exp2(-3.5);

    float baseGradient = exp(-(1.0 - pow(1.0 - max(VoU, 0.0), 1.5 - 0.5 * VoL)) / density);

    #if SKY_GROUND > 0
    float groundVoU = clamp(-VoU * 1.015 - 0.015, 0.0, 1.0);
    float ground = 1.0 - exp(-groundDensity * SKY_GROUND_BRIGHTNESS / groundVoU);
    #if SKY_GROUND == 1
    if (!isReflection) ground = 1.0;
    #endif
    #else
    float ground = 1.0;
    #endif

    vec3 sky = skyCol * baseGradient / (SKY_I * SKY_I);
    #ifdef SKY_VANILLA
    sky = mix(sky, fogCol * baseGradient, pow(1.0 - max(VoU, 0.0), 4.0));
    #endif
    sky = sky / sqrt(sky * sky + 1.0) * exposure * sunVisibility * (SKY_I * SKY_I);

    float sunMix = (VoL * 0.5 + 0.5) * pow(clamp(1.0 - VoU, 0.0, 1.0), 2.0 - sunVisibility) *
                   pow(1.0 - timeBrightness * 0.6, 3.0);
    float horizonMix = pow(1.0 - abs(VoU), 2.5) * 0.125 * (1.0 - timeBrightness * 0.5);
    float lightMix = (1.0 - (1.0 - sunMix) * (1.0 - horizonMix));

    vec3 lightSky = pow(lightSun, vec3(4.0 - sunVisibility)) * baseGradient;
    lightSky = lightSky / (1.0 + lightSky * rainStrength);

    sky = mix(
        sqrt(sky * (1.0 - lightMix)), 
        sqrt(lightSky), 
        lightMix
    );
    sky *= sky;

    float nightGradient = exp(-max(VoU, 0.0) / nightDensity);
    vec3 nightSky = lightNight * lightNight * nightGradient * nightExposure;
    sky = mix(nightSky, sky, sunVisibility * sunVisibility);

    float rainGradient = exp(-max(VoU, 0.0) / weatherDensity);
    vec3 weatherSky = weatherCol.rgb * weatherCol.rgb;
    weatherSky *= GetLuminance(ambientCol / (weatherSky)) * (0.2 * sunVisibility + 0.2);
    sky = mix(sky, weatherSky * rainGradient, rainStrength);

    sky *= ground;

    if (cameraPosition.y < 1.0) sky *= exp(2.0 * cameraPosition.y - 2.0);

    return sky;
}

#endif