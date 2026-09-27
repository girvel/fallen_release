uniform float k = 1;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 it = Texel(tex, texture_coords);
    it.rgb *= k;
    return it * color;
}
