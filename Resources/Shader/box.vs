#version 300 es

uniform mat4 MVPMatrix;
in vec3 vertPos;
in vec3 vertNormal;
in vec3 vertUV;
out vec3 normal;
out vec3 UV;
void main() {
    normal = vertNormal;
    UV = vertUV;
    gl_Position = MVPMatrix * vec4(vertPos, 1.f);
}
