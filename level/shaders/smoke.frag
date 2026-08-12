const int SCALE = 4;

vec2 right = vec2(SCALE / love_ScreenSize.x, 0.);
vec2 down = vec2(0., SCALE / love_ScreenSize.y);
vec2 left = -right;
vec2 up = -down;

uniform vec4 palette[%s];

vec4 apply_palette(vec4 it)
{
    float min_distance = 1;
    vec4 closest_color;
    for (int i = 0; i < 46; i++) {
        vec4 current_color = palette[i];
        float distance = (
            pow(current_color.r - it.r, 2) +
            pow(current_color.g - it.g, 2) +
            pow(current_color.b - it.b, 2)
        );

        if (distance < min_distance) {
            min_distance = distance;
            closest_color = current_color;
        }
    }
    return closest_color;
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    if (texture_coords.y > 1 - SCALE / love_ScreenSize.y
        || texture_coords.y < SCALE / love_ScreenSize.y
        || texture_coords.x > 1 - SCALE / love_ScreenSize.x
        || texture_coords.x < SCALE / love_ScreenSize.x) {
        return vec4(0, 0, 0, 1);
    }

    return apply_palette(vec4((
        + Texel(tex, texture_coords + up)
        + Texel(tex, texture_coords + left)
        + Texel(tex, texture_coords + right)
        + 2 * Texel(tex, texture_coords + down)
    ).rgb / 5, 1.));
}
