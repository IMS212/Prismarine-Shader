const float pi = 3.1415926535;

#define pow2(x) (x * x)
#define x2(x) (x * x)
#define x3(x) (x * x * x)
#define x4(x) (x * x * x * x)

#define d2(x) (x - x)
#define d3(x) (x - x - x)
#define d4(x) (x - x - x - x)

#define s2(x) (x + x)
#define s3(x) (x + x + x)
#define s4(x) (x + x + x + x)

#define ss(x, y, z) smoothstep(y, z, x)
#define sat(x) clamp(x, 0, 1)