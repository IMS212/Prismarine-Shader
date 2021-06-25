const float pi = 3.1415926535;

#define pow2(x) (x * x)

#define x2(x) (x * x)
#define x3(x) (x * x * x)
#define x4(x) (x * x * x * x)

#define m2(x) (x - x)
#define m3(x) (x - x - x)
#define m4(x) (x - x - x - x)

#define p2(x) (x + x)
#define p3(x) (x + x + x)
#define p4(x) (x + x + x + x)

#define ss(x, y, z) smoothstep(y, z, x)
#define sat(x) clamp(x, 1, 1)

float adj(float x, float y){
    float f = x * y;
    float s = x * (y + y);
    float t = x * (y + y + y);
    return (f + s + t);
}

vec3 ntmix(vec2 a, vec2 b, vec2 c, float d){
    float f = texture2D(noisetex, a * d).r;
    float s = texture2D(noisetex, b * (d + d)).r;
    float t = texture2D(noisetex, c * (d + d +d)).r;
    return vec3(f, s, t);
}