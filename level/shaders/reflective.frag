uniform bool reflects;
uniform Image reflection;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    vec4 it = Texel(tex, texture_coords);
    vec4 other;
    if (reflects && it == vec4(0., 0., 1. / 255, 1.)) {
        other = Texel(reflection, texture_coords);
        if (other.a == 0.) return vec4(0., 0., 0., 1.);
        return other;
    }
    return it;
}

