// Entity trong suot (skin nguoi choi...). Iris ve chuong trinh nay SAU buoc deferred,
// nen phai tu tinh anh sang ngay tai day (forward), khong the dua albedo tho vao colortex0.
varying vec2 lmcoord;
varying vec2 texcoord;

varying vec4 glcolor;

varying vec3 normalVO;
varying vec4 vWorldPos;

varying vec3 lightWorldDir;
varying vec3 sunColor, skyColor;

#include "/lib/uniform.glsl"
#include "/lib/settings.glsl"
#include "/lib/common/utils.glsl"
#include "/lib/camera/colorToolkit.glsl"
#include "/lib/common/position.glsl"
#include "/lib/common/noise.glsl"
#include "/lib/common/normal.glsl"

#include "/lib/atmosphere/atmosphericScattering.glsl"

#include "/lib/lighting/lightmap.glsl"
#include "/lib/lighting/shadowMapping.glsl"

#ifdef FSH
#include "/lib/water/translucentLighting.glsl"

void main() {
	vec4 texColor = texture(tex, texcoord) * glcolor;
	if(texColor.a < 0.005) discard;
	texColor.rgb = mix(texColor.rgb, entityColor.rgb, entityColor.a);

	vec3 albedo = toLinearR(texColor.rgb);
	vec3 diffuse = albedo / PI;

	vec2 lightmap = AdjustLightmap(lmcoord);

	vec3 normalV = normalize(normalVO);
	vec3 normalW = normalize(viewPosToWorldPos(vec4(normalV, 0.0)).xyz);

	float cosTheta = max(dot(normalW, lightWorldDir), 0.0);

	float UoN = dot(normalW, upWorldDir);
	vec3 skyColorMix = mix(sunColor, skyColor, 0.98 - 0.05 * lightmap.y);
	float hemiWeight = mix(1.0, UoN * 0.5 + 0.5, 0.66);
	vec3 skyLight = lightmap.y * diffuse * skyColorMix * hemiWeight;

	float shade = 1.0;
	#ifdef TRANSLUCENT_SHADOW
		shade = shadowMappingTranslucent(vWorldPos, normalW, TRANSLUCENT_SHADOW_SOFTNESS, TRANSLUCENT_SHADOW_QUALITY);
	#endif
	vec3 direct = sunColor * diffuse * shade * cosTheta;

	vec3 artificial = lightmap.x * artificial_color * diffuse;

	vec3 c = albedo * 0.005;
	c += skyLight * SKY_LIGHT_BRIGHTNESS;
	c += nightVision * diffuse * NIGHT_VISION_BRIGHTNESS;
	c += direct * DIRECT_LUMINANCE;
	c += artificial;

	if(isEyeInWater == 1){
		c *= saturate(fastExp(-(vec3(1.0) - waterFogColor) * (1.25 - lightmap.y) * 3.0));
	}

	c = max(c, BLACK);

/* DRAWBUFFERS:0 */
	gl_FragData[0] = vec4(c, texColor.a);
}

#endif
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#ifdef VSH

void main() {
	gl_Position = ftransform();

	vec2 jitter = Halton_2_3[framemod8];	//-1 to 1
	jitter *= invViewSize;
	gl_Position.xyz /= gl_Position.w;
    gl_Position.xy += jitter * TAA_JITTER_AMOUNT;
    gl_Position.xyz *= gl_Position.w;

	vec4 vViewPos = gl_ModelViewMatrix * gl_Vertex;
	vWorldPos = viewPosToWorldPos(vViewPos);

	normalVO = normalize(gl_NormalMatrix * gl_Normal);
	lightWorldDir = normalize(viewPosToWorldPos(vec4(shadowLightPosition, 0.0)).xyz);

	sunColor = texelFetch(gaux2, SUN_COLOR_UV, 0).rgb;
	skyColor = texelFetch(gaux2, SKY_COLOR_UV, 0).rgb;

	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;
}

#endif
