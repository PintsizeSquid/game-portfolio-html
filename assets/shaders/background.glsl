#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_pixelHeight;

// Rotation matrix around the Y axis.
mat3 rotateY(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(c, 0, s),
        vec3(0, 1, 0),
        vec3(-s, 0, c)
    );
}

// Rotation matrix around the X axis.
mat3 rotateX(float theta) {
    float c = cos(theta);
    float s = sin(theta);
    return mat3(
        vec3(1, 0, 0),
        vec3(0, c, -s),
        vec3(0, s, c)
    );
}

// Signed distance function for a cube
float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

// Ray marching function
float raymarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    for(int i = 0; i < 64; i++) {
        vec3 p = ro + rd * t;
        // Apply rotation to the point
        p = rotateY(u_time) * rotateX(u_time * 0.5) * p;
        float d = sdBox(p, vec3(0.6));
        if(d < 0.001) break;
        t += d;
        if(t > 20.0) break;
    }
    return t;
}

// Calculate normal
vec3 getNormal(vec3 p) {
    float d = sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * p, vec3(0.6));
    vec2 e = vec2(0.001, 0.0);
    vec3 n = d - vec3(
        sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * (p - e.xyy), vec3(0.6)),
        sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * (p - e.yxy), vec3(0.6)),
        sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * (p - e.yyx), vec3(0.6))
    );
    return normalize(n);
}

// Calculate luminance
float luma(vec3 color) {
    return dot(color, vec3(0.299, 0.587, 0.114));
}

// ASCII character rendering
float character(float n, vec2 p) {
    p = floor(p*vec2(4.0, -4.0) + 2.5);
    if (clamp(p.x, 0.0, 4.0) == p.x && clamp(p.y, 0.0, 4.0) == p.y) {
        if (int(mod(n/exp2(p.x + 5.0*p.y), 2.0)) == 1) return 1.0;
    }
    return 0.0;
}

float asciiFilter(vec3 color, vec2 uv, float pixelSize) {
    float threshold = luma(color);
    float n = 0.0;                      // Black (no character)
    if (threshold > 0.2) n = 65536.0;   // .
    if (threshold > 0.3) n = 65600.0;    // :
    if (threshold > 0.4) n = 332772.0;   // *
    if (threshold > 0.5) n = 15255086.0; // o
    if (threshold > 0.6) n = 23385164.0; // &
    if (threshold > 0.7) n = 15252014.0; // 8
    if (threshold > 0.8) n = 13199452.0; // @
    if (threshold > 0.9) n = 11512810.0; // #
    vec2 p = mod(uv / (pixelSize * 0.5), 2.0) - vec2(1.0);
    return character(n, p);
}

void main() {
    // Get normalized coordinates
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    
    // Calculate aspect ratio to maintain square pixels
    float aspectRatio = u_resolution.x/u_resolution.y;
    
    // Convert to screen space (-1 to 1)
    vec2 screenPos = (st * 2.0 - 1.0) * vec2(aspectRatio, 1.0);
    
    // Ray origin and direction
    vec3 ro = vec3(0.0, -.5, -2.5);
    vec3 rd = normalize(vec3(screenPos, 1.0));
    
    // Ray march
    float t = raymarch(ro, rd);
    
    // Base colors
    vec3 color1 = vec3(0.0, 0.0, 0.0); // Pure black background
    vec3 color2 = vec3(0.310, 0.616, 0.412); // Cube color
    
    // Final color
    vec3 color = color1;
    
    // If we hit the cube
    if(t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 normal = getNormal(p);
        
        // Multiple light sources for better visibility
        vec3 lightDir1 = normalize(vec3(1.0, 1.0, -1.0));
        vec3 lightDir2 = normalize(vec3(-1.0, 0.5, -0.5));
        vec3 lightDir3 = normalize(vec3(0.5, -1.0, -0.5));
        
        // Calculate diffuse lighting from multiple sources
        float diff1 = max(dot(normal, lightDir1), 0.0);
        float diff2 = max(dot(normal, lightDir2), 0.0) * 0.5;
        float diff3 = max(dot(normal, lightDir3), 0.0) * 0.3;
        
        // Combine lighting with higher ambient term
        float totalDiff = diff1 + diff2 + diff3;
        float ambient = 0.4; // Increased ambient lighting
        
        // Mix cube color with lighting
        color = color2 * (totalDiff * 0.8 + ambient);
    }
    
    // Calculate pixel size maintaining aspect ratio
    float pixelSize = 1.0 / u_pixelHeight;
    vec2 asciiUV = st * vec2(aspectRatio, 1.0);
    
    // Apply ASCII filter with adjusted UV coordinates
    float ascii = asciiFilter(color, asciiUV, pixelSize);
    
    // Use the primary accent color for ASCII characters
    vec3 accentColor = vec3(0.310, 0.616, 0.412);
    color = accentColor * ascii;
    
    gl_FragColor = vec4(color, 1.0);
} 