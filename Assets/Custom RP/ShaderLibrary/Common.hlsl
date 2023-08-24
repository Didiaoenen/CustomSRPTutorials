#ifndef CUSTOM_COMMON_INCLUDED
#define CUSTOM_COMMON_INCLUDED

#ifndef SHADER_API_D3D11
#define SHADER_API_D3D11
#endif

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/CommonMaterial.hlsl"
#include "UnityInput.hlsl"

#define UNITY_MATRIX_M unity_ObjectToWorld
#define UNITY_MATRIX_I_M unity_WorldToObject
#define UNITY_MATRIX_V unity_MatrixV
#define UNITY_MATRIX_VP unity_MatrixVP
#define UNITY_MATRIX_P glstate_matrix_projection
#define UNITY_PREV_MATRIX_M   unity_MatrixPreviousM
#define UNITY_PREV_MATRIX_I_M unity_MatrixPreviousMI

#if defined(_SHADOW_MASK_ALWAYS) || defined(_SHADOW_MASK_DISTANCE)
	#define SHADOWS_SHADOWMASK
#endif

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/SpaceTransforms.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Packing.hlsl"

SAMPLER(sampler_linear_clamp);
SAMPLER(sampler_point_clamp);

bool IsOrthographicCamera() 
{
	return unity_OrthoParams.w;
}

float OrthographicDepthBufferToLinear(float rawDepth) 
{
	#if UNITY_REVERSED_Z
		rawDepth = 1.0 - rawDepth;
	#endif
	return (_ProjectionParams.z - _ProjectionParams.y) * rawDepth + _ProjectionParams.y;
}

#include "Fragment.hlsl"

float Square(float x) 
{
	return x * x;
}

float DistanceSquared(float3 pA, float3 pB) 
{
	return dot(pA - pB, pA - pB);
}

void ClipLOD(Fragment fragment, float fade) 
{
	#if defined(LOD_FADE_CROSSFADE)
		float dither = InterleavedGradientNoise(fragment.positionSS, 0);
		clip(fade + (fade < 0.0 ? dither : -dither));
	#endif
}

real3 _UnpackNormalAG(real4 packedNormal, real scale = 1.0)
{
    real3 normal;
    normal.xy = packedNormal.ag * 2.0 - 1.0;
    normal.xy *= scale;
    normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
    return normal;
}

// Unpack normal as DXT5nm (1, y, 0, x) or BC5 (x, y, 0, 1)
real3 _UnpackNormalmapRGorAG(real4 packedNormal, real scale = 1.0)
{
    // Convert to (?, y, 0, x)
    packedNormal.a *= packedNormal.r;
    return _UnpackNormalAG(packedNormal, scale);
}

float3 DecodeNormal(float4 sample, float scale) 
{
	#if defined(UNITY_NO_DXT5nm)
	    return UnpackNormalRGB(sample, scale);
	#else
	    return _UnpackNormalmapRGorAG(sample, scale);
	#endif
}

float3 NormalTangentToWorld(float3 normalTS, float3 normalWS, float4 tangentWS) 
{
	float3x3 tangentToWorld = 
		CreateTangentToWorld(normalWS, tangentWS.xyz, tangentWS.w);
	return TransformTangentToWorld(normalTS, tangentToWorld);
}

#endif