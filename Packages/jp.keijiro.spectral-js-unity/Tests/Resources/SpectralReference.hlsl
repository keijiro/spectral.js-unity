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
    int gridSizeX = 16;
    int gridSizeY = 18;
    float2 grid = uv * float2(float(gridSizeX), float(gridSizeY));
    int2 cellCoord = int2(floor(grid));
    float2 localCoord = frac(grid);
    
    int index = cellCoord.y * gridSizeX + cellCoord.x;
    
    float3 result;
    
    // Color bars section (rows 17-18)
    if (cellCoord.y >= 16) {
        if (cellCoord.y == 16) {
            // Row 17: HSV Hue color bar (H varies 0-1, S=1, V=1)
            float hue = float(cellCoord.x) / float(gridSizeX - 1);
            result = hsv2rgb(float3(hue, 1.0, 1.0));
        } else {
            // Row 18: Grayscale bar (0-1)
            float gray = float(cellCoord.x) / float(gridSizeX - 1);
            result = float3(gray, gray, gray);
        }
    }
    // Generate test colors based on grid position
    // First 128 cells: Primary color tests with spectral mixing
    else if (index < 128) {
        float hue1 = fmod(float(index * 7), 360.0) / 360.0;
        float hue2 = fmod(float(index * 13 + 180), 360.0) / 360.0;
        
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
    else if (index < 192) {
        int subIndex = index - 128;
        
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
        
        int colorIndex1 = subIndex % 16;
        int colorIndex2 = (subIndex / 4) % 16;
        
        float3 color1 = specialColors[colorIndex1];
        float3 color2 = specialColors[colorIndex2];
        
        float tint1 = 0.7 + 0.3 * localCoord.x;
        float tint2 = 0.7 + 0.3 * localCoord.y;
        result = spectral_mix(color1, tint1, 0.5, color2, tint2, 0.5);
    }
    // Last 64 cells: Three and four color mixing
    else {
        int subIndex = index - 192;
        
        float r1 = float((subIndex * 3) % 11) / 10.0;
        float g1 = float((subIndex * 5) % 11) / 10.0;
        float b1 = float((subIndex * 7) % 11) / 10.0;
        float3 color1 = float3(r1, g1, b1);
        
        float r2 = float((subIndex * 11) % 13) / 12.0;
        float g2 = float((subIndex * 13) % 13) / 12.0;
        float b2 = float((subIndex * 17) % 13) / 12.0;
        float3 color2 = float3(r2, g2, b2);
        
        float r3 = float((subIndex * 19) % 17) / 16.0;
        float g3 = float((subIndex * 23) % 17) / 16.0;
        float b3 = float((subIndex * 29) % 17) / 16.0;
        float3 color3 = float3(r3, g3, b3);
        
        if (subIndex < 32) {
            float f1 = 0.33;
            float f2 = 0.33;
            float f3 = 0.34;
            result = spectral_mix(color1, f1, color2, f2, color3, f3);
        } else {
            float r4 = float((subIndex * 31) % 19) / 18.0;
            float g4 = float((subIndex * 37) % 19) / 18.0;
            float b4 = float((subIndex * 41) % 19) / 18.0;
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