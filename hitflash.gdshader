shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
    vec4 current_color = texture(TEXTURE, UV);
    vec2 size = TEXTURE_PIXEL_SIZE;
    
    // Detectamos bordes revisando los píxeles vecinos
    float alpha = current_color.a;
    alpha += texture(TEXTURE, UV + vec2(size.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(-size.x, 0.0)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, size.y)).a;
    alpha += texture(TEXTURE, UV + vec2(0.0, -size.y)).a;
    
    // Si estamos en un borde (alfa < 5.0) y queremos intensidad, pintamos el borde
    if (alpha < 5.0 && alpha > 0.0 && intensity > 0.0) {
        COLOR = rim_color;
    } else {
        COLOR = current_color;
    }
}