#include "/lib/color/auroraColor.glsl"

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
	float multiplier = sqrt(sqrt(VoU)) * 5.0 * (1.0 - rainStrength) * STARS_AMOUNT;
	
	float star = 1.0;
	if (VoU > 0.0) {
		star *= GetNoise(coord.xy);
		star *= GetNoise(coord.xy + 0.10);
		star *= GetNoise(coord.xy + 0.23);
	}
	star = clamp(star - 0.7125, 0.0, 1.0) * multiplier;
	
	#ifdef DAY_STARS
	color += star * pow(lightNight, vec3(0.8));
	#else
	if (moonVisibility > 0.0) color += star * pow(lightNight, vec3(0.8));
	#endif

	#ifdef END
	color += star * pow(lightNight * 16, vec3(0.8));
	#endif

	color *= STARS_BRIGHTNESS;
}

void DrawBigStars(inout vec3 color, vec3 viewPos) {
	vec3 wpos = vec3(gbufferModelViewInverse * vec4(viewPos, 1.0));
	vec3 planeCoord = wpos / (wpos.y + length(wpos.xz));
	vec2 wind = vec2(frametime, 0.0);
	vec2 coord = planeCoord.xz * 1.2 + cameraPosition.xz * 0.0001 + wind * 0.00125;
	coord = floor(coord * 1024.0) / 1024.0;
	
	float VoU = clamp(dot(normalize(viewPos), normalize(upVec)), 0.0, 1.0);
	float multiplier = sqrt(sqrt(VoU)) * 3.0 * (1.0 - rainStrength) * STARS_AMOUNT;
	
	float star = 1.0;
	if (VoU > 0.0) {
		star *= GetNoise(coord.xy);
		star *= GetNoise(coord.xy + 0.10);
		star *= GetNoise(coord.xy + 0.20);
	}
	star = clamp(star - 0.7125, 0.0, 1.0) * multiplier;
		
	#ifdef DAY_STARS
	color += star * pow(lightNight, vec3(0.8));
	#else
	if (moonVisibility > 0.0) color += star * pow(lightNight, vec3(0.8));
	#endif

	#ifdef END
	color += star * pow(lightNight * 16 * endCol.rgb, vec3(1.0));
	#endif
}

#ifdef END
float CloudSample(vec2 coord, vec2 wind, float currentStep, float sampleStep, float sunCoverage) {
	float noiseCoverage = abs(currentStep - 0.125) * (currentStep > 0.125 ? 1.12 : 4.0);
	noiseCoverage = noiseCoverage * noiseCoverage * 4.0;
	float noise = texture2D(noisetex, coord*1        + wind * 0.55).x;
		  noise+= texture2D(noisetex, coord*0.5      + wind * 0.45).x * -2.0;
		  noise+= texture2D(noisetex, coord*0.25     + wind * 0.35).x * 2.0;
		  noise+= texture2D(noisetex, coord*0.125    + wind * 0.25).x * 5.0;
		  noise+= texture2D(noisetex, coord*0.0625   + wind * 0.15).x * 9.0;
		  noise+= texture2D(noisetex, coord*0.03125  + wind * 0.05).x * 10.0;
		  noise+= texture2D(noisetex, coord*0.015625 + wind * 0.05).x * -12.0;
	noise = (noise * 0.7) - p2(p4(noiseCoverage)) + p3(rainStrength) + timeBrightness;
	float multiplier = (CLOUD_THICKNESS * 1.5) * sampleStep * (1.0 - 0.75 * rainStrength);

	noise = max(noise - (sunCoverage * 3.0 + CLOUD_AMOUNT), 0.0) * multiplier;
	noise = noise / pow(pow(noise, 2.5) + 1.0, 0.4);

	return noise;
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol) {
	dither *= 0.25;

	int samples = CLOUDS_NOISE_SAMPLES;
	
	float cloud = 0.0, cloudLighting = 0.0;

	float sampleStep = 1.2 / samples;
	float currentStep = dither * sampleStep;
	
	float brightness = CLOUD_BRIGHTNESS - rainStrength;
	if (CLOUD_BRIGHTNESS == 1) brightness = 1;
	float VoS = dot(normalize(viewPos), sunVec);
	float VoU = dot(normalize(viewPos), upVec);
	float VoL = dot(normalize(viewPos), lightVec);
	float cloudHeightFactor = x2(max(1.2 - 0.002 * CLOUDS_HEIGHT_FACTOR * cameraPosition.y, 0.0));
	float cloudHeight = CLOUD_HEIGHT * cloudHeightFactor * CLOUD_HEIGHT_MULTIPLIER * 0.05;
	float sunCoverage = pow(clamp(abs(VoL) * 2.0 - 1.0, 0.0, 1.0), 12.0) * (1.0 - rainStrength);

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.0005,
		sin(frametime * CLOUD_SPEED * 0.004) * 0.006
	) * CLOUD_HEIGHT / 15.0;

	vec3 cloudColor = vec3(0.0);

	if (VoU > 0.025) {
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < samples; i++) {
			float iDither = i + dither;
			vec3 planeCoord = wpos * ((cloudHeight + currentStep * 1.5) / wpos.y) * CLOUD_VERTICAL_THICKNESS * 16;
			vec2 coord = cameraPosition.xz * 0.0003 + planeCoord.xz;
				 coord += cos(mix(vec2(cos(iDither * 0.75), sin(iDither * 1.75)), vec2(cos(iDither * 2.75), sin(iDither * 3.75)), iDither) * 0.0015);
				 coord += sin(mix(vec2(cos(iDither * 1.75), sin(iDither * 2.75)), vec2(cos(iDither * 3.25), sin(iDither * 4.75)), iDither) * 0.0010);
				 coord += cos(mix(vec2(cos(iDither * 2.75), sin(iDither * 3.75)), vec2(cos(iDither * 4.25), sin(iDither * 5.75)), iDither) * 0.0005);
			float noise = CloudSample(coord, wind, currentStep, sampleStep, sunCoverage);

			float halfVoL = VoL * shadowFade * 0.5 + 0.5;
			float halfVoLSqr = halfVoL * halfVoL;
			float noiseLightFactor = (2.0 - 1.5 * VoL * shadowFade) * CLOUD_THICKNESS / 2.0;
			float sampleLighting = pow(currentStep, 1.125 * halfVoLSqr + 0.875) * 0.8 + 0.2;
			sampleLighting *= 1.0 - pow(noise, noiseLightFactor);

			cloudLighting = mix(cloudLighting, sampleLighting, noise * (1.0 - cloud * cloud));
			cloud = mix(cloud, 1.0, noise);

			currentStep += sampleStep;
		}	

		cloudColor = mix(
			cloudambientEnd * (0.35 * sunVisibility + 0.5) * 0.25,
			cloudlightEnd * 2,
			cloudLighting
		);

		cloudColor *= 1.0 - 0.6 * rainStrength;
		cloud *= clamp(1.0 - exp(-20.0 * VoU + 0.5), 0.0, 1.0) * (1.0 - 0.6 * rainStrength);
	}
	cloudColor *= brightness * (0.5 - 0.25 * (1.0 - sunVisibility) * (1.0 - rainStrength));
	
	return vec4(cloudColor, cloud * cloud * CLOUD_OPACITY);
}
#endif

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
			coord += vec2(coord.y, -coord.x) * 0.3;

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
	float noise = texture2D(noisetex, coord * 0.5000  + wind * 0.20).b;
		  noise = texture2D(noisetex, coord * 0.2500  + wind * 0.15).b;
		  noise+= texture2D(noisetex, coord * 0.1250  + wind * 0.10).b;
		  noise+= texture2D(noisetex, coord * 0.0625  + wind * 0.05).b;	
		  noise+= texture2D(noisetex, coord * 0.03125).b;
		  noise+= texture2D(noisetex, coord * 0.01575).b;
		  noise+= texture2D(noisetex, coord * 0.007150).b;
	noise = max(1.0 - 2.0 * (0.5 * VoU + 0.5) * abs(noise - 4), 0.0);

	return noise;
}

vec3 DrawRift(vec3 viewPos, float dither, int samples, float riftType) {
	dither *= 0.25;

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
			vec3 planeCoord = wpos * ((0.0 + currentStep * 16.0)) * 0.00175;

			float iDither = i + dither;
			vec2 coord = cameraPosition.xz * 0.00006 + planeCoord.xz;

			if (riftType == 0){
				coord += vec2(coord.y, -coord.x) * 0.75;
				coord += cos(mix(vec2(cos(iDither * 1), sin(iDither * 2.00)), vec2(cos(iDither * 3.0), sin(iDither * 4.00)), iDither) * 0.0015);
				coord += sin(mix(vec2(cos(iDither * 2), sin(iDither * 2.50)), vec2(cos(iDither * 3.0), sin(iDither * 3.50)), iDither) * 0.0005);
				coord += cos(mix(vec2(cos(iDither * 3), sin(iDither * 3.75)), vec2(cos(iDither * 4.5), sin(iDither * 5.25)), iDither) * 0.0010);
			}else{
				coord += vec2(coord.y, -coord.x) * 1.25;
				coord += cos(mix(vec2(cos(iDither * 0.50), sin(iDither * 1.00)), vec2(cos(iDither * 1.50), sin(iDither * 2.00)), iDither) * 0.0025);
				coord += sin(mix(vec2(cos(iDither * 1.00), sin(iDither * 2.00)), vec2(cos(iDither * 3.00), sin(iDither * 4.00)), iDither) * 0.0015);
				coord += cos(mix(vec2(cos(iDither * 1.50), sin(iDither * 3.00)), vec2(cos(iDither * 4.50), sin(iDither * 6.00)), iDither) * 0.0005);
			}

			float noise = RiftSample(coord, wind, VoU);
			
			if (noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.25 + wind * 0.25).b;
				noise *= 1.0 * texture2D(noisetex, coord + wind * 16.0).b + 0.75;
				noise = noise * noise * 4 * sampleStep;
				noise *= max(sqrt(1.0 - length(planeCoord.xz) * 2.5), 0.0);
				if (riftType == 0){
					#if defined END
					riftColor = mix(riftLowCol, riftHighCol, pow(currentStep, 0.4)) * vec3(END_R * 6.0, END_G * 0.5, END_B * 2.0);
					#elif defined OVERWORLD
					riftColor = mix(riftLowCol, riftHighCol, pow(currentStep, 0.4)) * 0.5;
					#elif defined NETHER
					riftColor = mix(netherCol.rgb, netherCol.rgb, pow(currentStep, 0.4)) * 0.4;
					#endif
				}else{
					#if defined END
					riftColor = mix(secondRiftLowCol, secondRiftHighCol, pow(currentStep, 0.4)) * vec3(END_R * 6.0, END_G * 0.5, END_B * 2.0);
					#elif defined OVERWORLD
					riftColor = mix(secondRiftLowCol, secondRiftHighCol, pow(currentStep, 0.4)) * 0.25;
					#elif defined NETHER
					riftColor = mix(netherCol.rgb, netherCol.rgb, pow(currentStep, 0.4));
					#endif
				}
				rift += noise * riftColor * exp2(-4.0 * i * sampleStep);
			}
			currentStep += sampleStep;
		}
	}

	return rift * (moonVisibility - rainStrength);
}