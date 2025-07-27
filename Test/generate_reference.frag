#version 330

#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

out vec4 fragColor;

#include "spectral.glsl"

// HSV to RGB conversion
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void main() {
    vec2 st = gl_FragCoord.xy / u_resolution.xy;
    
    // Create a color wheel + additional test colors
    // Divide into a 16x18 grid to test 256 different color combinations + color bars
    int gridSizeX = 16;
    int gridSizeY = 18;
    vec2 grid = st * vec2(float(gridSizeX), float(gridSizeY));
    ivec2 cellCoord = ivec2(floor(grid));
    vec2 localCoord = fract(grid);
    
    // Convert grid position to a unique index
    int index = cellCoord.y * gridSizeX + cellCoord.x;
    
    vec3 result;
    
    // Color bars section (rows 17-18)
    if (cellCoord.y >= 16) {
        if (cellCoord.y == 16) {
            // Row 17: HSV Hue color bar (H varies 0-1, S=1, V=1)
            float hue = float(cellCoord.x) / float(gridSizeX - 1);  // 0 to 1 across 16 cells
            result = hsv2rgb(vec3(hue, 1.0, 1.0));
        } else {
            // Row 18: Grayscale bar (0-1)
            float gray = float(cellCoord.x) / float(gridSizeX - 1);  // 0 to 1 across 16 cells
            result = vec3(gray);
        }
    }
    // Generate test colors based on grid position
    // First 128 cells: Primary color tests with spectral mixing
    else if (index < 128) {
        // Create a variety of colors using HSV-like approach
        float hue1 = mod(float(index * 7), 360.0) / 360.0;
        float hue2 = mod(float(index * 13 + 180), 360.0) / 360.0;
        
        // Convert hue to RGB (simplified HSV to RGB)
        vec3 color1 = vec3(
            0.5 + 0.5 * cos(6.28318 * (hue1 + 0.0)),
            0.5 + 0.5 * cos(6.28318 * (hue1 + 0.333)),
            0.5 + 0.5 * cos(6.28318 * (hue1 + 0.666))
        );
        
        vec3 color2 = vec3(
            0.5 + 0.5 * cos(6.28318 * (hue2 + 0.0)),
            0.5 + 0.5 * cos(6.28318 * (hue2 + 0.333)),
            0.5 + 0.5 * cos(6.28318 * (hue2 + 0.666))
        );
        
        // Test different mixing methods in each cell
        if (localCoord.x < 0.5 && localCoord.y < 0.5) {
            // Top-left: spectral_mix with 0.25 factor
            result = spectral_mix(color1, color2, 0.25);
        } else if (localCoord.x >= 0.5 && localCoord.y < 0.5) {
            // Top-right: spectral_mix with 0.5 factor
            result = spectral_mix(color1, color2, 0.5);
        } else if (localCoord.x < 0.5 && localCoord.y >= 0.5) {
            // Bottom-left: spectral_mix with 0.75 factor
            result = spectral_mix(color1, color2, 0.75);
        } else {
            // Bottom-right: spectral_mix with factors
            result = spectral_mix(color1, 0.5, color2, 0.5);
        }
    }
    // Next 64 cells: Edge cases and special colors
    else if (index < 192) {
        int subIndex = index - 128;
        
        // Extended special colors covering more edge cases
        vec3 specialColors[16];
        specialColors[0] = vec3(0.01, 0.01, 0.01);   // Very dark gray
        specialColors[1] = vec3(1.0, 1.0, 1.0);     // White
        specialColors[2] = vec3(0.2, 0.2, 0.2);     // Dark gray
        specialColors[3] = vec3(0.5, 0.5, 0.5);     // Medium gray
        specialColors[4] = vec3(0.8, 0.8, 0.8);     // Light gray
        specialColors[5] = vec3(1.0, 0.0, 0.0);     // Pure Red
        specialColors[6] = vec3(0.0, 1.0, 0.0);     // Pure Green
        specialColors[7] = vec3(0.0, 0.0, 1.0);     // Pure Blue
        specialColors[8] = vec3(1.0, 1.0, 0.0);     // Yellow
        specialColors[9] = vec3(1.0, 0.0, 1.0);     // Magenta
        specialColors[10] = vec3(0.0, 1.0, 1.0);    // Cyan
        specialColors[11] = vec3(1.0, 0.5, 0.0);    // Orange
        specialColors[12] = vec3(0.5, 0.0, 1.0);    // Purple
        specialColors[13] = vec3(0.0, 0.5, 1.0);    // Sky blue
        specialColors[14] = vec3(1.0, 0.0, 0.5);    // Pink
        specialColors[15] = vec3(0.5, 1.0, 0.0);    // Lime
        
        int colorIndex1 = subIndex % 16;
        int colorIndex2 = (subIndex / 4) % 16;
        
        vec3 color1 = specialColors[colorIndex1];
        vec3 color2 = specialColors[colorIndex2];
        
        // Test with different tinting strengths (safe range 0.7-1.0)
        float tint1 = 0.7 + 0.3 * localCoord.x;
        float tint2 = 0.7 + 0.3 * localCoord.y;
        result = spectral_mix(color1, tint1, 0.5, color2, tint2, 0.5);
    }
    // Last 64 cells: Three and four color mixing
    else {
        int subIndex = index - 192;
        
        // Generate diverse test colors
        float r1 = float((subIndex * 3) % 11) / 10.0;
        float g1 = float((subIndex * 5) % 11) / 10.0;
        float b1 = float((subIndex * 7) % 11) / 10.0;
        vec3 color1 = vec3(r1, g1, b1);
        
        float r2 = float((subIndex * 11) % 13) / 12.0;
        float g2 = float((subIndex * 13) % 13) / 12.0;
        float b2 = float((subIndex * 17) % 13) / 12.0;
        vec3 color2 = vec3(r2, g2, b2);
        
        float r3 = float((subIndex * 19) % 17) / 16.0;
        float g3 = float((subIndex * 23) % 17) / 16.0;
        float b3 = float((subIndex * 29) % 17) / 16.0;
        vec3 color3 = vec3(r3, g3, b3);
        
        if (subIndex < 32) {
            // Three color mixing
            float f1 = 0.33;
            float f2 = 0.33;
            float f3 = 0.34;
            result = spectral_mix(color1, f1, color2, f2, color3, f3);
        } else {
            // Four color mixing
            float r4 = float((subIndex * 31) % 19) / 18.0;
            float g4 = float((subIndex * 37) % 19) / 18.0;
            float b4 = float((subIndex * 41) % 19) / 18.0;
            vec3 color4 = vec3(r4, g4, b4);
            
            float f1 = 0.25;
            float f2 = 0.25;
            float f3 = 0.25;
            float f4 = 0.25;
            result = spectral_mix(color1, f1, color2, f2, color3, f3, color4, f4);
        }
    }
    
    fragColor = vec4(result, 1.0);
}