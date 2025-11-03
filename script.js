// Helper function to load shader files
async function loadShader(url) {
    const response = await fetch(url);
    if (!response.ok) {
        throw new Error(`Failed to load shader: ${url}`);
    }
    return await response.text();
}

async function main(gridSize) {
    // ------------ setup ------------
    const canvas = document.querySelector("canvas");
    if (!navigator.gpu) {
        alert("WebGPU not supported on this browser.");
        throw new Error("WebGPU not supported on this browser.");
    }

    const adapter = await navigator.gpu.requestAdapter();
    if (!adapter) {
        throw new Error("No appropriate GPUAdapter found.");
    }
    const device = await adapter.requestDevice();

    const context = canvas.getContext("webgpu");
    const canvasFormat = navigator.gpu.getPreferredCanvasFormat();
    context.configure({
        device: device,
        format: canvasFormat,
    });

    const vertices = new Float32Array([
        //   X,    Y,
        -0.8, -0.8, // Triangle 1 (Blue)
        0.8, -0.8,
        0.8, 0.8,

        -0.8, -0.8, // Triangle 2 (Red)
        0.8, 0.8,
        -0.8, 0.8,
    ]);


    // ------------ buffers ------------
    const vertexBufferLayout = {
        arrayStride: 8,
        attributes: [{
            format: "float32x2",
            offset: 0,
            shaderLocation: 0,
        }],
    };

    const vertexBuffer = device.createBuffer({
        label: "vertices",
        size: vertices.byteLength,
        usage: GPUBufferUsage.VERTEX | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(vertexBuffer, /*bufferOffset=*/0, vertices);

    // ------------ vertex + frag shader module ------------
    const vertexShaderCode = await loadShader('./shader.vert.wgsl');
    const fragmentShaderCode = await loadShader('./shader.frag.wgsl');
    const combinedShaderCode = vertexShaderCode + '\n\n' + fragmentShaderCode;

    const shaderModule = device.createShaderModule({
        label: "shader module",
        code: combinedShaderCode
    });

    // ------------ compute shader ------------
    // const WORKGROUP_SIZE = 8;
    // let computeShaderCode = await loadShader('./shader.compute.wgsl');
    // computeShaderCode = computeShaderCode.replace(/WORKGROUP_SIZE_PLACEHOLDER/g, WORKGROUP_SIZE.toString());

    // const computeShaderModule = device.createShaderModule({
    //     label: "compute shader module",
    //     code: computeShaderCode
    // });


    // ------------ pipeline ------------
    const pipeline = device.createRenderPipeline({
        label: "pipeline",
        layout: "auto",
        vertex: {
            module: shaderModule,
            entryPoint: "vertexMain",
            buffers: [vertexBufferLayout]
        },
        fragment: {
            module: shaderModule,
            entryPoint: "fragmentMain",
            targets: [{
                format: canvasFormat
            }]
        }
    });





    // ------------ drawing ------------
    const encoder = device.createCommandEncoder();

    const pass = encoder.beginRenderPass({
        colorAttachments: [{
            view: context.getCurrentTexture().createView(),
            loadOp: "clear",
            clearValue: { r: 0, g: 0, b: 0.4, a: 1 },
            storeOp: "store",
        }]
    });

    pass.setPipeline(pipeline);
    pass.setVertexBuffer(0, vertexBuffer);
    pass.draw(vertices.length / 2); // 6 vertices

    pass.end();

    device.queue.submit([encoder.finish()]);
}

main();