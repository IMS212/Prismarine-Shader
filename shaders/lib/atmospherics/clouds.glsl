uniform float eyeAltitude;
uniform float sunAngle;
#include "/lib/color/auroraColor.glsl"
float CloudSample(vec2 coord, vec2 wind, float currentStep, float sampleStep, float sunCoverage) {
	float noiseCoverage = abs(currentStep - 0.125) * (currentStep > 0.125 ? 1.14 : 8.0);
	noiseCoverage = noiseCoverage * noiseCoverage * 4.0;
	float noise = texture2D(noisetex, coord*1        + wind * 0.55).x;
		  noise+= texture2D(noisetex, coord*0.5      + wind * 0.45).x * -2.0;
		  noise+= texture2D(noisetex, coord*0.25     + wind * 0.35).x * 2.0;
		  noise+= texture2D(noisetex, coord*0.125    + wind * 0.25).x * 5.0;
		  noise+= texture2D(noisetex, coord*0.0625   + wind * 0.15).x * 9.0;
		  noise+= texture2D(noisetex, coord*0.03125  + wind * 0.05).x * 10.0;
		  noise+= texture2D(noisetex, coord*0.015625 + wind * 0.05).x * -12.0;
		  noise = noise * 2.5;
		  #if CLOUDS_NOISE_QUALITY == 1
		  noise+= texture2D(noisetex, coord*0.0625    + wind * 0.25).x * 1.5;
		  noise+= texture2D(noisetex, coord*0.03125   + wind * 0.2).x * 2.0;
		  noise+= texture2D(noisetex, coord*0.015625  + wind * 0.15).x * 2.5;
		  noise+= texture2D(noisetex, coord*0.010025  + wind * 0.1).x * 3;
		  #elif CLOUDS_NOISE_QUALITY == 2
		  noise+= texture2D(noisetex, coord*0.0625    + wind * 0.25).x * 1.5;
		  noise+= texture2D(noisetex, coord*0.03125   + wind * 0.2).x * 2.0;
		  noise+= texture2D(noisetex, coord*0.015625  + wind * 0.15).x * 2.5;
		  noise+= texture2D(noisetex, coord*0.010025  + wind * 0.1).x * 3;
		  noise+= texture2D(noisetex, coord*0.007812    + wind * 0.05).x * 3.5;
		  noise+= texture2D(noisetex, coord*0.003906).x * 4;
		  #endif
	noise = noise - noiseCoverage - noiseCoverage + rainStrength + rainStrength + rainStrength + rainStrength;
	float multiplier = CLOUD_THICKNESS * sampleStep * (1.0 - 0.75 * rainStrength + rainStrength);

	noise = max(noise - (sunCoverage * 3.0 + CLOUD_AMOUNT * 1.8), 0.0) * multiplier;
	noise = noise / pow(pow(noise, 2.5) + 1.0, 0.4);

	return noise;
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol) {
	#ifdef TAA
	dither = fract(16.0 * frameTimeCounter + dither);
	#endif

	int samples = CLOUDS_NOISE_SAMPLES;
	
	float cloud = 0.0, cloudLighting = 0.0;

	float sampleStep = 1.0 / samples;
	float currentStep = dither * sampleStep;
	
	float brightness = CLOUD_BRIGHTNESS - rainStrength;
	float VoU = dot(normalize(viewPos), upVec);
	float VoL = dot(normalize(viewPos), lightVec);
	float cloudHeightFactor = max(1.2 - 0.002 * CLOUDS_HEIGHT_FACTOR * eyeAltitude, 0.0) * max(1.2 - 0.002 * CLOUDS_HEIGHT_FACTOR * eyeAltitude, 0.0);
	float cloudHeight = CLOUD_HEIGHT * cloudHeightFactor * CLOUD_HEIGHT_MULTIPLIER;
	float sunCoverage = pow(clamp(abs(VoL) * 2.0 - 1.0, 0.0, 1.0), 12.0) * (1.0 - rainStrength);

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.0003,
		sin(frametime * CLOUD_SPEED * 0.001) * 0.004
	) * CLOUD_HEIGHT / 15.0;

	vec3 cloudColor = vec3(0.0);

	if (VoU > 0.025) {
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < samples; i++) {
			if (cloud > 0.99) break;
			vec3 planeCoord = wpos * ((cloudHeight + currentStep * 4.0) / wpos.y) * CLOUD_VERTICAL_THICKNESS;
			vec2 coord = cameraPosition.xz * 0.0001 + planeCoord.xz;

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
		float scattering = pow(VoL * shadowFade * 0.5 + 0.5, 6.0);
		cloudLighting = mix(cloudLighting, 1.0, (1.0 - cloud * cloud) * scattering * 0.5);
		cloudColor = mix(
			ambientCol * (0.15 * sunVisibility + 0.5),
			cloudCol * (0.85 + 1.15 * scattering),
			cloudLighting
		);
		#ifdef END
		vec4 endCColSqrt = vec4(vec3(CLOUDS_END_R, CLOUDS_END_G, CLOUDS_END_B) / 255.0, 1.0) * CLOUDS_END_I;
		vec4 endCCol = endCColSqrt * endCColSqrt;
		vec3 cloudColor = pow(endCCol.rgb * scattering * 2, vec3(1.5));
		#endif
		cloudColor *= 1.0 - 0.6 * rainStrength;
		cloud *= clamp(1.0 - exp(-20.0 * VoU + 0.5), 0.0, 1.0) * (1.0 - 0.6 * rainStrength);
	}
	cloudColor *= CLOUD_BRIGHTNESS * (0.5 - 0.25 * (1.0 - sunVisibility) * (1.0 - rainStrength));
	if (cameraPosition.y < 1.0) cloudColor *= exp(2.0 * cameraPosition.y - 2.0);
	
	return vec4(cloudColor, cloud * cloud * (CLOUD_OPACITY + rainStrength));
}


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
	float multiplier = sqrt(sqrt(VoU)) * 5.0 * (1.0 - rainStrength) * moonVisibility;
	
	float star = 1.0;
	if (VoU > 0.0) {
		star *= GetNoise(coord.xy);
		star *= GetNoise(coord.xy + 0.10);
		star *= GetNoise(coord.xy + 0.23);
	}
	star = clamp(star - 0.8125, 0.0, 1.0) * multiplier;

	if (cameraPosition.y < 1.0) star *= exp(2.0 * cameraPosition.y - 2.0);
		
	color += star * pow(lightNight, vec3(0.8));
}

float AuroraSample(vec2 coord, vec2 wind, float VoU) {
	float noise = texture2D(noisetex, coord * 0.0625  + wind * 0.25).b * 3.0;
		  noise+= texture2D(noisetex, coord * 0.03125 + wind * 0.15).b * 3.0;

	noise = max(1.0 - 4.0 * (0.5 * VoU + 0.5) * abs(noise - 3.0), 0.0);

	return noise;
}

vec3 DrawAurora(vec3 viewPos, float dither, int samples) {
	#ifdef TAA
		dither = fract(16.0 * frameTimeCounter + dither);
	#endif
	
	float sampleStep = 1.0 / samples;
	float currentStep = dither * sampleStep;

	float VoU = dot(normalize(viewPos), upVec);

	float visibility = moonVisibility * (1.0 - rainStrength) * (1.0 - rainStrength);

	#if	(defined WEATHER_PERBIOME && SKY_MODE == 1) || (defined WEATHER_PERBIOME && SKY_MODE == 2) || SKY_MODE == 2
	visibility *= isCold * isCold;
	#else
	visibility = 0.0;
	#endif

	#ifdef END
	visibility = 1.0;
	#endif

	vec2 wind = vec2(
		frametime * CLOUD_SPEED * 0.000525,
		sin(frametime * CLOUD_SPEED * 0.05) * 0.00125
	);

	vec3 aurora = vec3(0.0);

	if (VoU > 0.0 && visibility > 0.0) {
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < samples; i++) {
			vec3 planeCoord = wpos * ((8.0 + currentStep * 7.0) / wpos.y) * 0.006;

			vec2 coord = cameraPosition.xz * 0.00008 + planeCoord.xz;
			coord += vec2(coord.y, -coord.x) * 1.0;

			float noise = AuroraSample(coord, wind, VoU);
			
			if(noise > 0.0) {
				noise *= texture2D(noisetex, coord * 0.125 + wind * 0.25).b;
				noise *= 1.0 * texture2D(noisetex, coord + wind * 16.0).b + 0.75;
				noise = noise * noise * 1.5 * sampleStep;
				noise *= max(sqrt(1.0 - length(planeCoord.xz) * 2.75), 0.0);

				vec3 auroraColor = mix(auroraLowCol, auroraHighCol, pow(currentStep, 0.4));
				#ifdef END
				auroraColor = mix(auroraLowCol, auroraHighCol, pow(currentStep, 0.4)) * vec3(END_R * 6.0, END_G * 0.5, END_B * 2.0) / 16;
				#endif
				aurora += noise * auroraColor * exp2(-6.0 * i * sampleStep);
			}
			currentStep += sampleStep;
		}
	}

	return aurora * visibility;
}