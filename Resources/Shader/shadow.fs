#version 300 es

precision highp float;
precision highp sampler2D;

uniform sampler2D depthTexture;
uniform float timeVariant;

in vec4 shadowCoord;
layout (location = 0) out vec4 color;

float unpack(vec4 packedZValue) {
    const vec4 unpackFactors = vec4( 1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0 );
    return dot(packedZValue,unpackFactors);
}

void main() {
    vec4 shadowMapPosition = shadowCoord / shadowCoord.w;
    float depth = (shadowCoord.z / shadowCoord.w + 1.0) / 2.0;
    vec4 dist_pack = texture(depthTexture, shadowCoord.xy);
    bool isShadow = unpack(dist_pack) < depth;
    if (!isShadow && timeVariant < 0.001f) {
        discard;
    }
    color = isShadow ? vec4(0.4f) : vec4(timeVariant > 1.f ? 0.4f : timeVariant * 0.4f);
}
