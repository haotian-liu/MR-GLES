#version 300 es

uniform mat4 MVPMatrix;
in vec3 vertPos;
void main() {
    gl_Position = MVPMatrix * vec4(vertPos, 1.f);
}
