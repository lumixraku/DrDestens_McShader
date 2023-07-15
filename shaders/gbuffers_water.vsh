#include "/lib/settings.glsl"
#include "/lib/math.glsl"
#include "/lib/kernels.glsl"
#include "/lib/vertex_transform.glsl"
#include "/lib/vertex_lighting.glsl"

#ifdef TAA
    uniform vec2 taaOffset;
#endif

uniform float frameTimeCounter;

attribute vec4 mc_Entity; // from block.properties
attribute vec4 at_tangent;

#ifdef OPTIMIZE_INTERPOLATION
    flat out mat3 tbn;
#else
    out mat3 tbn;
#endif

flat out int blockId;
out vec3 worldPos;
out vec3 viewDir;
out vec2 lmcoord;
out vec2 coord;
out vec4 glcolor;

void main(){

	gl_Position    = ftransform();
	vec3 viewPos   = getView();
	vec3 playerPos = toPlayer(viewPos);
	worldPos       = playerPos + cameraPosition;

	#ifdef WATER_WAVES

		if (mc_Entity.x == 1010) {  //  from block.properties 1010 means water

			float flowHeight = fract(worldPos.y + 0.01);

			// "Physical" Wave Offsets
			float zOffset    = sin((worldPos.x * 0.1) + (frameTimeCounter)) * 0.1;
			float zOffset2   = sin((worldPos.z * 0.2) + (frameTimeCounter * 3))* 0.4;
			// Appling them (y Direction aka "up")
			worldPos.y += (zOffset + zOffset2) * WATER_WAVE_AMOUNT * flowHeight;
			worldPos.y -= flowHeight * 0.5 * WATER_WAVE_AMOUNT;

			gl_Position = playerToClip(vec4(worldPos - cameraPosition, 1));

		}

	#endif

	#ifdef WORLD_CURVE
		#include "/lib/world_curve.glsl"
	#endif

	#ifdef TAA
		gl_Position.xy += taaOffset * TAA_JITTER_AMOUNT * gl_Position.w * 2;
	#endif

	tbn			 = getTBN(at_tangent);

	viewDir      = normalize(viewPos.xyz);

	blockId 	 = getID(mc_Entity);
    coord 		 = getCoord();
	lmcoord      = getLmCoord();
	glcolor 	 = gl_Color;
	glcolor.a   *= oldLighting(tbn[2], gbufferModelView);

}