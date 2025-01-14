#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_lighting.glsl"

#ifdef WORLD_CURVE
    #include "/lib/vertex_transform.glsl"
#else
    #include "/lib/vertex_transform_simple.glsl"
    uniform mat4 gbufferModelView;
#endif

attribute vec2 mc_midTexCoord;
attribute vec4 mc_Entity;
attribute vec4 at_tangent;

#ifdef TAA
    uniform vec2 taaOffset;
#endif

#ifdef OPTIMIZE_INTERPOLATION
    flat out vec4  glcolor;
    flat out mat3  tbn;
#else
    out vec4  glcolor;
    out mat3  tbn;
#endif

#ifdef PHYSICALLY_BASED
    out vec3 viewpos;
#endif

flat out int blockId;
out vec2 lmcoord;
out vec2 coord;

void main() {
	gl_Position = ftransform();
	
	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif
	
	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif

	#ifdef PHYSICALLY_BASED
	viewpos = getView();
	#endif
	lmcoord = getLmCoord();
	coord   = getCoord();
	tbn     = getTBN(at_tangent);

	blockId    = getID(mc_Entity);
	glcolor    = gl_Color;
	glcolor.a *= oldLighting(tbn[2], gbufferModelView);
}