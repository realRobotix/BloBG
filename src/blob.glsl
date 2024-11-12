#version 300 es
precision highp float;

uniform vec2 iResolution;
uniform float iTime;
out vec4 fragColor;

vec3 channel_mix(vec3 a, vec3 b, vec3 w) {
    return vec3(mix(a.r, b.r, w.r), mix(a.g, b.g, w.g), mix(a.b, b.b, w.b));
}

float gaussian(float z, float u, float o) {
    return (1.0 / (o * sqrt(2.0 * 3.1415))) * exp(-(((z - u) * (z - u)) / (2.0 * (o * o))));
}

vec3 overlay(vec3 a, vec3 b, float w) {
    return mix(a, channel_mix(
        2.0 * a * b,
        vec3(1.0) - 2.0 * (vec3(1.0) - a) * (vec3(1.0) - b),
        step(vec3(0.5), a)
    ), w);
}


// MurmurHash (https://en.wikipedia.org/wiki/MurmurHash)

uint hash(uint x, uint seed) {
    const uint m = 0x5bd1e995U;
    uint hash = seed;
    // process input
    uint k = x;
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // some final mixing
    hash ^= hash >> 13;
    hash *= m;
    hash ^= hash >> 15;
    return hash;
}

uint hash(uvec3 x, uint seed){
    const uint m = 0x5bd1e995U;
    uint hash = seed;
    // process first vector element
    uint k = x.x; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // process second vector element
    k = x.y; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
    // process third vector element
    k = x.z; 
    k *= m;
    k ^= k >> 24;
    k *= m;
    hash *= m;
    hash ^= k;
	// some final mixing
    hash ^= hash >> 13;
    hash *= m;
    hash ^= hash >> 15;
    return hash;
}


vec3 gradientDirection(uint hash) {
    switch (int(hash) & 15) {
    case 0:
        return vec3(1, 1, 0);
    case 1:
        return vec3(-1, 1, 0);
    case 2:
        return vec3(1, -1, 0);
    case 3:
        return vec3(-1, -1, 0);
    case 4:
        return vec3(1, 0, 1);
    case 5:
        return vec3(-1, 0, 1);
    case 6:
        return vec3(1, 0, -1);
    case 7:
        return vec3(-1, 0, -1);
    case 8:
        return vec3(0, 1, 1);
    case 9:
        return vec3(0, -1, 1);
    case 10:
        return vec3(0, 1, -1);
    case 11:
        return vec3(0, -1, -1);
    case 12:
        return vec3(1, 1, 0);
    case 13:
        return vec3(-1, 1, 0);
    case 14:
        return vec3(0, -1, 1);
    case 15:
        return vec3(0, -1, -1);
    }
}

float interpolate(float value1, float value2, float value3, float value4, float value5, float value6, float value7, float value8, vec3 t) {
    return mix(
        mix(mix(value1, value2, t.x), mix(value3, value4, t.x), t.y),
        mix(mix(value5, value6, t.x), mix(value7, value8, t.x), t.y),
        t.z
    );
}

vec3 fade(vec3 t) {
    // 6t^5 - 15t^4 + 10t^3
	return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float perlinNoise(vec3 position, uint seed) {
    vec3 floorPosition = floor(position);
    vec3 fractPosition = position - floorPosition;
    uvec3 cellCoordinates = uvec3(floorPosition);
    float value1 = dot(gradientDirection(hash(cellCoordinates, seed)), fractPosition);
    float value2 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 0, 0)), seed)), fractPosition - vec3(1, 0, 0));
    float value3 = dot(gradientDirection(hash((cellCoordinates + uvec3(0, 1, 0)), seed)), fractPosition - vec3(0, 1, 0));
    float value4 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 1, 0)), seed)), fractPosition - vec3(1, 1, 0));
    float value5 = dot(gradientDirection(hash((cellCoordinates + uvec3(0, 0, 1)), seed)), fractPosition - vec3(0, 0, 1));
    float value6 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 0, 1)), seed)), fractPosition - vec3(1, 0, 1));
    float value7 = dot(gradientDirection(hash((cellCoordinates + uvec3(0, 1, 1)), seed)), fractPosition - vec3(0, 1, 1));
    float value8 = dot(gradientDirection(hash((cellCoordinates + uvec3(1, 1, 1)), seed)), fractPosition - vec3(1, 1, 1));
    return interpolate(value1, value2, value3, value4, value5, value6, value7, value8, fade(fractPosition));
}

float perlinNoise(vec3 position, int frequency, int octaveCount, float persistence, float lacunarity, uint seed) {
    float value = 0.0;
    float amplitude = 1.0;
    float currentFrequency = float(frequency);
    uint currentSeed = seed;
    for (int i = 0; i < octaveCount; i++) {
        currentSeed = hash(currentSeed, 0x0U); // create a new seed for each octave
        value += perlinNoise(position * currentFrequency, currentSeed) * amplitude;
        amplitude *= persistence;
        currentFrequency *= lacunarity;
    }
    return value;
}

void main() {
    vec2 ps = vec2(1.0) / iResolution.xy;
    //vec2 uv = gl_FragCoord.xy * ps;
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    vec2 noResolution = vec2(1920.0, 1080.0);
    vec2 position = gl_FragCoord.xy / iResolution.xy;
    position.y = gl_FragCoord.y / 1440.0;
    position.x *= iResolution.x / 1440.0;
    //position.y *= iResolution.x / iResolution.y;
    uint seed = 0x578437adU; // starting point
    float frequency = 2.0;
    float colorFrequency = 0.5;
    float value = perlinNoise(vec3(position * 1.3, iTime * 0.17), seed); // single octave perlin noise
    //float value = perlinNoise(vec3(position, iTime * 0.1), 1, 16, 0.1, 2.0, seed); // multiple octaves
    value = ((value + 1.0) * 0.5); // convert from range [-1, 1] to range [0, 1]
    value = 1.0/(1.0+pow(2.0, -30.0*(value - 0.57))); // sigmoid function
    float rMul = 0.85;
    float gMul = 0.6;
    float bMul = 1.2;
    vec4 color =vec4((perlinNoise(vec3(position, iTime * 0.1) * colorFrequency, hash(seed, 0x0U)) + 1.0) * 0.5 * rMul,
                (perlinNoise(vec3(position, iTime * 0.1) * colorFrequency, hash(hash(seed, 0x0U), 0x0U)) + 1.0) * 0.5 * gMul,
                (perlinNoise(vec3(position, iTime * 0.1) * colorFrequency, hash(hash(hash(seed, 0x0U), 0x0U), 0x0U)) + 1.0) * 0.5 * bMul,
                1.0) * value;  //this could be made ~3x faster by converting from hsl/hsv to rgb

    float variance = 0.8;
    
    // add film grain

    float t = iTime * 0.5;
    float grainSeed = dot(uv, vec2(12.9898, 78.233));
    float noise = fract(sin(grainSeed) * 43758.5453 + t*2.0);
    noise = gaussian(noise, 0.0, variance * variance);

    float w = 0.1;
	
    vec3 grain = vec3(noise) * (1.0 - color.rgb);
    
    color.rgb = overlay(color.rgb, grain, w);

    //color = vec4(vec3(noise), 1.0);
    
    fragColor = color * min(iTime, 1.0);
}
