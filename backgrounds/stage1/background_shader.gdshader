shader_type canvas_item;

uniform float brightness : hint_range(0.0, 2.0) = 1.15;
uniform float contrast   : hint_range(0.0, 2.0) = 1.00;
uniform float alpha      : hint_range(0.0, 1.0) = 1.0; // New transparency control

void fragment() {
    vec4 c = texture(TEXTURE, UV);

    // Contrast around 0.5
    c.rgb = (c.rgb - 0.5) * contrast + 0.5;

    // Brightness
    c.rgb *= brightness;

    // Apply transparency (alpha)
    c.a *= alpha;

    COLOR = c;
}
