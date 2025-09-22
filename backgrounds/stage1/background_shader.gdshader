shader_type canvas_item;

uniform float brightness : hint_range(0.0, 2.0) = 1.15;
uniform float contrast   : hint_range(0.0, 2.0) = 1.00;

void fragment() {
    vec4 c = texture(TEXTURE, UV);
    // Contraste alrededor de 0.5
    c.rgb = (c.rgb - 0.5) * contrast + 0.5;
    // Brillo
    c.rgb *= brightness;
    COLOR = c * texture(TEXTURE, UV).a; // respeta alpha original
}
