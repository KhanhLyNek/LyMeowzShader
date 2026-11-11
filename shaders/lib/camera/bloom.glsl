// High quality bloom - dual filter method
//https://zhuanlan.zhihu.com/p/525500877

// GoldenSpring bloom system
vec2 samplingOffset[7] = vec2[](
    vec2(0.0, 0.0),
    vec2(0.35, 0.0),
    vec2(0.575, 0.0),
    vec2(0.7375, 0.0),
    vec2(0.86875, 0.0),
    vec2(0.0, 0.35),
    vec2(0.1078125, 0.35)
);

vec3 downSampling(float lod){
    float scale = exp2(lod);
    vec2 newUV = (texcoord - samplingOffset[int(lod - 2)]) * scale; 
    if(outScreen(newUV)) return BLACK;
    // return filter5_22(colortex0, newUV, scale, lod);
    return gaussianBlur6x6(colortex0, newUV, scale, lod).rgb;
}

vec3 horizontalDownSampling(float lod){
    float scale = exp2(lod);
    vec2 newUV = (texcoord - samplingOffset[int(lod - 2)]) * scale; 
    if(outScreen(newUV)) return BLACK;
    return gaussianBlur6x1(colortex0, newUV, scale, lod).rgb;
}

vec3 upSampling(float lod){
    float scale = exp2(-lod);
    vec2 newUV = texcoord * scale + samplingOffset[int(lod - 2)];
    return textureBicubic(colortex1, newUV).rgb;
}