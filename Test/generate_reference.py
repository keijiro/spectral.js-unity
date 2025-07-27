#!/usr/bin/env python3
"""
Generate reference image by rendering fragment shader using ModernGL.
"""

import moderngl
import numpy as np
from PIL import Image
import sys
import os

def load_shader_source(filename):
    """Load shader source code from file."""
    with open(filename, 'r') as f:
        content = f.read()

    # Include spectral.glsl if referenced
    if '#include "spectral.glsl"' in content:
        with open('spectral.glsl', 'r') as f:
            spectral_source = f.read()
        content = content.replace('#include "spectral.glsl"', spectral_source)

    return content

def create_vertex_shader():
    """Create a simple vertex shader for fullscreen quad."""
    return """
    #version 330

    in vec2 position;

    void main() {
        gl_Position = vec4(position, 0.0, 1.0);
    }
    """

def render_fragment_shader(width=512, height=512, output_file="SpectralMixReference.png"):
    """Render fragment shader to image."""

    # Create OpenGL context
    ctx = moderngl.create_context(standalone=True)

    try:
        # Load fragment shader
        fragment_source = load_shader_source('generate_reference.frag')
        vertex_source = create_vertex_shader()

        # Create shader program
        program = ctx.program(
            vertex_shader=vertex_source,
            fragment_shader=fragment_source
        )

        # Set uniforms
        if 'u_resolution' in program:
            program['u_resolution'] = (width, height)
        if 'u_time' in program:
            program['u_time'] = 0.0

        # Create fullscreen quad
        vertices = np.array([
            -1.0, -1.0,
             1.0, -1.0,
            -1.0,  1.0,
             1.0,  1.0,
        ], dtype=np.float32)

        vbo = ctx.buffer(vertices.tobytes())
        vao = ctx.vertex_array(program, [(vbo, '2f', 'position')])

        # Create framebuffer
        texture = ctx.texture((width, height), 4)
        framebuffer = ctx.framebuffer(color_attachments=[texture])

        # Render
        framebuffer.use()
        ctx.viewport = (0, 0, width, height)
        ctx.clear(0.0, 0.0, 0.0, 1.0)
        vao.render(moderngl.TRIANGLE_STRIP)

        # Read pixels
        pixels = framebuffer.read(components=4)

        # Convert to PIL Image and save
        image_array = np.frombuffer(pixels, dtype=np.uint8).reshape((height, width, 4))
        image_array = np.flip(image_array, axis=0)  # Flip Y axis
        image = Image.fromarray(image_array)
        image.save(output_file)

        print(f"Reference image saved to {output_file}")

    except Exception as e:
        print(f"Error rendering shader: {e}", file=sys.stderr)
        return False

    finally:
        ctx.release()

    return True

def main():
    """Main function."""
    if not os.path.exists('generate_reference.frag'):
        print("Error: generate_reference.frag not found", file=sys.stderr)
        sys.exit(1)

    if not os.path.exists('spectral.glsl'):
        print("Error: spectral.glsl not found", file=sys.stderr)
        sys.exit(1)

    success = render_fragment_shader()
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()