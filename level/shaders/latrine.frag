vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 v = Texel(tex, texture_coords);
    vec4 u = vec4(0.376, 0.702, 0.494, v.w);
    return vec4(
        (v.xyz + u.xyz) / 2,
        v.w
    ) * color;
}
