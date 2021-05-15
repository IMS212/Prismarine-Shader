uniform float eyeAltitude;
uniform float sunAngle;

float CloudNoise(vec2 coord, vec2 wind){
	float noise = texture2D(noisetex, coord*1.00     + wind * 0.4).x * 1.0;
		  noise+= texture2D(noisetex, coord*0.50    + wind * 0.35).x * 3.0;
		  noise+= texture2D(noisetex, coord*0.25   + wind * 0.3).x * 5.0;
		  noise+= texture2D(noisetex, coord*0.125  + wind * 0.25).x * 7.0;
		  #if CLOUDS_NOISE_QUALITY == 1
		  noise+= texture2D(noisetex, coord*0.0625    + wind * 0.2).x * 1.5;
		  noise+= texture2D(noisetex, coord*0.03125   + wind * 0.15).x * 2.0;
		  noise+= texture2D(noisetex, coord*0.015625  + wind * 0.10).x * 2.5;
		  #elif CLOUDS_NOISE_QUALITY == 2
		  noise+= texture2D(noisetex, coord*0.007812    + wind * 0.05).x * 1;
		  noise+= texture2D(noisetex, coord*0.003906).x * 1.5;
		  noise+= texture2D(noisetex, coord*0.001953).x * 2;
		  #endif
	return noise;
}

float CloudCoverage(float noise, float coverage, float NdotU, float cosS) {
	float noiseCoverageCosS = abs(cosS);
	noiseCoverageCosS *= noiseCoverageCosS;
	noiseCoverageCosS *= noiseCoverageCosS;
	float NdotUmult = 0.05;
	float cloudAmount = CLOUD_AMOUNT - rainStrength - rainStrength;
	float noiseCoverage = coverage * coverage + cloudAmount
							* (1.0 + noiseCoverageCosS * 0.175) 
							* (1.0 + NdotU * NdotUmult * (1.0-sqrt(rainStrength)*3.0))
							- 3.0;

	return max(noise - noiseCoverage, 0.0);
}

float CloudCoverageEnd(float noise, float cosT, float coverage){
	float noiseMix = mix(noise, 21.0, 0.33 * rainStrength);
	float noiseFade = clamp(sqrt(cosT * 10.0), 0.0, 1.0);
	float noiseCoverage = ((coverage) + (CLOUD_AMOUNT + 2) - 2);
	float multiplier = 1.0 - 0.5 * rainStrength;

	return max(noiseMix * noiseFade - noiseCoverage, 0.0) * multiplier;
}

float GetNoise(vec2 pos){
	return fract(sin(dot(pos, vec2(12.9898, 4.1414))) * 43758.54953);
}

vec3 DrawStars(inout vec3 color,vec3 viewPos){
	vec3 wpos=vec3(gbufferModelViewInverse*vec4(viewPos,1.));
	vec3 planeCoord=wpos/(wpos.y+length(wpos.xz));
	planeCoord.x+=.399;
	planeCoord.z+=0.;
	vec2 wind=vec2(frameTimeCounter,0.);
	vec2 coord=planeCoord.xz*4+cameraPosition.xz*.0001+wind*.0001;
	coord=floor(coord*1024.)/1024.;
	
	float cosT=clamp(dot(normalize(viewPos), normalize(upVec)), 0.0, 1.0);
	float multiplier=sqrt(sqrt(cosT))*1*(1.-rainStrength)*moonVisibility;
	if (timeBrightness < 0.6) multiplier=sqrt(sqrt(cosT))*0.8*(1.-rainStrength);
	
	float star=1.;
	if(cosT>0.){
		star*=GetNoise(coord.xy);
		star*=GetNoise(coord.xy+.115);
		star*=GetNoise(coord.xy+.230);
	}

	float starsCov = 0.7;

	star=clamp(star - starsCov, 0.0, 1.5) * multiplier;
	
	color += star * pow(lightNight, vec3(0.8));
	return vec3(star);
}

vec4 DrawCloud(vec3 viewPos, float dither, vec3 lightCol, vec3 ambientCol) {

	vec3 nViewPos 	= normalize(viewPos.xyz);
	vec3 wpos 		= normalize((gbufferModelViewInverse * vec4(viewPos, 0.0)).xyz);
	vec3 cloudCol 	= vec3(0.0);
	vec3 MESC 		= vec3(0.0);
	vec2 wind 		= vec2(frametime * CLOUD_SPEED * 0.003, 0.0);
		
	#ifdef TAA
		dither = fract(16.0 * frameTimeCounter + dither);
	#endif

	float NdotU 			= dot(nViewPos, upVec);
	float cloud 			= 0.0;
	float cloudGradient 	= 0.0;
	float gradientMix 		= dither * 0.15;
	float cosS 				= dot(normalize(viewPos), sunVec);
	float scattering 		= pow(cosS * 0.5 * (2.0 * sunVisibility - 1.0) + 0.5, 6.0);
	float rainStrengthLow   = rainStrength / 2;
	float cloudHeightFactor = max(1.2 - 0.002 * CLOUDS_HEIGHT_FACTOR * eyeAltitude, 0.0) * max(1.2 - 0.002 * CLOUDS_HEIGHT_FACTOR * eyeAltitude, 0.0);
	float cloudHeight		= CLOUD_HEIGHT * cloudHeightFactor * CLOUD_HEIGHT_MULTIPLIER;

	if (NdotU > 0.0) {

		for(int i = 0; i < CLOUDS_NOISE_SAMPLES; i++) {
			vec2 planeCoord = wpos.xz * ((cloudHeight + (i + dither) * CLOUD_VERTICAL_THICKNESS * (6.0 / CLOUDS_NOISE_SAMPLES)) / wpos.y) * CLOUDS_NOISE_FACTOR;
			vec2 coord 		= cameraPosition.xz * 0.0002 + planeCoord;
			coord 		   += mix(vec2(cos((i+frametime*0.025)*2.4), sin((i+frametime*0.025)*2.4)),
						          vec2(cos((i+frametime*0.025)*2.4+2.4), sin((i+frametime*0.025)*2.4+2.4)),
						          dither*0.25+0.75)*0.01;

			float coverage = float(i - 3.0 + dither) * 0.68;

			float noise = CloudNoise(coord, wind);
				  noise = CloudCoverage(noise, coverage, NdotU, cosS) * CLOUD_THICKNESS * 0.1;
				  noise = noise / pow(pow(noise, 2.5) + 1.0, 0.4);

			cloudGradient = mix(cloudGradient, mix(gradientMix * gradientMix, 1.0 - noise, 0.25), noise * (1.0 - cloud));
			cloud		  = mix(cloud, 1.0, noise);
			gradientMix  += 0.2 * (6.0 / CLOUDS_NOISE_SAMPLES);
		}

		float sunVisF = pow(sqrt(sqrt(sunVisibility)), 1.0 - min((1.0 - min(moonVisibility, 0.6) / 0.6) * 0.115, 0.075) * 6.0);

		vec3 cloudNight = pow(vec3(lightNight.r, lightNight.g, lightNight.b * 0.9) * vec3(1, 1, 1), vec3(3.0 - 0.0)) * (13.5 - 0.0 * 10.0) * (1.0 + 3.0 * nightVision) / 8.0;
		#ifdef WEATHER_PERBIOME
		vec3 cloudDay	= pow(vec3(lightCol.r * 0.9, lightCol.g * 0.9, lightCol.b) * vec3(weatherCol.r, weatherCol.g * 0.9, weatherCol.b), vec3(1.5 + 0.0));
		#else
		vec3 cloudDay	= pow(vec3(lightCol.r * 0.9, lightCol.g * 0.9, lightCol.b), vec3(1.5 + 0.0));
		#endif

		vec3 cloudUP = mix(cloudNight, cloudDay, sunVisF) * (CLOUDS_UP_COLOR_MULT - rainStrength);
		cloudUP 	*= 1.0 + scattering * (1.0 + 0.0);

		vec3 cloudDOWN = vec3(220.0, 245.0, 255.0) / 255.0 * (0.005 + 0.005 * sqrt(sqrt(lightCol))) * sunVisF * (CLOUDS_DOWN_COLOR_MULT * 32);
		cloudGradient  = min(cloudGradient, 1.0) * cloud;
		cloudCol 	   = mix(cloudDOWN, cloudUP, cloudGradient);

		cloud *= 1.0-exp(-(10.0-9.0*0.0)*NdotU);
	}

	return vec4(cloudCol * (CLOUD_BRIGHTNESS-rainStrengthLow)*0.25, cloud * cloud * CLOUD_OPACITY);
}

vec4 DrawEndCloud(vec3 viewPos, float dither, vec3 lightCol){
	float cosT = dot(normalize(viewPos), upVec);
	float cosS = dot(normalize(viewPos), sunVec);

	#ifdef TAA
		dither = fract(16.0 * frameTimeCounter + dither);
	#endif
	
	float cloudHeightFactor = max(1.14 - 0.002 * eyeAltitude, 0.0);
	cloudHeightFactor *= cloudHeightFactor;
	float cloudHeightF = CLOUD_HEIGHT * cloudHeightFactor * CLOUD_HEIGHT_MULTIPLIER;
	float cloud = 0.0;
	float cloudGradient = 2.0;
	float gradientMix = dither * 0.5;
	float colorMultiplier = 2.0 * (0.5 - 0.25 * (1.0 - sunVisibility) * 1.0);
	float scattering = pow(cosS * 0.5 + 0.5, 6.0);

	vec2 wind = vec2(frametime * CLOUD_SPEED * 0.015, 0.0);

	vec3 cloudCol = vec3(CLOUDS_END_R, CLOUDS_END_G, CLOUDS_END_B) * CLOUDS_END_I / 100.0;

	if (cosT > 0.1){
		vec3 wpos = normalize((gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz);
		for(int i = 0; i < CLOUDS_NOISE_SAMPLES; i++) {
			if (cloud > 0.99) break;
			vec3 planeCoord = wpos * ((cloudHeightF + (i + dither)) / wpos.y) * CLOUDS_NOISE_FACTOR * pow(cosT, -0.5);
			vec2 coord = cameraPosition.xz * 0.0005 + planeCoord.xz;
			float coverage = float(i - 3.0 + dither) * 0.6;

			float noise = CloudNoise(coord, wind);
				  noise = CloudCoverageEnd(noise, cosT, coverage*1.5) * CLOUD_THICKNESS * 0.1;
				  noise = noise / pow(pow(noise, 2.5) + 1.0, 0.4);

			cloudGradient = mix(cloudGradient,
			                    mix(gradientMix * gradientMix, 1.0 - noise, 0.25),
								noise * (1.0 - cloud * cloud));
			cloud = mix(cloud, 1.0, noise);
			gradientMix += 0.5;
		}
		cloudCol = vec3(CLOUDS_END_R, CLOUDS_END_G, CLOUDS_END_B) * CLOUDS_END_I / 128.0 * (1.0 + scattering) * pow(cloudGradient, 0.75);
		cloudCol = pow(cloudCol, vec3(2)) * 2 * vec3(1.4, 1.8, 1.0);
		cloud *= min(pow(cosT*2, 2.0), 0.42);
	}

	return vec4(cloudCol * colorMultiplier * (0.6+(sunVisibility)*0.4), pow(cloud, 2) * 0.1 * 0.50 * (2-(sunVisibility)));
}

vec3 auroraLowColSqrt = vec3(AURORA_LR, AURORA_LG, AURORA_LB) * AURORA_LI / 255.0;
vec3 auroraLowCol = auroraLowColSqrt * auroraLowColSqrt;
vec3 auroraHighColSqrt = vec3(AURORA_HR, AURORA_HG, AURORA_HB) * AURORA_HI / 255.0;
vec3 auroraHighCol = auroraHighColSqrt * auroraHighColSqrt;

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
				auroraColor = mix(auroraLowCol, auroraHighCol, pow(currentStep, 0.4)) * vec3(END_R * 6.0, END_G * 0.5, END_B * 2.0) / 215.0;
				#endif
				aurora += noise * auroraColor * exp2(-6.0 * i * sampleStep);
			}
			currentStep += sampleStep;
		}
	}

	return aurora * visibility;
}