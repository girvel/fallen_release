vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 v = Texel(tex, texture_coords);
    if (v.a == 0) {
        return vec4(0.);
    }
    if (v.r < 0.2 && v.g < 0.2 && v.b < 0.2) {
        return vec4(0., 0., 0., 1.);
    }
    return vec4(0.93, 0.93, 0.93, 1.0);
}
