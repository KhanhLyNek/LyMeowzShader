// Suong mu buoi sang / suong mu theo do cao (viet rieng cho LyMeowz Shader)
// Y tuong: suong day nhat sat mat dat vao luc binh minh (mat troi moc phia dong), nhat dan khi mat troi len cao.
#define MORNING_MIST
#define MORNING_MIST_DENSITY 1.0    // [0.25 0.5 0.75 1.0 1.5 2.0 2.5 3.0 4.0]
#define MORNING_MIST_HEIGHT 24.0    // [8.0 12.0 16.0 24.0 32.0 48.0 64.0 96.0]
#define MORNING_MIST_BASE_Y 62.0    // [0.0 32.0 48.0 56.0 62.0 70.0 80.0 100.0 128.0]
#define MORNING_MIST_DAYTIME 0.15   // [0.0 0.05 0.1 0.15 0.2 0.3 0.4 0.5]
#define MORNING_MIST_EVENING 0.5    // [0.0 0.25 0.5 0.75 1.0]
#define MORNING_MIST_RAIN 0.5       // [0.0 0.25 0.5 0.75 1.0]

#ifdef MORNING_MIST

varying float mistAmount;

// Muc do suong theo vi tri mat troi (world space) va mua
float mistAmountFromSun(vec3 sunDirW){
    float e = sunDirW.y;
    // cua so binh minh/hoang hon: mat troi gan chan troi
    float window = smoothstep(-0.12, 0.06, e) * (1.0 - smoothstep(0.12, 0.55, e));
    // mat troi moc o phia dong (+x) -> sang; phia tay (-x) -> chieu toi (giam bot)
    float east = smoothstep(-0.05, 0.15, sunDirW.x);
    window *= mix(MORNING_MIST_EVENING, 1.0, east);
    // suong mong ca ngay
    float haze = MORNING_MIST_DAYTIME * smoothstep(0.0, 0.3, e);
    // mua cung tao suong
    float rain = MORNING_MIST_RAIN * rainStrength * smoothstep(-0.15, 0.1, e);
    return max(max(window, haze), rain);
}

float mistDensityAt(float h, float a){
    return a * exp(-max(h, 0.0) / MORNING_MIST_HEIGHT);
}

// Ap suong len mau: dist = khoang cach tu camera (block), worldDir = huong nhin (world space)
vec3 applyMist(vec3 color, float dist, vec3 worldDir, float amount, float skyExposure, vec3 lightDirW, vec3 sunCol, vec3 skyCol){
    float a = 0.012 * MORNING_MIST_DENSITY * amount;

    float h0 = cameraPosition.y - MORNING_MIST_BASE_Y;
    float h1 = h0 + worldDir.y * dist;
    float hm = 0.5 * (h0 + h1);
    // Simpson: tich phan mat do doc theo tia
    float tau = dist * (mistDensityAt(h0, a) + 4.0 * mistDensityAt(hm, a) + mistDensityAt(h1, a)) / 6.0;

    float fog = (1.0 - exp(-tau)) * skyExposure;

    float cosVL = dot(worldDir, lightDirW);
    vec3 mistColor = skyCol * 1.2 + sunCol * hgPhase1(cosVL, 0.55) * 1.2;

    return mix(color, mistColor, saturate(fog));
}

#endif
