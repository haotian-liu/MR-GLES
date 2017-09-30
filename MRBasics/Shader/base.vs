#version 300 es

in vec3 vertPos;
void main() {
    gl_Position = vec4(vertPos, 1.f);
}
