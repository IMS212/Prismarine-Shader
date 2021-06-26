#if defined OVERWORLD || defined END
#include "/lib/lighting/shadows.glsl"
#endif
#include "/lib/prismarine/caustics.glsl"
#include "/lib/prismarine/functions.glsl"

void GetLighting(inout vec3 albedo, out vec3 shadow, vec3 viewPos, vec3 worldPos,
                 vec2 lightmap, float smoothLighting, float NoL, float vanillaDiffuse,
                 float parallaxShadow, float emission, float subsurface) {
    #if EMISSIVE == 0 || (!defined ADVANCED_MATERIALS && EMISSIVE == 1)
    emission = 0.0;
    #endif

    #if SUBSURFACE_SCATTERING == 0 || (!defined ADVANCED_MATERIALS && SUBSURFACE_SCATTERING == 1)
    subsurface = 0.0;
    #endif

    #if defined OVERWORLD || defined END
    if (NoL > 0.0 || subsurface > 0.0) shadow = GetShadow(worldPos, NoL, subsurface, lightmap.y);
    shadow *= parallaxShadow;
    NoL = clamp(NoL * 1.01 - 0.01, 0.0, 1.0);
    
    float scattering = 0.0;
    if (subsurface > 0.0){
        float VdotL2 = clamp(dot(normalize(viewPos.xyz), lightVec) * 0.5 + 0.5, 0.0, 1.0);
        scattering = pow(VdotL2, 16.0) * (1.0 - rainStrength) * subsurface;
        NoL = mix(NoL, 1.0, sqrt(subsurface) * 0.7);
        NoL = mix(NoL, 1.0, scattering);
    }
    
    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD

    #if NOISEMAP_SHADOWS == 1
    float noiseMap = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0002).r;
    #elif NOISEMAP_SHADOWS == 2
    float noiseMap = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.02).r + SHADING_REDUCTION_FACTOR;
    #else
    float noiseMap = 1;
    #endif

    float shadowMult = (1.0 - 0.95 * rainStrength) * shadowFade;
    vec3 sceneLighting = mix(ambientCol, lightCol * noiseMap, fullShadow * shadowMult);
    sceneLighting *= (4.0 - 3.0 * eBS) * lightmap.y * lightmap.y * (1.0 + scattering * shadow);
    #endif

    #ifdef END
    vec3 sceneLighting = endCol.rgb * (0.075 * fullShadow + 0.025);
    #endif

    #else
    vec3 sceneLighting = netherColSqrt.rgb * 0.1;
    #endif
    
    float newLightmap  = pow(lightmap.x, 10.0) * 1.5 + lightmap.x * 0.7;

    float blocklightStrength = BLOCKLIGHT_I;

    #ifdef BLOCKLIGHT_FLICKERING
    blocklightStrength += getFlickering(vec3(0.1,0.1,0.1));
    #endif

    #ifdef NETHER
    vec3 blocklightColSqrtNether = vec3(BLOCKLIGHT_R_NETHER, BLOCKLIGHT_G_NETHER, BLOCKLIGHT_B_NETHER) * blocklightStrength / 300.0;
    vec3 blocklightColNether = blocklightColSqrtNether * blocklightColSqrtNether;
    vec3 blockLighting = blocklightColNether * newLightmap * newLightmap;
    #endif

    #ifdef END
    vec3 blocklightColSqrtEnd = vec3(BLOCKLIGHT_R_END, BLOCKLIGHT_G_END, BLOCKLIGHT_B_END) * blocklightStrength / 300.0;
    vec3 blocklightColEnd = blocklightColSqrtEnd * blocklightColSqrtEnd;
    vec3 blockLighting = blocklightColEnd * newLightmap * newLightmap;
    #endif

    //Three different lighting modes for emissive things in Overworld.
    //WORLD POSITION BASED - DYNAMIC
    #if defined OVERWORLD && COLORED_LIGHTING_MODE == 1

    #if CLM_MAINCOL == 0
    float rWP = (cameraPosition.x + cameraPosition.x) * (worldPos.x + worldPos.x);
    float bWP = (cameraPosition.z + cameraPosition.z) * (worldPos.z + worldPos.z);
    float redCol    = rWP * 0.00004;
    float blueCol   = bWP * 0.000038;
	float redColStatic    = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0004).r;
	float greenColStatic  = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
	float blueColStatic   = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0008).r;
    #if NOISEMAP_SHADOWS != 0
    noiseMap = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.01).r + (SHADING_REDUCTION_FACTOR * 1.5);
    #else
    noiseMap = 1;
    #endif
    blocklightCol   = vec3(redCol * redColStatic, greenColStatic, blueCol * blueColStatic) * blocklightStrength;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol * x2(noiseMap);
    
    #elif CLM_MAINCOL == 1
    float rWP = (cameraPosition.x + cameraPosition.x) * (worldPos.x + worldPos.x);
    float bWP = (cameraPosition.z + cameraPosition.z) * (worldPos.z + worldPos.z);
    float redCol    = rWP * 0.000039;
    float greenCol  = bWP * 0.000038;
	float redColStatic    = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0004).r;
	float greenColStatic  = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
	float blueColStatic   = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
    #if NOISEMAP_SHADOWS != 0
    noiseMap = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.01).r + (SHADING_REDUCTION_FACTOR * 1.5);
    #else
    noiseMap = 1;
    #endif
    blocklightCol   = vec3(redCol * redColStatic, greenCol * greenColStatic, blueColStatic) * blocklightStrength;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol * x2(noiseMap);

    #elif CLM_MAINCOL == 2
    float rWP = (cameraPosition.x + cameraPosition.x) * (worldPos.x + worldPos.x);
    float bWP = (cameraPosition.z + cameraPosition.z) * (worldPos.z + worldPos.z);
    float blueCol    = rWP * 0.00004;
    float greenCol  = bWP * 0.000038;
	float redColStatic    = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
	float greenColStatic  = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
	float blueColStatic   = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0008).r;
    #if NOISEMAP_SHADOWS != 0
    noiseMap = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.01).r + (SHADING_REDUCTION_FACTOR * 1.5);
    #else
    noiseMap = 1;
    #endif
    blocklightCol   = vec3(redColStatic, greenCol * greenColStatic, blueCol * blueColStatic) * blocklightStrength;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol * x2(noiseMap);

    #endif
    #endif

    //WORLD POSITION BASED - STATIC
    #ifdef OVERWORLD
    #if COLORED_LIGHTING_MODE == 3
    vec2 pos = (cameraPosition.xz + worldPos.xz);
    blocklightCol = x4(ntmix(pos, pos, pos, 0.0005)) * blocklightStrength * 4;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol;

    //TIME BASED
    #elif COLORED_LIGHTING_MODE == 2
    vec3 blockLighting = newLightmap * newLightmap * lightCol;

    //NORMAL
    #elif COLORED_LIGHTING_MODE == 0
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol;
    #endif
    #endif

    vec3 minLighting = minLightCol * (1.0 - eBS);

    #ifdef TOON_LIGHTMAP
    minLighting *= floor(smoothLighting * 8.0 + 1.001) / 4.0;
    smoothLighting = 1.0;
    #endif
    
    vec3 emissiveLighting = albedo * vec3(emission * 4.0);

    float lightFlatten = pow(min(emission * 4.0, 1.0), 4.0);
    vanillaDiffuse = mix(vanillaDiffuse, 1.0, lightFlatten);
    smoothLighting = mix(smoothLighting, 1.0, lightFlatten);
    
    float nightVisionLighting = nightVision * 0.25;
    
    //albedo = vec3(0.5);
    albedo *= sceneLighting + blockLighting + emissiveLighting + nightVisionLighting + minLighting;
    albedo *= vanillaDiffuse * smoothLighting * smoothLighting;

    #ifdef DESATURATION
    #ifdef OVERWORLD
    float desatAmount = sqrt(max(sqrt(length(fullShadow / 3.0)) * lightmap.y, lightmap.y)) *
                        sunVisibility * (1.0 - rainStrength * 0.4) + 
                        sqrt(lightmap.x + emission * 4.0);

    vec3 desatNight   = lightNight / LIGHT_NI;
    vec3 desatWeather = weatherCol.rgb / weatherCol.a * 0.5;

    desatNight *= desatNight; desatWeather *= desatWeather;
    
    float desatNWMix  = (1.0 - sunVisibility) * (1.0 - rainStrength);

    vec3 desatColor = mix(desatWeather, desatNight, desatNWMix);
    desatColor = mix(vec3(0.1), desatColor, sqrt(lightmap.y)) * 10.0;
    #endif

    #ifdef NETHER
    float desatAmount = sqrt(lightmap.x + emission * 4.0);

    vec3 desatColor = netherColSqrt.rgb / netherColSqrt.a;
    #endif

    #ifdef END
    float desatAmount = sqrt(lightmap.x + emission * 4.0);

    vec3 desatColor = endCol.rgb * 1.25;
    #endif

    desatAmount = clamp(desatAmount, DESATURATION_FACTOR * 0.4, 1.0);
    desatColor *= 1.0 - desatAmount;

    albedo = mix(GetLuminance(albedo) * desatColor, albedo, desatAmount);
    #endif
}