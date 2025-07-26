#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;

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
    float gridSizeX = 16.0;
    float gridSizeY = 18.0;
    vec2 grid = st * vec2(gridSizeX, gridSizeY);
    vec2 cellCoord = floor(grid);
    vec2 localCoord = fract(grid);
    
    // Convert grid position to a unique index
    float index = cellCoord.y * gridSizeX + cellCoord.x;
    
    vec3 result;
    
    // Color bars section (rows 17-18)
    if (cellCoord.y >= 16.0) {
        if (cellCoord.y == 16.0) {
            // Row 17: HSV Hue color bar (H varies 0-1, S=1, V=1)
            float hue = cellCoord.x / (gridSizeX - 1.0);  // 0 to 1 across 16 cells
            result = hsv2rgb(vec3(hue, 1.0, 1.0));
        } else {
            // Row 18: Grayscale bar (0-1)
            float gray = cellCoord.x / (gridSizeX - 1.0);  // 0 to 1 across 16 cells
            result = vec3(gray);
        }
    }
    // Generate test colors based on grid position
    // First 128 cells: Primary color tests with spectral mixing
    else if (index < 128.0) {
        // Create a variety of colors using HSV-like approach
        float hue1 = mod(index * 7.0, 360.0) / 360.0;
        float hue2 = mod(index * 13.0 + 180.0, 360.0) / 360.0;
        
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
    else if (index < 192.0) {
        float subIndex = index - 128.0;
        
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
        
        int colorIndex1 = int(mod(subIndex, 16.0));
        int colorIndex2 = int(mod(subIndex / 4.0, 16.0));
        
        vec3 color1 = specialColors[colorIndex1];
        vec3 color2 = specialColors[colorIndex2];
        
        // Test with different tinting strengths (safe range 0.7-1.0)
        float tint1 = 0.7 + 0.3 * localCoord.x;
        float tint2 = 0.7 + 0.3 * localCoord.y;
        result = spectral_mix(color1, tint1, 0.5, color2, tint2, 0.5);
    }
    // Last 64 cells: Three and four color mixing
    else {
        float subIndex = index - 192.0;
        
        // Generate diverse test colors
        float r1 = mod(subIndex * 3.0, 11.0) / 10.0;
        float g1 = mod(subIndex * 5.0, 11.0) / 10.0;
        float b1 = mod(subIndex * 7.0, 11.0) / 10.0;
        vec3 color1 = vec3(r1, g1, b1);
        
        float r2 = mod(subIndex * 11.0, 13.0) / 12.0;
        float g2 = mod(subIndex * 13.0, 13.0) / 12.0;
        float b2 = mod(subIndex * 17.0, 13.0) / 12.0;
        vec3 color2 = vec3(r2, g2, b2);
        
        float r3 = mod(subIndex * 19.0, 17.0) / 16.0;
        float g3 = mod(subIndex * 23.0, 17.0) / 16.0;
        float b3 = mod(subIndex * 29.0, 17.0) / 16.0;
        vec3 color3 = vec3(r3, g3, b3);
        
        if (subIndex < 32.0) {
            // Three color mixing
            float f1 = 0.33;
            float f2 = 0.33;
            float f3 = 0.34;
            result = spectral_mix(color1, f1, color2, f2, color3, f3);
        } else {
            // Four color mixing
            float r4 = mod(subIndex * 31.0, 19.0) / 18.0;
            float g4 = mod(subIndex * 37.0, 19.0) / 18.0;
            float b4 = mod(subIndex * 41.0, 19.0) / 18.0;
            vec3 color4 = vec3(r4, g4, b4);
            
            float f1 = 0.25;
            float f2 = 0.25;
            float f3 = 0.25;
            float f4 = 0.25;
            result = spectral_mix(color1, f1, color2, f2, color3, f3, color4, f4);
        }
    }
    
    gl_FragColor = vec4(result, 1.0);
}