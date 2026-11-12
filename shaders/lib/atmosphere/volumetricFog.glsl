// Suong mu the tich (volumetric fog) - viet rieng cho LyMeowz Shader.
// Y tuong tham khao: Bliss shader (suong theo gio trong ngay, dam suong tung dam, tia sang xuyen suong).
// Ray-march doc tia nhin, mat do suong theo do cao + noise, anh sang mat troi lay tu shadow map.
#define VOLUMETRIC_FOG
#define VFOG_SAMPLES 8              // [4 6 8 10 12 16]
#define VFOG_DENSITY 1.0            // [0.25 0.5 0.75 1.0 1.5 2.0 3.0]
#define VFOG_START_HEIGHT 63.0      // [0.0 32.0 48.0 56.0 63.0 70.0 80.0 100.0]
#define VFOG_HEIGHT_FALLOFF 20.0    // [8.0 12.0 16.0 20.0 30.0 40.0 60.0]
#define VFOG_PATCHY 0.6             // [0.0 0.2 0.4 0.6 0.8 1.0]
#define VFOG_LIGHTSHAFTS 1.0        // [0.0 0.5 1.0 1.5 2.0]
#define VFOG_MORNING 1.0            // [0.0 0.1 0.25 0.5 0.75 1.0 1.5 2.0]
#define VFOG_NOON 0.15              // [0.0 0.05 0.1 0.15 0.25 0.5 0.75 1.0]
#define VFOG_EVENING 0.5            // [0.0 0.1 0.25 0.5 0.75 1.0 1.5 2.0]
#define VFOG_NIGHT 0.3              // [0.0 0.1 0.25 0.3 0.5 0.75 1.0]
#define VFOG_RAIN 1.0               // [0.0 0.5 1.0 1.5 2.0]
#define VFOG_MAX_DISTANCE 192.0     // [64.0 96.0 128.0 192.0 256.0]

#ifdef VOLUMETRIC_FOG

varying float vfogTimeMult;

// He so suong theo gio trong ngay (sang/trua/chieu/toi), tinh tu vi tri mat troi (world space)
float vfogTimeOfDay(vec3 sunDirW){
    float e = sunDirW.y;
    float east = smoothstep(-0.05, 0.15, sunDirW.x);   // mat troi moc phia dong (+x) = buoi sang
    float dawnDusk = mix(VFOG_EVENING, VFOG_MORNING, east);
    float day = mix(dawnDusk, VFOG_NOON, smoothstep(0.1, 0.5, e));
    return mix(VFOG_NIGHT, day, smoothstep(-0.15, 0.05, e));
}

// Noise 2D lap lai, cho dam suong
float vfogNoise(vec3 p){
    vec2 uv = (p.xz + p.y * vec2(0.17, 0.31)) / (noiseTextureResolution * 6.0);
    uv += frameTimeCounter * vec2(0.0006, 0.0003);
    float n1 = texture(noisetex, uv).r;
    float n2 = texture(noisetex, uv * 3.1 + 0.37).r;
    return n1 * 0.7 + n2 * 0.3;
}

// Mat do suong tai mot diem (world space, y la toa do the gioi)
float vfogDensity(vec3 p, float timeMult){
    float h = max(p.y - VFOG_START_HEIGHT, 0.0);
    float base = exp(-h / VFOG_HEIGHT_FALLOFF);

    float clump = smoothstep(0.45, 0.8, vfogNoise(p)) * exp(-max(h - 12.0, 0.0) * 0.05);
    float patchy = mix(1.0, 0.4 + 2.2 * clump, VFOG_PATCHY);

    float rain = rainStrength * VFOG_RAIN * exp(-h / (VFOG_HEIGHT_FALLOFF * 1.5)) * 1.5;

    return 0.006 * VFOG_DENSITY * (timeMult * base * patchy + rain);
}

// color: mau canh (HDR) truoc suong; dist: khoang cach toi diem (block); worldDir: huong nhin (world)
vec3 applyVolumetricFog(vec3 color, float dist, vec3 worldDir, float dither, float timeMult, vec3 lightDirW, vec3 sunCol, vec3 skyCol){
    float tMax = min(dist, VFOG_MAX_DISTANCE);

    // chi co suong khi camera o ngoai troi (khong ap vao hang dong)
    float outdoors = smoothstep(0.2, 0.9, float(eyeBrightnessSmooth.y) / 240.0);

    const float expF = 8.0;
    float N = float(VFOG_SAMPLES);

    float cosVL = dot(worldDir, lightDirW);
    float phase = hgPhase1(cosVL, 0.6);
    vec3 ambient = skyCol * 1.2;
    vec3 sunL = sunCol * phase * 1.2;

    float T = 1.0;
    vec3 S = vec3(0.0);

    for(int i = 0; i < VFOG_SAMPLES; i++){
        float u = (float(i) + dither) / N;
        float t = tMax * (pow(expF, u) - 1.0) / (expF - 1.0);
        float dt = tMax * pow(expF, u) * log(expF) / ((expF - 1.0) * N);

        vec3 pRel = worldDir * t;
        vec3 pW = pRel + cameraPosition;

        float rho = vfogDensity(pW, timeMult) * outdoors;
        if(rho < 1e-6) continue;

        float vis = 1.0;
        if(VFOG_LIGHTSHAFTS > 0.0 && t < shadowDistance){
            vec3 sp = getShadowPos(vec4(pRel, 1.0)).xyz;
            float s = texture(shadowtex0, sp).r;
            vis = pow(s, VFOG_LIGHTSHAFTS);
        }

        vec3 L = ambient + sunL * vis;
        float absorb = exp(-rho * dt);
        S += L * (1.0 - absorb) * T;
        T *= absorb;
    }

    return color * T + S;
}

#endif
