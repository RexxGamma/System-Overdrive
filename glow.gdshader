shader_type canvas_item;

// Quitamos el uniform de color para que use el color nativo del nodo
// Usaremos COLOR que es el color que le pasas en el draw_line
void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);
    
    // El brillo blanco: si la distancia es pequeña, píntalo blanco
    vec3 glow_center = mix(vec3(1.0, 1.0, 1.0), COLOR.rgb, smoothstep(0.0, 0.3, dist));
    
    COLOR.rgb = glow_center;
}