//Dithering from Jodie
float BlueDithering() {
    ivec2 coord = ivec2(fract(gl_FragCoord.xy/256.0)*256.0);
    float noise = texture2DLod(noisetex, coord, 0).a;

    #ifdef TAA
        noise   = fract(noise+float(frameTimeCounter)/32);
    #endif

    return noise;
}

float Bayer2(vec2 a) {
    a = floor(a);
    return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

#define Bayer4(a)   (Bayer2(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer8(a)   (Bayer4(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer16(a)  (Bayer8(  0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer32(a)  (Bayer16( 0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer64(a)  (Bayer32( 0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer128(a) (Bayer64( 0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer256(a) (Bayer128(0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer512(a) (Bayer256(0.5 * (a)) * 0.25 + Bayer2(a))
#define Bayer1024(a) (Bayer512(0.5 * (a)) * 0.25 + Bayer2(a))