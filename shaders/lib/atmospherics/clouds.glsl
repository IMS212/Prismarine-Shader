#include "/lib/color/auroraColor.glsl"
#include "/lib/prismarine/functions.glsl"

float GetNoise(vec2 pos) {
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.5453);
}

void DrawStars(inout vec3 color, vec3 viewPos) {
	vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
	vec3 planeCoord = wpos / (wpos.y + length(wpos.xz));
	vec2 wind = vec2(frametime, 0.0);
	vec2 coord = planeCoord.xz * 0.4 + cameraPosition.xz * 0.0001 + wind * 0.00125;
	coord = floor(coord * 1024.0) / 1024.0;
	
	float VoU = clamp(dot(normalize(viewPos), normalize(upVec)), 0.0, 1.0);
	float multiplier = sqrt(sqrt(VoU)) * 5.0 * (1.0 - rainStrength);
	
	float star = 1.25 * STARS_AMOUNT;
	if (VoU > 0.0) {
		star *= GetNoise(coord.xy);
		star *= GetNoise(coord.xy + 0.10);
		star *= GetNoise(coord.xy + 0.23);
	}
	star = clamp(star - 0.7125, 0.0, 1.0) * multiplier;
	
	#ifdef DAY_STARS
	color += star * vec3(0.75, 0.85, 1.00);
	#else
	if (moonVisibility > 0.0) color += star * pow(vec3(1.75, 1.85, 2.00), vec3(0.8));
	#endif

	#ifdef END
	color += star * pow(vec3(1.15, 0.85, 1.00) * 16, vec3(0.8));
	#endif

	star *= 0.5 * STARS_BRIGHTNESS;
}

void DrawBigStars(inout vec3 color, vec3 viewPos) {
	vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
	vec3 planeCoord = wpos / (wpos.y + length(wpos.xz));
	vec2 wind = vec2(frametime, 0.0);
	vec2 coord = planeCoord.xz * 1.2 + cameraPosition.xz * 0.0001 + wind * 0.00125;
	coord = floor(coord * 1024.0) / 1024.0;
	
	float VoU = clamp(dot(normalize(viewPos), normalize(upVec)), 0.0, 1.0);
	float multiplier = sqrt(sqrt(VoU)) * 3.0 * (1.0 - rainStrength);
	
	float star = 1.25 * STARS_AMOUNT;
	if (VoU > 0.0) {
		star *= GetNoise(coord.xy);
		star *= GetNoise(coord.xy + 0.10);
		star *= GetNoise(coord.xy + 0.20);
	}
	star = clamp(star - 0.7125, 0.0, 1.0) * multiplier;
		
	#ifdef DAY_STARS
	color += star * vec3(0.75, 0.85, 1.00);
	#else
	if (moonVisibility > 0.0) color += star * vec3(0.75, 0.85, 1.00);
	#endif

	#ifdef END
	color += star * pow(vec3(1.15, 0.85, 1.00) * 16 * endCol.rgb, vec3(1.0));
	#endif

	star *= 0.5 * STARS_BRIGHTNESS;
}

#ifdef OVERWORLD
#ifdef AURORA
float AuroraSample(vec2 coord, vec2 wind, float VoU) {
	float noise = texture2D(noisetex, coord * 0.0625  + wind * 0.25).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.03125 + wind * 0.15).b * 3.0;

	noise = max(1.0 - 4.0 * (0.5 * VoU + 0.5) * abs(noise - 3.0), 0.0);

	return noise;
}

vec3 DrawAurora(vec3 viewPos, float dither, int samples) {

	float sampleStep = 1.0 / samples;
	float currentStep = dither * sampleStep;

	float VoU = dot(normalize(viewPos), upVec);

	float visibility = moonVisibility * (1.0 - rainStrength) * (1.0 - rainStrength);

	#ifdef WEATHER_PERBIOME
	visibility *= isCold * isCold;
	#endif

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.000125,
		sin(frametime * CLOUD_SPEED * 0.05) * 0.00025
	);

	vec3 aurora = vec3(0.0);

	if (VoU > 0.0 && visibility > 0.0) {
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < samples; i++) {
			vec3 planeCoord = wpos * ((8.0 + currentStep * 7.0) / wpos.y) * 0.003;
			vec2 coord = cameraPosition.xz * 0.00004 + planeCoord.xz;

			float noise = AuroraSample(coord, wind, VoU);
			
			if (noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.125 + wind * 0.25).b;
				noise *= 0.5 * texture2D(noisetex, coord + wind * 16.0).b + 0.75;
				noise = noise * noise * 3.0 * sampleStep;
				noise *= max(sqrt(1.0 - length(planeCoord.xz) * 3.75), 0.0);

				vec3 auroraColor = mix(auroraLowCol, auroraHighCol, pow(currentStep, 0.4));
				aurora += noise * auroraColor * exp2(-6.0 * i * sampleStep);
			}
			currentStep += sampleStep;
		}
	}

	return aurora * visibility;
}
#endif
#endif

float RiftSample(vec2 coord, vec2 wind, float VoU) {
	float noise = texture2D(noisetex, coord * 1.0000  + wind * 0.25).b;
		  noise+= texture2D(noisetex, coord * 0.5000  + wind * 0.20).b;
		  noise+= texture2D(noisetex, coord * 0.2500  + wind * 0.15).b;
		  noise+= texture2D(noisetex, coord * 0.1250  + wind * 0.10).b;
		  noise+= texture2D(noisetex, coord * 0.0625  + wind * 0.05).b;	
	noise *= NEBULA_AMOUNT;
	noise = max(1.0 - 2.0 * (0.5 * VoU + 0.5) * abs(noise - 3.5), 0.0);

	return noise;
}

vec3 DrawRift(vec3 viewPos, float dither, int samples, float riftType) {
	dither *= NEBULA_DITHERING_STRENGTH;

	float auroraVisibility = 0.0;
	float visFactor = 1.0;

	#ifdef NEBULA_AURORA_CHECK
	#if defined AURORA && defined WEATHER_PERBIOME && defined OVERWORLD
	auroraVisibility = isCold * isCold;
	#endif
	#endif

	#ifdef OVERWORLD
	visFactor = (moonVisibility - rainStrength) * (moonVisibility - auroraVisibility) * (1 - auroraVisibility);
	#endif

	float VoU = abs(dot(normalize(viewPos.xyz), upVec));
	float sampleStep = 1.0 / samples;
	float currentStep = dither * sampleStep;

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.000125,
		sin(frametime * CLOUD_SPEED * 0.05) * 0.00125
	);

	vec3 rift = vec3(0.0);
	vec3 riftColor = vec3(0.0);

	if (VoU > 0.0) {
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < samples; i++) {
			vec3 planeCoord = wpos * ((16.0 + currentStep * -8.0)) * 0.001 * NEBULA_STRETCHING;
			vec2 coord = cameraPosition.xz * 0.0000225 * NEBULA_OFFSET_FACTOR + planeCoord.xz;
			#ifdef NETHER
			coord = cameraPosition.xz * 0.0001 + planeCoord.xz;
			#endif

			if (riftType == 0){
				coord += vec2(coord.y, -coord.x) * 1.00 * NEBULA_DISTORTION;
				coord += cos(mix(vec2(cos(currentStep * 1), sin(currentStep * 2.00)), vec2(cos(currentStep * 3.0), sin(currentStep * 4.00)), currentStep) * 0.0005);
				coord += sin(mix(vec2(cos(currentStep * 2), sin(currentStep * 2.50)), vec2(cos(currentStep * 3.0), sin(currentStep * 3.50)), currentStep) * 0.0010);
				coord += cos(mix(vec2(cos(currentStep * 3), sin(currentStep * 3.75)), vec2(cos(currentStep * 4.5), sin(currentStep * 5.25)), currentStep) * 0.0015);
			}else{
				coord += vec2(coord.y, -coord.x) * 2.00 * NEBULA_DISTORTION;
				coord += cos(mix(vec2(cos(currentStep * 0.50), sin(currentStep * 1.00)), vec2(cos(currentStep * 1.50), sin(currentStep * 2.00)), currentStep) * 0.0020);
				coord += sin(mix(vec2(cos(currentStep * 1.00), sin(currentStep * 2.00)), vec2(cos(currentStep * 3.00), sin(currentStep * 4.00)), currentStep) * 0.0015);
				coord += cos(mix(vec2(cos(currentStep * 1.50), sin(currentStep * 3.00)), vec2(cos(currentStep * 4.50), sin(currentStep * 6.00)), currentStep) * 0.0010);
			}

			float noise = RiftSample(coord, wind, VoU);

			#ifdef NEBULA_STARS
			vec3 planeCoordstar = wpos / (wpos.y + length(wpos.xz));
			vec2 starcoord = planeCoordstar.xz * 0.4 + cameraPosition.xz * 0.0001 + wind * 0.00125;
			starcoord = floor(starcoord * 1024.0) / 1024.0;
			
			float multiplier = sqrt(sqrt(VoU)) * (1.0 - rainStrength) * STARS_AMOUNT;
			
			float star = 1.0;

			if (VoU > 0.0) {
				star *= GetNoise(starcoord.xy);
				star *= GetNoise(starcoord.xy + 0.10);
				star *= GetNoise(starcoord.xy + 0.23);
			}

			star = clamp(star - 0.7125, 0.0, 1.0) * multiplier * 2;
			star * vec3(0.75, 0.85, 1.00);
			star *= STARS_BRIGHTNESS * 128;
			#endif
			
			if (noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.25 + wind * 0.25).b;
				noise *= 1.0 * texture2D(noisetex, coord + wind * 16.0).b + 0.75;
				noise = noise * noise * 4 * sampleStep;
				noise *= max(sqrt(1.0 - length(planeCoord.xz) * 2.5), 0.0);
				if (riftType == 0){
					#if defined END
					riftColor = mix(riftLowCol, riftHighCol, pow(currentStep, 0.4)) * vec3(END_R * 8.0, END_G * 0.5, END_B * 4.0) * 0.25;
					#elif defined OVERWORLD
					riftColor = mix(riftLowCol, riftHighCol, pow(currentStep, 0.4));
					#elif defined NETHER
					riftColor = mix(netherCol.rgb, netherCol.rgb, pow(currentStep, 0.4)) * 0.4;
					#endif
				}else{
					#if defined END
					riftColor = mix(secondRiftLowCol, secondRiftHighCol, pow(currentStep, 0.4)) * vec3(END_R * 10.0, END_G * 0.25, END_B * 6.0) * 0.50;
					#elif defined OVERWORLD
					riftColor = mix(secondRiftLowCol, secondRiftHighCol, pow(currentStep, 0.4));
					#elif defined NETHER
					riftColor = mix(netherCol.rgb, netherCol.rgb, pow(currentStep, 0.4));
					#endif
				}
				#ifndef NETHER
				riftColor += star;
				#endif
				rift += noise * riftColor * exp2(-4.0 * i * sampleStep);
			}
			currentStep += sampleStep;
		}
	}

	return rift * NEBULA_BRIGHTNESS * visFactor;
}