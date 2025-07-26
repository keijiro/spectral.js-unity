#ifndef SPECTRAL_REFERENCE_INCLUDED
#define SPECTRAL_REFERENCE_INCLUDED

#include "../../Shaders/Spectral.hlsl"

// HSV to RGB conversion
float3 hsv2rgb(float3 c) {
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
}

// Generate reference pattern colors for testing spectral mixing
float3 GenerateReferenceColor(float2 uv, float2 resolution) {
    float gridSizeX = 16.0;
    float gridSizeY = 18.0;
    float2 grid = uv * float2(gridSizeX, gridSizeY);
    float2 cellCoord = floor(grid);
    float2 localCoord = frac(grid);
    
    float index = cellCoord.y * gridSizeX + cellCoord.x;
    
    float3 result;
    
    // Color bars section (rows 17-18)
    if (cellCoord.y >= 16.0) {
        if (cellCoord.y == 16.0) {
            // Row 17: HSV Hue color bar (H varies 0-1, S=1, V=1)
            float hue = cellCoord.x / (gridSizeX - 1.0);
            result = hsv2rgb(float3(hue, 1.0, 1.0));
        } else {
            // Row 18: Grayscale bar (0-1)
            float gray = cellCoord.x / (gridSizeX - 1.0);
            result = float3(gray, gray, gray);
        }
    }
    // Generate test colors based on grid position
    // First 128 cells: Primary color tests with spectral mixing
    else if (index < 128.0) {
        float hue1 = fmod(index * 7.0, 360.0) / 360.0;
        float hue2 = fmod(index * 13.0 + 180.0, 360.0) / 360.0;
        
        float3 color1 = float3(
            0.5 + 0.5 * cos(6.28318 * (hue1 + 0.0)),
            0.5 + 0.5 * cos(6.28318 * (hue1 + 0.333)),
            0.5 + 0.5 * cos(6.28318 * (hue1 + 0.666))
        );
        
        float3 color2 = float3(
            0.5 + 0.5 * cos(6.28318 * (hue2 + 0.0)),
            0.5 + 0.5 * cos(6.28318 * (hue2 + 0.333)),
            0.5 + 0.5 * cos(6.28318 * (hue2 + 0.666))
        );
        
        if (localCoord.x < 0.5 && localCoord.y < 0.5) {
            result = spectral_mix(color1, color2, 0.25);
        } else if (localCoord.x >= 0.5 && localCoord.y < 0.5) {
            result = spectral_mix(color1, color2, 0.5);
        } else if (localCoord.x < 0.5 && localCoord.y >= 0.5) {
            result = spectral_mix(color1, color2, 0.75);
        } else {
            result = spectral_mix(color1, 0.5, color2, 0.5);
        }
    }
    // Next 64 cells: Edge cases and special colors
    else if (index < 192.0) {
        float subIndex = index - 128.0;
        
        float3 specialColors[16] = {
            float3(0.01, 0.01, 0.01),   // Very dark gray
            float3(1.0, 1.0, 1.0),     // White
            float3(0.2, 0.2, 0.2),     // Dark gray
            float3(0.5, 0.5, 0.5),     // Medium gray
            float3(0.8, 0.8, 0.8),     // Light gray
            float3(1.0, 0.0, 0.0),     // Pure Red
            float3(0.0, 1.0, 0.0),     // Pure Green
            float3(0.0, 0.0, 1.0),     // Pure Blue
            float3(1.0, 1.0, 0.0),     // Yellow
            float3(1.0, 0.0, 1.0),     // Magenta
            float3(0.0, 1.0, 1.0),     // Cyan
            float3(1.0, 0.5, 0.0),     // Orange
            float3(0.5, 0.0, 1.0),     // Purple
            float3(0.0, 0.5, 1.0),     // Sky blue
            float3(1.0, 0.0, 0.5),     // Pink
            float3(0.5, 1.0, 0.0)      // Lime
        };
        
        int colorIndex1 = (int)fmod(subIndex, 16.0);
        int colorIndex2 = (int)fmod(subIndex / 4.0, 16.0);
        
        float3 color1 = specialColors[colorIndex1];
        float3 color2 = specialColors[colorIndex2];
        
        float tint1 = 0.7 + 0.3 * localCoord.x;
        float tint2 = 0.7 + 0.3 * localCoord.y;
        result = spectral_mix(color1, tint1, 0.5, color2, tint2, 0.5);
    }
    // Last 64 cells: Three and four color mixing
    else {
        float subIndex = index - 192.0;
        
        float r1 = fmod(subIndex * 3.0, 11.0) / 10.0;
        float g1 = fmod(subIndex * 5.0, 11.0) / 10.0;
        float b1 = fmod(subIndex * 7.0, 11.0) / 10.0;
        float3 color1 = float3(r1, g1, b1);
        
        float r2 = fmod(subIndex * 11.0, 13.0) / 12.0;
        float g2 = fmod(subIndex * 13.0, 13.0) / 12.0;
        float b2 = fmod(subIndex * 17.0, 13.0) / 12.0;
        float3 color2 = float3(r2, g2, b2);
        
        float r3 = fmod(subIndex * 19.0, 17.0) / 16.0;
        float g3 = fmod(subIndex * 23.0, 17.0) / 16.0;
        float b3 = fmod(subIndex * 29.0, 17.0) / 16.0;
        float3 color3 = float3(r3, g3, b3);
        
        if (subIndex < 32.0) {
            float f1 = 0.33;
            float f2 = 0.33;
            float f3 = 0.34;
            result = spectral_mix(color1, f1, color2, f2, color3, f3);
        } else {
            float r4 = fmod(subIndex * 31.0, 19.0) / 18.0;
            float g4 = fmod(subIndex * 37.0, 19.0) / 18.0;
            float b4 = fmod(subIndex * 41.0, 19.0) / 18.0;
            float3 color4 = float3(r4, g4, b4);
            
            float f1 = 0.25;
            float f2 = 0.25;
            float f3 = 0.25;
            float f4 = 0.25;
            result = spectral_mix(color1, f1, color2, f2, color3, f3, color4, f4);
        }
    }
    
    return result;
}

#endif