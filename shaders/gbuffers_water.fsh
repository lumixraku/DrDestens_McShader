uniform int worldTime;
//uniform vec2 atlasSizeInverse;

#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/gbuffers_basics.glsl"
#include "/lib/unpackPBR.glsl"
#include "/lib/generatePBR.glsl"
#include "/lib/lighting.glsl"

uniform float frameTimeCounter;

#ifdef OPTIMIZE_INTERPOLATION
    flat in mat3 tbn;
#else
    in mat3 tbn;
#endif
// tbn[0] = tangent vector
// tbn[1] = binomial vector
// tbn[2] = normal vector

flat in int blockId; // from gbuffer_water.vsh
in vec3 worldPos;
in vec3 viewDir;
in vec2 lmcoord;
in vec2 coord;
in vec4 glcolor;

vec2 worley(vec2 coord, float size, int complexity, float time) {
    vec2 uv  = coord;
    
    // Calculate Grid UVs (Also center at (0,0))
    vec2 guv = fract(uv * size) - .5;
    vec2 gid = floor(uv * size);
    
    float md1 = 1e3;
    float md2 = 2e3;
    
    // Check neighboring Grid cells
    for (int x = -complexity; x <= complexity; x++) {
        for (int y = -complexity; y <= complexity; y++) {
        
            vec2 offset = vec2(x, y);
            
            // Get the id of current cell (pixel cell + offset by for loop)
            vec2 id    = gid + offset;
            // Get the uv difference to that cell (offset has to be subtracted)
            vec2 relUV = guv - offset;
            
            // Get Random Point (adjust to range (-.5, .5))
            vec2 p     = N22(id) - .5;
            p          = vec2(sin(time * p.x), cos(time * p.y)) * .5;
            
            // Calculate Distance bewtween point and relative UVs)
            vec2 tmp   = p - relUV;
            float d    = dot(tmp, tmp);
            
            
            if (md1 > d) {
                md2 = md1;
                md1 = d;
            } else if (md2 > d) {
                md2 = d;
            }
        }
    }

    return vec2(md1, md2);
}

// voronoi 图，像细胞一样
float voronoi(vec2 coord, float size, int complexity, float time) {
    vec2 uv  = coord;
    
    // Calculate Grid UVs (Also center at (0,0))
    vec2 guv = fract(uv * size) - .5;
    vec2 gid = floor(uv * size);
    
    float md1 = 1e3;
    float md2 = 2e3;
    
    float minDistance = 1e3;

    // Check neighboring Grid cells
    for (int x = -complexity; x <= complexity; x++) {
        for (int y = -complexity; y <= complexity; y++) {
        
            vec2 offset = vec2(x, y);
            
            // Get the id of current cell (pixel cell + offset by for loop)
            vec2 id    = gid + offset;
            // Get the uv difference to that cell (offset has to be subtracted)
            vec2 relUV = guv - offset;
            
            // Get Random Point (adjust to range (-.5, .5))
            vec2 p     = N22(id) - .5;
            p          = vec2(sin(time * p.x), cos(time * p.y)) * .5;
            
            // Calculate Distance bewtween point and relative UVs)
            vec2 tmp   = p - relUV;
            float d    = dot(tmp, tmp);
            
            // Select the smallest distance
            
            float h     = smoothstep( 0.0, 2.0, 0.5 + (minDistance-d) * 1.);
            minDistance = mix( minDistance, d, h ); // distance
            
        }
    }

    return 1 - minDistance;
}

vec3 noiseNormals(vec2 coord, float strength) {
    vec2  e = vec2(0.01, 0);
    float C = fbm(coord,        2);
    float R = fbm(coord + e.xy, 2);
    float B = fbm(coord + e.yx, 2);

    vec3 n  = vec3(R-C, B-C, e.x);
    n.xy   *= strength;
    return normalize(n);
}

vec3 waveNormals(vec2 coord, float strength) {
    float t = frameTimeCounter * 5;

    vec2 nCoord = coord * 5;

    vec2  e = vec2(0.01, 0);
    float C = voronoi(coord,        .5, 2, t) + fbm(nCoord,        1);
    float R = voronoi(coord + e.xy, .5, 2, t) + fbm(nCoord + e.xy, 1);
    float B = voronoi(coord + e.yx, .5, 2, t) + fbm(nCoord + e.yx, 1);

    vec3 n  = vec3(R-C, B-C, e.x);
    n.xy   *= strength;
    return normalize(n);
}

#ifndef PHYSICALLY_BASED
/* DRAWBUFFERS:023 */
#else
#ifdef PHYSICALLY_BASED
/* DRAWBUFFERS:0231 */
#else
/* DRAWBUFFERS:023 */
#endif
#endif

/* 暂时不明上面的意义，没看到使用方，但是去掉就看不到水的存在了  改变数字顺序也看不到了   */
/* 但是 0231 改成 023 看起来无变化  02 就看不到水了  021 的话水看起来完全透明没有水面反射了 */
/* 其他和水相关的部分在 composite2.fsh 中  */


void main(){
    vec3  surfaceNormal  = tbn[2];
	vec4  color          = texture2D(texture, coord, 0) * vec4(glcolor.rgb, 1); // 不知道用途

    // Reduce opacity and saturation of only water
    if (blockId == 10) {

        #ifdef WATER_TEXTURE_VISIBLE
         // 有了 ifdef 控制面板中才有 WATER_TEXTURE_VISIBLE 配置项
         color.rgb = sq(color.rgb * getLightmap(lmcoord).rgb) * 0.75;
        #else

            color.rgb          = vec3(0);
            color.a            = 0.01;

        #endif

        #ifdef WATER_NORMALS

            float surfaceDot   = dot(viewDir, surfaceNormal);
            
            // "Fake" Waves
            vec2  seed         = (worldPos.xz * WATER_NORMALS_SIZE) + (frameTimeCounter * 0.5);
            float blend        = saturate(map(abs(surfaceDot), 0.005, 0.2, 0.05, 1));              // Reducing the normals at small angles to avoid high noise
            vec3  noiseNormals = noiseNormals(seed, WATER_NORMALS_AMOUNT * 0.1 * blend);

            surfaceNormal      = normalize(tbn * noiseNormals);

        #endif

    }


    gl_FragData[0] = color; // Color  // 意义不明 注释了后看不出区别
    gl_FragData[1] = vec4(surfaceNormal, 1); // Normal  // 注释后水就坏了，像泥巴一样

    // 关键作用，注释了这个水看起来就没有了，
    gl_FragData[2] = vec4(codeID(blockId), vec3(1)); // Type (colortex3)
    #ifdef PHYSICALLY_BASED
    gl_FragData[3] = vec4(reflectiveness, vec3(1)); // 从命名看反光，但是注释后还是有镜面反射
    #endif
}