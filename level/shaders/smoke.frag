const int SCALE = 4;

vec2 right = vec2(SCALE / love_ScreenSize.x, 0.);
vec2 down = vec2(0., SCALE / love_ScreenSize.y);
vec2 left = -right;
vec2 up = -down;

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    if (texture_coords.y > 1 - 1 / love_ScreenSize.y) {
        return vec4(0, 0, 0, 1);
    }

    return vec4((
        + Texel(tex, texture_coords + up)
        + Texel(tex, texture_coords + left)
        + Texel(tex, texture_coords + right)
        + 2 * Texel(tex, texture_coords + down)
    ).rgb / 5, 1.);
}
