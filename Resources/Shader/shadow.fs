#version 300 es

precision highp float;
precision highp sampler2D;

uniform sampler2D depthTexture;

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
    color = isShadow ? vec4(0.3f) : vec4(0.f);
}
