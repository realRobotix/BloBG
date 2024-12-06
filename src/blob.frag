#version 300 es
precision highp float;

uniform vec2 iResolution;
uniform float iTime;
uniform vec3 uColor1;
uniform vec3 uColor2;
uniform bool uHSVMix;
out vec4 fragColor;

vec3 hsv2rgb(vec3 c){
    vec4 K=vec4(1.,2./3.,1./3.,3.);
    vec3 p=abs(fract(c.xxx+K.xyz)*6.-K.www);
    return c.z*mix(K.xxx,clamp(p-K.xxx,0.,1.),c.y);
}

vec3 channel_mix(vec3 a,vec3 b,vec3 w){
    return vec3(mix(a.r,b.r,w.r),mix(a.g,b.g,w.g),mix(a.b,b.b,w.b));
}

float gaussian(float z,float u,float o){
    return(1./(o*sqrt(2.*3.1415)))*exp(-(((z-u)*(z-u))/(2.*(o*o))));
}

vec3 overlay(vec3 a,vec3 b,float w){
    return mix(a,channel_mix(
        2.*a*b,
        vec3(1.)-2.*(vec3(1.)-a)*(vec3(1.)-b),
        step(vec3(.5),a)
    ),w);
}

vec3 mod289(vec3 x){
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 mod289(vec4 x){
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec4 permute(vec4 x){
    return mod289(((x*34.0)+10.0)*x);
}

vec4 taylorInvSqrt(vec4 r){
    return 1.79284291400159 - 0.85373472095314 * r;
}

float snoise(vec3 v){ 
    const vec2  C = vec2(1.0/6.0, 1.0/3.0) ;
    const vec4  D = vec4(0.0, 0.5, 1.0, 2.0);

    // First corner
    vec3 i  = floor(v + dot(v, C.yyy) );
    vec3 x0 =   v - i + dot(i, C.xxx) ;

    // Other corners
    vec3 g = step(x0.yzx, x0.xyz);
    vec3 l = 1.0 - g;
    vec3 i1 = min( g.xyz, l.zxy );
    vec3 i2 = max( g.xyz, l.zxy );
    vec3 x1 = x0 - i1 + C.xxx;
    vec3 x2 = x0 - i2 + C.yyy;
    vec3 x3 = x0 - D.yyy;

    // Permutations
    i = mod289(i); 
    vec4 p = permute( permute( permute( 
                i.z + vec4(0.0, i1.z, i2.z, 1.0 ))
            + i.y + vec4(0.0, i1.y, i2.y, 1.0 )) 
            + i.x + vec4(0.0, i1.x, i2.x, 1.0 ));

    // Gradients
    float n_ = 0.142857142857;
    vec3  ns = n_ * D.wyz - D.xzx;

    vec4 j = p - 49.0 * floor(p * ns.z * ns.z);

    vec4 x_ = floor(j * ns.z);
    vec4 y_ = floor(j - 7.0 * x_ );

    vec4 x = x_ *ns.x + ns.yyyy;
    vec4 y = y_ *ns.x + ns.yyyy;
    vec4 h = 1.0 - abs(x) - abs(y);

    vec4 b0 = vec4( x.xy, y.xy );
    vec4 b1 = vec4( x.zw, y.zw );

    vec4 s0 = floor(b0)*2.0 + 1.0;
    vec4 s1 = floor(b1)*2.0 + 1.0;
    vec4 sh = -step(h, vec4(0.0));

    vec4 a0 = b0.xzyw + s0.xzyw*sh.xxyy ;
    vec4 a1 = b1.xzyw + s1.xzyw*sh.zzww ;

    vec3 p0 = vec3(a0.xy,h.x);
    vec3 p1 = vec3(a0.zw,h.y);
    vec3 p2 = vec3(a1.xy,h.z);
    vec3 p3 = vec3(a1.zw,h.w);

    //Normalise gradients
    vec4 norm = taylorInvSqrt(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;

    // Mix final noise value
    vec4 m = max(0.5 - vec4(dot(x0,x0), dot(x1,x1), dot(x2,x2), dot(x3,x3)), 0.0);
    m = m * m;
    return 105.0 * dot( m*m, vec4( dot(p0,x0), dot(p1,x1), 
                                    dot(p2,x2), dot(p3,x3) ) );
}

void main(){
    vec2 uv=gl_FragCoord.xy/iResolution.xy;
    vec2 position=gl_FragCoord.xy/iResolution.xy;
    position.y=gl_FragCoord.y/1440.;
    position.x*=iResolution.x/1440.;
    
    float value=snoise(vec3(position*.9,iTime*.08));// single octave simplex noise
    value=((value+1.)*.5);// convert from range [-1, 1] to range [0, 1]
    value=1./(1.+pow(1.5,-30.*(value-.57)));// sigmoid function
    float colorMix=(snoise(vec3(position*.4,iTime*.05))+1.)*.5;

    vec4 color;
    if (uHSVMix){
        color=vec4(hsv2rgb(channel_mix(uColor1,uColor2,vec3(colorMix))),value);
    } else {
        color=vec4(channel_mix(hsv2rgb(uColor1),hsv2rgb(uColor2),vec3(colorMix)),value);
    }
    
    float variance=.8;
    
    // add film grain
    
    float t=iTime*.5;
    float grainSeed=dot(uv,vec2(12.9898,78.233));
    float noise=fract(sin(grainSeed)*43758.5453+t*2.);
    noise=gaussian(noise,0.,variance*variance);
    
    float w=.1;
    
    vec3 grain=vec3(noise)*(1.-color.rgb);
    
    color.rgb=overlay(color.rgb,grain,w);
    
    fragColor=color*min(iTime,1.);
}
