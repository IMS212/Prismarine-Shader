vec3 RiftLowColSqrt = vec3(RIFT_LR, RIFT_LG, RIFT_LB) * RIFT_LI / 255.0;
vec3 riftLowCol = RiftLowColSqrt * RiftLowColSqrt;
vec3 RiftHighColSqrt = vec3(RIFT_HR, RIFT_HG, RIFT_HB) * RIFT_HI / 255.0;
vec3 riftHighCol = RiftHighColSqrt * RiftHighColSqrt;

vec3 auroraLowColSqrt = vec3(AURORA_LR, AURORA_LG, AURORA_LB) * AURORA_LI / 255.0;
vec3 auroraLowCol = auroraLowColSqrt * auroraLowColSqrt;
vec3 auroraHighColSqrt = vec3(AURORA_HR, AURORA_HG, AURORA_HB) * AURORA_HI / 255.0;
vec3 auroraHighCol = auroraHighColSqrt * auroraHighColSqrt;