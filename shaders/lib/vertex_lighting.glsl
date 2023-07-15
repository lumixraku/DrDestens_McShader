// 暫時沒有看到使用方
float oldLighting(vec3 normal, vec3 viewUp) {
    return dot(normal, viewUp) * OLD_LIGHTING_STRENGTH + (1 - OLD_LIGHTING_STRENGTH);
}

// gbufferModelView 來自 optfine 中 uniform 變量
float oldLighting(vec3 normal, mat4 gbufferModelView) {
    const vec3 oldLightVec = normalize(vec3(1,4,2));
    return dot(normal, mat3(gbufferModelView) * oldLightVec) * OLD_LIGHTING_STRENGTH + (1 - OLD_LIGHTING_STRENGTH);
}