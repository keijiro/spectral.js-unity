//  This file is in the public domain.
//  Unity wrapper functions for spectral.js

#ifndef SPECTRAL_UNITY_INCLUDED
#define SPECTRAL_UNITY_INCLUDED

#include "Spectral.hlsl"

// Unity-style PascalCase wrapper functions for spectral mixing
// These functions automatically handle color space conversion based on Unity's lighting mode

// Helper function to convert input colors to sRGB space for spectral calculation
// spectral_mix() expects sRGB input and returns sRGB output
float3 _PrepareColorForSpectral(float3 color) {
#ifdef UNITY_COLORSPACE_GAMMA
    return color; // Already in gamma/sRGB space
#else
    return spectral_linear_to_srgb(color); // Convert from linear to sRGB
#endif
}

// Helper function to convert result back to Unity's expected color space
float3 _PrepareColorFromSpectral(float3 color) {
#ifdef UNITY_COLORSPACE_GAMMA
    return color; // Keep in gamma/sRGB space
#else
    return spectral_srgb_to_linear(color); // Convert from sRGB to linear
#endif
}

// Two-color mixing with factor
float3 SpectralMix(float3 color1, float3 color2, float factor) {
    float3 linear1 = _PrepareColorForSpectral(color1);
    float3 linear2 = _PrepareColorForSpectral(color2);
    float3 result = spectral_mix(linear1, linear2, factor);
    return _PrepareColorFromSpectral(result);
}

// Two-color mixing with separate factors
float3 SpectralMix(float3 color1, float factor1, float3 color2, float factor2) {
    float3 linear1 = _PrepareColorForSpectral(color1);
    float3 linear2 = _PrepareColorForSpectral(color2);
    float3 result = spectral_mix(linear1, factor1, linear2, factor2);
    return _PrepareColorFromSpectral(result);
}

// Two-color mixing with tinting strengths and factors
float3 SpectralMix(float3 color1, float tintingStrength1, float factor1, float3 color2, float tintingStrength2, float factor2) {
    float3 linear1 = _PrepareColorForSpectral(color1);
    float3 linear2 = _PrepareColorForSpectral(color2);
    float3 result = spectral_mix(linear1, tintingStrength1, factor1, linear2, tintingStrength2, factor2);
    return _PrepareColorFromSpectral(result);
}

// Three-color mixing with factors
float3 SpectralMix(float3 color1, float factor1, float3 color2, float factor2, float3 color3, float factor3) {
    float3 linear1 = _PrepareColorForSpectral(color1);
    float3 linear2 = _PrepareColorForSpectral(color2);
    float3 linear3 = _PrepareColorForSpectral(color3);
    float3 result = spectral_mix(linear1, factor1, linear2, factor2, linear3, factor3);
    return _PrepareColorFromSpectral(result);
}

// Three-color mixing with tinting strengths and factors
float3 SpectralMix(float3 color1, float tintingStrength1, float factor1, float3 color2, float tintingStrength2, float factor2, float3 color3, float tintingStrength3, float factor3) {
    float3 linear1 = _PrepareColorForSpectral(color1);
    float3 linear2 = _PrepareColorForSpectral(color2);
    float3 linear3 = _PrepareColorForSpectral(color3);
    float3 result = spectral_mix(linear1, tintingStrength1, factor1, linear2, tintingStrength2, factor2, linear3, tintingStrength3, factor3);
    return _PrepareColorFromSpectral(result);
}

// Four-color mixing with factors
float3 SpectralMix(float3 color1, float factor1, float3 color2, float factor2, float3 color3, float factor3, float3 color4, float factor4) {
    float3 linear1 = _PrepareColorForSpectral(color1);
    float3 linear2 = _PrepareColorForSpectral(color2);
    float3 linear3 = _PrepareColorForSpectral(color3);
    float3 linear4 = _PrepareColorForSpectral(color4);
    float3 result = spectral_mix(linear1, factor1, linear2, factor2, linear3, factor3, linear4, factor4);
    return _PrepareColorFromSpectral(result);
}

// Four-color mixing with tinting strengths and factors
float3 SpectralMix(float3 color1, float tintingStrength1, float factor1, float3 color2, float tintingStrength2, float factor2, float3 color3, float tintingStrength3, float factor3, float3 color4, float tintingStrength4, float factor4) {
    float3 linear1 = _PrepareColorForSpectral(color1);
    float3 linear2 = _PrepareColorForSpectral(color2);
    float3 linear3 = _PrepareColorForSpectral(color3);
    float3 linear4 = _PrepareColorForSpectral(color4);
    float3 result = spectral_mix(linear1, tintingStrength1, factor1, linear2, tintingStrength2, factor2, linear3, tintingStrength3, factor3, linear4, tintingStrength4, factor4);
    return _PrepareColorFromSpectral(result);
}

#endif
