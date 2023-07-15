// optfine 支持 colortex0 ~ 15 的 buffer
uniform sampler2D colortex0; // Color Buffer

vec3 getAlbedo(vec2 coord) {
    return texture(colortex0, coord).rgb;
}
vec3 getAlbedo(vec2 coord, float lod) {
    return texture(colortex0, coord, lod).rgb;
}

vec3 getAlbedoLod(vec2 coord, float lod) {

    // textureLod — perform a texture lookup with explicit level-of-detail
    // https://registry.khronos.org/OpenGL-Refpages/gl4/html/textureLod.xhtml
    return textureLod(colortex0, coord, lod).rgb;
}

vec3 getAlbedo(ivec2 icoord) {
    // https://blog.csdn.net/wyq1153/article/details/126191318
    // 更精确的纹理信息获取
    return texelFetch(colortex0, icoord, 0).rgb;
}
vec3 getAlbedo(ivec2 icoord, int lod) {
    return texelFetch(colortex0, icoord, lod).rgb;
}