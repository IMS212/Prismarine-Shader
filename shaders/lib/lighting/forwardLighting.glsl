#if defined OVERWORLD || defined END
#include "/lib/lighting/shadows.glsl"
#endif

uniform int heldItemId, heldItemId2;

void GetLighting(inout vec3 albedo, out vec3 shadow, vec3 viewPos, vec3 worldPos,
                 vec2 lightmap, float smoothLighting, float NoL, float vanillaDiffuse,
                 float parallaxShadow, float emission, float subsurface) {

    #if EMISSIVE == 0 || (!defined ADVANCED_MATERIALS && EMISSIVE == 1)
    emission = 0.0;
    #endif

    #if SSS == 0 || (!defined ADVANCED_MATERIALS && SSS == 1)
    subsurface = 0.0;
    #endif

    #if defined OVERWORLD || defined END
    if (NoL > 0.0 || subsurface > 0.0) shadow = GetShadow(worldPos, NoL, subsurface, lightmap.y);
    shadow *= parallaxShadow;
    NoL = clamp(NoL * 1.01 - 0.01, 0.0, 1.0);
    
    float scattering = 0.0;
    if (subsurface > 0.0){
        float VoL = clamp(dot(normalize(viewPos.xyz), lightVec) * 0.5 + 0.5, 0.0, 1.0);
        scattering = pow(VoL, 16.0) * (1.0 - rainStrength) * subsurface;
        NoL = mix(NoL, 1.0, sqrt(subsurface) * 0.7);
        NoL = mix(NoL, 1.0, scattering);
    }
    
    vec3 fullShadow = shadow * NoL;
    
    #ifdef OVERWORLD
    float shadowMult = (1.0 - 0.95 * rainStrength) * shadowFade;
    vec3 sceneLighting = mix(ambientCol, lightCol, fullShadow * shadowMult);
    sceneLighting *= (4.0 - 3.0) * lightmap.y * lightmap.y * (1.0 + scattering * shadow);
    if (isEyeInWater == 1 && lightmap.y < 1){
        sceneLighting *= lightmap.y * 16;
    }
    #endif

    #ifdef END
    vec3 sceneLighting = endCol.rgb * (0.06 * fullShadow + 0.02);
    #endif

    #else
    vec3 sceneLighting = netherColSqrt.rgb * 0.1;
    #endif

    float newLightmap  = pow(lightmap.x, 10.0) * 1.5 + lightmap.x * 0.8;
    float lightMapBrightnessFactor = 4 - pow(lightmap.x, 4) - pow(lightmap.x, 4) - pow(lightmap.x, 4) - pow(lightmap.x, 4);
    blocklightCol *= lightMapBrightnessFactor;

    #ifdef LIGHTMAP_BRIGHTNESS_RECOLOR
    float lightFlatten1 = clamp(1.0 - pow(1.0 - emission, 128.0), 0.0, 1.0);
    if (lightFlatten1 == 0){
        blocklightCol.r *= (pow(newLightmap, 6)) * 3 * LIGHTMAP_R;
        blocklightCol.g *= (3.50 - newLightmap) * newLightmap * 1.25 * LIGHTMAP_G;
        blocklightCol.b *= (3.50 - newLightmap - newLightmap) * 2.50 * LIGHTMAP_B;
    } else {
        blocklightCol *= 2 * BLOCKLIGHT_I;
    }
    #endif


    #ifdef LIGHTMAP_DIM_CUTOFF
    blocklightCol *= pow(newLightmap, DIM_CUTOFF_FACTOR);
    #endif

    #ifdef NETHER
    vec3 blocklightColSqrtNether = vec3(BLOCKLIGHT_R_NETHER, BLOCKLIGHT_G_NETHER, BLOCKLIGHT_B_NETHER) * BLOCKLIGHT_I / 300.0;
    vec3 blocklightColNether = blocklightColSqrtNether * blocklightColSqrtNether;
    vec3 blockLighting = blocklightColNether * newLightmap * newLightmap;
    #endif

    #ifdef END
    vec3 blocklightColSqrtEnd = vec3(BLOCKLIGHT_R_END, BLOCKLIGHT_G_END, BLOCKLIGHT_B_END) * BLOCKLIGHT_I / 300.0;
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
    blocklightCol   = vec3(redCol * redColStatic, greenColStatic, blueCol * blueColStatic) * BLOCKLIGHT_I;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol;
    
    #elif CLM_MAINCOL == 1
    float rWP = (cameraPosition.x + cameraPosition.x) * (worldPos.x + worldPos.x);
    float bWP = (cameraPosition.z + cameraPosition.z) * (worldPos.z + worldPos.z);
    float redCol    = rWP * 0.000039;
    float greenCol  = bWP * 0.000038;
	float redColStatic    = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0004).r;
	float greenColStatic  = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
	float blueColStatic   = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
    blocklightCol   = vec3(redCol * redColStatic, greenCol * greenColStatic, blueColStatic) * BLOCKLIGHT_I;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol;

    #elif CLM_MAINCOL == 2
    float rWP = (cameraPosition.x + cameraPosition.x) * (worldPos.x + worldPos.x);
    float bWP = (cameraPosition.z + cameraPosition.z) * (worldPos.z + worldPos.z);
    float blueCol    = rWP * 0.00004;
    float greenCol  = bWP * 0.000038;
	float redColStatic    = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
	float greenColStatic  = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0006).r;
	float blueColStatic   = texture2D(noisetex, (cameraPosition.xz + worldPos.xz) * 0.0008).r;
    blocklightCol   = vec3(redColStatic, greenCol * greenColStatic, blueCol * blueColStatic) * BLOCKLIGHT_I;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol;

    #endif
    #endif

    //WORLD POSITION BASED - STATIC

    #ifdef OVERWORLD
    #if COLORED_LIGHTING_MODE == 3
    vec2 pos = (cameraPosition.xz + worldPos.xz);
    blocklightCol = x4(ntmix(pos, pos, pos, 0.00025)) * BLOCKLIGHT_I * 2;
    if (heldItemId == 64 || heldItemId2 == 64) blocklightCol = TORCH.rgb;
    if (heldItemId == 63 || heldItemId2 == 63) blocklightCol = SOUL_TORCH.rgb;
    if (heldItemId == 62 || heldItemId2 == 62) blocklightCol = JACKOLANTERN.rgb;
    if (heldItemId == 61 || heldItemId2 == 61) blocklightCol = TORCH.rgb;
    if (heldItemId == 60 || heldItemId2 == 60) blocklightCol = SOUL_TORCH.rgb;
    if (heldItemId == 59 || heldItemId2 == 59) blocklightCol = LAVA.rgb;
    if (heldItemId == 58 || heldItemId2 == 58) blocklightCol = BEACON.rgb;
    if (heldItemId == 57 || heldItemId2 == 57) blocklightCol = SEA_LANTERN.rgb;
    if (heldItemId == 56 || heldItemId2 == 56) blocklightCol = GLOWSTONE.rgb;
    if (heldItemId == 55 || heldItemId2 == 55) blocklightCol = SHROOMLIGHT.rgb;
    if (heldItemId == 54 || heldItemId2 == 54) blocklightCol = END_ROD.rgb;
    if (heldItemId == 53 || heldItemId2 == 53) blocklightCol = TORCH.rgb;
    if (heldItemId == 52 || heldItemId2 == 52) blocklightCol = REDSTONE_TORCH.rgb;
    if (heldItemId == 51 || heldItemId2 == 51) blocklightCol = SOUL_TORCH.rgb;
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol * BLOCKLIGHT_I;

    //TIME BASED
    #elif COLORED_LIGHTING_MODE == 2
    vec3 blockLighting = newLightmap * newLightmap * lightCol;

    //NORMAL
    #elif COLORED_LIGHTING_MODE == 0
    vec3 blockLighting =  newLightmap * newLightmap * blocklightCol;

    //HANDHELD
    #elif COLORED_LIGHTING_MODE == 4
    if (heldItemId == 64 || heldItemId2 == 64) blocklightCol = TORCH.rgb;
    if (heldItemId == 63 || heldItemId2 == 63) blocklightCol = SOUL_TORCH.rgb;
    if (heldItemId == 62 || heldItemId2 == 62) blocklightCol = JACKOLANTERN.rgb;
    if (heldItemId == 61 || heldItemId2 == 61) blocklightCol = TORCH.rgb;
    if (heldItemId == 60 || heldItemId2 == 60) blocklightCol = SOUL_TORCH.rgb;
    if (heldItemId == 59 || heldItemId2 == 59) blocklightCol = LAVA.rgb;
    if (heldItemId == 58 || heldItemId2 == 58) blocklightCol = BEACON.rgb;
    if (heldItemId == 57 || heldItemId2 == 57) blocklightCol = SEA_LANTERN.rgb;
    if (heldItemId == 56 || heldItemId2 == 56) blocklightCol = GLOWSTONE.rgb;
    if (heldItemId == 55 || heldItemId2 == 55) blocklightCol = SHROOMLIGHT.rgb;
    if (heldItemId == 54 || heldItemId2 == 54) blocklightCol = END_ROD.rgb;
    if (heldItemId == 53 || heldItemId2 == 53) blocklightCol = TORCH.rgb;
    if (heldItemId == 52 || heldItemId2 == 52) blocklightCol = REDSTONE_TORCH.rgb;
    if (heldItemId == 51 || heldItemId2 == 51) blocklightCol = SOUL_TORCH.rgb;
    vec3 blockLighting = newLightmap * newLightmap * blocklightCol;

    //ALBEDO-BASED
    //#elif COLORED_LIGHTING_MODE == 6
    //#ifdef GBUFFERS_TERRAIN
    //if (lightFlatten1 == 0){ //removes tinting from the emissive block's albedo leaving it as it is
        //if (albedo.r > albedo.b && albedo.r > albedo.g){
            //BLOCKLIGHT_I = 0.1;
            //blocklightCol = GLOWSTONE.rgb;
        //}
        //if (albedo.g > albedo.r && albedo.g > albedo.b){
            //BLOCKLIGHT_I = 0.2;
            //blocklightCol = vec3(0,1,0.25);
        //}
        //if (albedo.b > albedo.r || albedo.b > albedo.g){
            //BLOCKLIGHT_I = 0.3;
            //blocklightCol = SOUL_TORCH.rgb;
        //}
    //
    //#endif

    //vec3 blockLighting = newLightmap * newLightmap * blocklightCol * BLOCKLIGHT_I;
    #endif
    #endif

    #ifdef BLOCKLIGHT_FLICKERING
    float jitter = 1.0 - sin(frameTimeCounter + cos(frameTimeCounter)) * BLOCKLIGHT_FLICKERING_STRENGTH;
    blockLighting *= jitter;
    #endif

    vec3 minLighting = minLightCol * (1.0 - eBS);

    #ifdef TOON_LIGHTMAP
    minLighting *= floor(smoothLighting * 8.0 + 1.001) / 4.0;
    smoothLighting = 1.0;
    #endif
    
    vec3 albedoNormalized = normalize(albedo.rgb + 0.00001);
    vec3 emissiveLighting = mix(albedoNormalized, vec3(1.0), emission * 0.5);
    emissiveLighting *= emission * 4.0;

    float lightFlatten = clamp(1.0 - pow(1.0 - emission, 128.0), 0.0, 1.0);
    vanillaDiffuse = mix(vanillaDiffuse, 1.0, lightFlatten);
    smoothLighting = mix(smoothLighting, 1.0, lightFlatten);
        
    float nightVisionLighting = nightVision * 0.25;
    
    #ifdef ALBEDO_BALANCING
    float albedoLength = length(albedo.rgb);
    albedoLength /= sqrt((albedoLength * albedoLength) * 0.25 * (1.0 - lightFlatten) + 1.0);
    albedo.rgb = albedoNormalized * albedoLength;
    #endif

    //albedo = vec3(0.5);
    albedo *= sceneLighting + blockLighting + emissiveLighting + nightVisionLighting + minLighting;
    albedo *= vanillaDiffuse * smoothLighting * smoothLighting;

    #ifdef DESATURATION
    #ifdef OVERWORLD
    float desatAmount = sqrt(max(sqrt(length(fullShadow / 3.0)) * lightmap.y, lightmap.y)) *
                        sunVisibility * (1.0 - rainStrength * 0.4) + 
                        sqrt(lightmap.x) + lightFlatten;

    vec3 desatNight   = lightNight / LIGHT_NI;
    vec3 desatWeather = weatherCol.rgb / weatherCol.a * 0.5;

    desatNight *= desatNight; desatWeather *= desatWeather;
    
    float desatNWMix  = (1.0 - sunVisibility) * (1.0 - rainStrength);

    vec3 desatColor = mix(desatWeather, desatNight, desatNWMix);
    desatColor = mix(vec3(0.1), desatColor, sqrt(lightmap.y)) * 10.0;
    #endif

    #ifdef NETHER
    float desatAmount = sqrt(lightmap.x) + lightFlatten;

    vec3 desatColor = netherColSqrt.rgb / netherColSqrt.a;
    #endif

    #ifdef END
    float desatAmount = sqrt(lightmap.x) + lightFlatten;

    vec3 desatColor = endCol.rgb * 1.25;
    #endif

    desatAmount = clamp(desatAmount, DESATURATION_FACTOR * 0.4, 1.0);
    desatColor *= 1.0 - desatAmount;

    albedo = mix(GetLuminance(albedo) * desatColor, albedo, desatAmount);
    #endif

}
