class ShaderBackground {
    constructor(canvasId) {
        this.canvas = document.getElementById(canvasId);
        this.gl = this.canvas.getContext('webgl');
        
        if (!this.gl) {
            console.error('WebGL not supported');
            return;
        }

        this.startTime = Date.now();
        this.targetPixelHeight = 128;
        this.init();
    }

    async init() {
        // Load shader source
        const response = await fetch('/assets/shaders/background.glsl');
        const fragmentShaderSource = await response.text();
        
        // Vertex shader source
        const vertexShaderSource = `
            attribute vec2 a_position;
            void main() {
                gl_Position = vec4(a_position, 0.0, 1.0);
            }
        `;

        // Create shaders
        const vertexShader = this.createShader(this.gl.VERTEX_SHADER, vertexShaderSource);
        const fragmentShader = this.createShader(this.gl.FRAGMENT_SHADER, fragmentShaderSource);

        // Create program
        this.program = this.createProgram(vertexShader, fragmentShader);

        // Look up uniform locations
        this.resolutionLocation = this.gl.getUniformLocation(this.program, "u_resolution");
        this.timeLocation = this.gl.getUniformLocation(this.program, "u_time");
        this.pixelHeightLocation = this.gl.getUniformLocation(this.program, "u_pixelHeight");

        // Create buffer for position
        const positionBuffer = this.gl.createBuffer();
        const positions = new Float32Array([
            -1.0, -1.0,
             1.0, -1.0,
            -1.0,  1.0,
             1.0,  1.0,
        ]);

        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, positionBuffer);
        this.gl.bufferData(this.gl.ARRAY_BUFFER, positions, this.gl.STATIC_DRAW);

        // Look up position attribute location
        const positionLocation = this.gl.getAttribLocation(this.program, "a_position");
        this.gl.enableVertexAttribArray(positionLocation);
        this.gl.vertexAttribPointer(positionLocation, 2, this.gl.FLOAT, false, 0, 0);

        this.resize();
        window.addEventListener('resize', () => this.resize());
        this.render();
    }

    createShader(type, source) {
        const shader = this.gl.createShader(type);
        this.gl.shaderSource(shader, source);
        this.gl.compileShader(shader);

        if (!this.gl.getShaderParameter(shader, this.gl.COMPILE_STATUS)) {
            console.error('Shader compile error:', this.gl.getShaderInfoLog(shader));
            this.gl.deleteShader(shader);
            return null;
        }

        return shader;
    }

    createProgram(vertexShader, fragmentShader) {
        const program = this.gl.createProgram();
        this.gl.attachShader(program, vertexShader);
        this.gl.attachShader(program, fragmentShader);
        this.gl.linkProgram(program);

        if (!this.gl.getProgramParameter(program, this.gl.LINK_STATUS)) {
            console.error('Program link error:', this.gl.getProgramInfoLog(program));
            return null;
        }

        return program;
    }

    resize() {
        const realToCSSPixels = window.devicePixelRatio;
        const displayWidth = Math.floor(this.canvas.clientWidth * realToCSSPixels);
        const displayHeight = Math.floor(this.canvas.clientHeight * realToCSSPixels);

        if (this.canvas.width !== displayWidth || this.canvas.height !== displayHeight) {
            this.canvas.width = displayWidth;
            this.canvas.height = displayHeight;
            this.gl.viewport(0, 0, this.gl.canvas.width, this.gl.canvas.height);
        }
    }

    render() {
        // Use shader program
        this.gl.useProgram(this.program);

        // Update uniforms
        this.gl.uniform2f(this.resolutionLocation, this.gl.canvas.width, this.gl.canvas.height);
        this.gl.uniform1f(this.timeLocation, (Date.now() - this.startTime) * 0.001);
        this.gl.uniform1f(this.pixelHeightLocation, this.targetPixelHeight);

        // Draw
        this.gl.drawArrays(this.gl.TRIANGLE_STRIP, 0, 4);

        // Request next frame
        requestAnimationFrame(() => this.render());
    }
}

// Initialize shader background when DOM is loaded
document.addEventListener('DOMContentLoaded', () => {
    new ShaderBackground('shader-canvas');
}); 