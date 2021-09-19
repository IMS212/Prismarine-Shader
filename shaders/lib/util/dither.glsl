//technically there's nothing bayer-related, i was just lazy to go to all the files just to replace BayerX with this new thing
float InterleavedGradientNoise(vec2 a) {
	float n = 52.9829189 * fract(0.06711056 * gl_FragCoord.x + 0.00583715 * gl_FragCoord.y);
	return fract(n + frameCounter / 16.0);
}

#define Bayer4(a)   (InterleavedGradientNoise(  0.5 * (a)) * 0.25 + InterleavedGradientNoise(a))
#define Bayer8(a)   (Bayer4(  0.5 * (a)) * 0.25 + InterleavedGradientNoise(a))
#define Bayer16(a)  (Bayer8(  0.5 * (a)) * 0.25 + InterleavedGradientNoise(a))
#define Bayer32(a)  (Bayer16( 0.5 * (a)) * 0.25 + InterleavedGradientNoise(a))
#define Bayer64(a)  (Bayer32( 0.5 * (a)) * 0.25 + InterleavedGradientNoise(a))