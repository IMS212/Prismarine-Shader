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

float adj(float x, float y){
    float f = x * y;
    float s = x * (y + y);
    float t = x * (y + y + y);
    return (f + s + t);
}