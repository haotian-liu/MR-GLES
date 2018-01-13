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

float getShadowFactor(vec4 lightZ) {
    vec4 packedZValue = texture(depthTexture, lightZ.st);
    float unpackedZValue = unpack(packedZValue);
    return float(unpackedZValue > lightZ.z);
}

void main() {
    vec4 shadowMapPosition = shadowCoord / shadowCoord.w;
    float depth = (shadowCoord.z / shadowCoord.w + 1.0) / 2.0;
    vec4 dist_pack = texture(depthTexture, shadowCoord.xy);
    vec4 f = dist_pack;

    color = vec4(vec3(f), 1.f - f);
}
