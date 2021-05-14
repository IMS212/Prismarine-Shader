const float pi = radians(180.0);
#define _pow2(x) ((x)*(x))
#define _rcp(x) (1.0 / (x))
#define sstep(x, low, high) smoothstep(low, high, x)
#define saturate(x) clamp(x, 0.0, 1.0)

float rcp(float x) {
    return _rcp(x);
}

vec2 rcp(vec2 x) {
    return _rcp(x);
}

vec3 rcp(vec3 x) {
    return _rcp(x);
}

float pow2(float x) {
    return x*x;
}

vec2 pow2(vec2 x) {
    return x*x;
}

vec3 pow2(vec3 x) {
    return x*x;
}