#ifdef GL_ES
precision mediump float;
#endif

uniform vec2 u_resolution;
uniform float u_time;
uniform float u_pixelHeight; // Number of vertical pixels we want

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
        float d = sdBox(p, vec3(0.6)); // Doubled size from 0.3 to 0.6
        if(d < 0.001) break;
        t += d;
        if(t > 20.0) break;
    }
    return t;
}

// Calculate normal
vec3 getNormal(vec3 p) {
    float d = sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * p, vec3(0.6)); // Doubled size from 0.3 to 0.6
    vec2 e = vec2(0.001, 0.0);
    vec3 n = d - vec3(
        sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * (p - e.xyy), vec3(0.6)), // Doubled size from 0.3 to 0.6
        sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * (p - e.yxy), vec3(0.6)), // Doubled size from 0.3 to 0.6
        sdBox(rotateY(u_time) * rotateX(u_time * 0.5) * (p - e.yyx), vec3(0.6))  // Doubled size from 0.3 to 0.6
    );
    return normalize(n);
}

void main() {
    // Get normalized coordinates
    vec2 st = gl_FragCoord.xy/u_resolution.xy;
    
    // Calculate aspect ratio to maintain square pixels
    float aspectRatio = u_resolution.x/u_resolution.y;
    
    // Pixelation effect
    // Use u_pixelHeight for vertical resolution and adjust horizontal by aspect ratio
    vec2 pixels = vec2(u_pixelHeight * aspectRatio, u_pixelHeight);
    st = floor(st * pixels) / pixels;
    
    // Convert to screen space (-1 to 1)
    vec2 screenPos = (st * 2.0 - 1.0) * vec2(aspectRatio, 1.0);
    
    // Ray origin and direction
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec3 rd = normalize(vec3(screenPos, 1.0));
    
    // Ray march
    float t = raymarch(ro, rd);
    
    // Base colors
    vec3 color1 = vec3(0.224, 0.243, 0.255); // Background color
    vec3 color2 = vec3(0.310, 0.616, 0.412); // Cube color
    
    // Final color
    vec3 color = color1;
    
    // If we hit the cube
    if(t < 20.0) {
        vec3 p = ro + rd * t;
        vec3 normal = getNormal(p);
        
        // Simple lighting
        vec3 lightDir = normalize(vec3(1.0, 1.0, -1.0));
        float diff = max(dot(normal, lightDir), 0.0);
        
        // Mix cube color with lighting
        color = color2 * (diff * 0.8 + 0.2);
    }
    
    gl_FragColor = vec4(color, 1.0);
} 