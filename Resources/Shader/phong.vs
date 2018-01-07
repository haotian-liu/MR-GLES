#version 300 es

uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform mat4 projectionMatrix;

in vec3 vertPos;
in vec3 vertNormal;
in vec3 vertUV;
in vec3 vertTangent;
in vec3 vertBitangent;

out vec2 texCoord;
out vec3 worldCoord;
out vec3 eyeCoord;
out vec3 normal;
out vec3 tangent;
out vec3 bitangent;

void main() {
    vec4 position = vec4(vertPos, 1.0f);

    vec4 worldPos = modelMatrix * position;
    vec4 eyePos = viewMatrix * worldPos;
    vec4 clipPos = projectionMatrix * eyePos;

    worldCoord = worldPos.xyz;
    eyeCoord = eyePos.xyz;
    texCoord = vertUV.xy;
    normal = normalize(mat3(viewMatrix * modelMatrix) * vertNormal);
    tangent = normalize(mat3(viewMatrix * modelMatrix) * vertTangent);
    bitangent = normalize(mat3(viewMatrix * modelMatrix) * vertBitangent);

    gl_Position = clipPos;
}
