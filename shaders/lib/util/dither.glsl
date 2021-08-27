

float Bayer2(vec2 a) {
    a = floor(a);

    return fract(dot(a, vec2(0.5, a.y * 0.75)));
}

float Bayer4(const vec2 a)   { return Bayer2 (0.5   * a) * 0.25     + Bayer2(a); }
float Bayer8(const vec2 a)   { return Bayer4 (0.5   * a) * 0.25     + Bayer2(a); }
float Bayer16(const vec2 a)  { return Bayer4 (0.25  * a) * 0.0625   + Bayer4(a); }
float Bayer32(const vec2 a)  { return Bayer8 (0.25  * a) * 0.0625   + Bayer4(a); }
float Bayer64(const vec2 a)  { return Bayer8 (0.125 * a) * 0.015625 + Bayer8(a); }
float Bayer128(const vec2 a) { return Bayer16(0.125 * a) * 0.015625 + Bayer8(a); }
float Bayer256(const vec2 a) { return Bayer16(0.125 * a) * 0.015625 + Bayer8(a); }