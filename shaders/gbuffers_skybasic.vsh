#include "/lib/settings.glsl"
#include "/lib/math.glsl"

// vsh 中 out 的变量将会作为 fsh 中 in 变量
out vec4 starData; //rgb = star color, a = flag for weather or not this pixel is a star.

void main() {
    gl_Position = ftransform();
    starData    = vec4(gl_Color.rgb, float(gl_Color.r == gl_Color.g && gl_Color.g == gl_Color.b && gl_Color.r > 0.0));
}