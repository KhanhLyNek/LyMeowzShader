// ============================================================================
//  LyMeowz Shader - settings
//  Every "#define ... // [values]" line below becomes an in-game option in Iris.
// ============================================================================

// ---- Water ------------------------------------------------------------------
#define WATER_COLOR 0 // [0 1 2 3]
#define WATER_CLARITY 1.0 // [0.5 0.75 1.0 1.5 2.0 3.0]
#define WATER_WAVE_HEIGHT 1.0 // [0.4 0.7 1.0 1.3 1.6 2.0]
#define WATER_WAVE_SPEED 1.0 // [0.4 0.7 1.0 1.4 1.8]
#define WATER_WAVE_SCALE 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define WATER_WAVE_DETAIL 5 // [3 4 5 6]
#define WATER_REFRACTION 1.0 // [0.0 0.5 1.0 1.5 2.0]
#define WATER_REFLECTIONS
#define WATER_SSR_STEPS 32 // [16 24 32 48 64]
#define WATER_PARALLAX
#define WATER_CAUSTICS
#define WATER_CAUSTICS_STRENGTH 1.0 // [0.5 1.0 1.5 2.0 3.0]
#define WATER_FOAM
#define RAIN_RIPPLES

// ---- Lighting ---------------------------------------------------------------
#define SHADOWS
#define SHADOW_SOFTNESS 1.0 // [0.5 1.0 1.5 2.0]
#define COLORED_SHADOWS
#define SHADOW_BIAS 0.0005 // [0.0002 0.0005 0.001 0.002 0.004]
#define SHADOW_NORMAL_OFFSET 1.0 // [0.5 1.0 1.5 2.0 3.0]
#define SUN_INTENSITY 1.0 // [0.6 0.8 1.0 1.2 1.5]
#define TORCH_INTENSITY 1.0 // [0.5 0.75 1.0 1.5 2.0]
#define MIN_LIGHT 0.012

// ---- Sky --------------------------------------------------------------------
#define PROCEDURAL_CLOUDS
#define CLOUD_COVERAGE 0.5 // [0.3 0.4 0.5 0.6 0.7]

// ---- Post -------------------------------------------------------------------
#define EXPOSURE 1.0 // [0.6 0.8 1.0 1.2 1.5 2.0]
#define SATURATION 1.0 // [0.6 0.8 1.0 1.1 1.2 1.4]
#define VIGNETTE
#define BLOOM
#define BLOOM_STRENGTH 1.0 // [0.5 1.0 1.5 2.0 3.0]
#define BLOOM_THRESHOLD 2.2

// ---- Shadow map (read by Iris) ----------------------------------------------
const int shadowMapResolution = 2048; // [1024 2048 3072 4096]
const float shadowDistance = 128.0; // [64.0 96.0 128.0 192.0 256.0]
const float sunPathRotation = -25.0; // [-40.0 -30.0 -25.0 -15.0 0.0 15.0 25.0 40.0]

#define SHADOW_DISTORT 0.9
