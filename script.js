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

    // ------------ uniform buffer ------------
    const uniformArray = new Uint32Array([1]); // Single number
    const uniformBuffer = device.createBuffer({
        label: "uniform buffer",
        size: 8,
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(uniformBuffer, 0, uniformArray);

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


    // ------------ set up bind groups ------------
    const bindGroupLayout = device.createBindGroupLayout({
        label: "bind group layout",
        entries: [{
            binding: 0,
            visibility: GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT | GPUShaderStage.COMPUTE,
            buffer: {}
        },
        ]
    });
    const pipelineLayout = device.createPipelineLayout({
        label: "pipeline layout",
        bindGroupLayouts: [bindGroupLayout],
    });

    const bindGroup = device.createBindGroup({
        label: "bind group",
        layout: bindGroupLayout,
        entries: [{
            binding: 0,
            resource: { buffer: uniformBuffer }
        },
        ],
    })

    // ------------ pipeline ------------
    const pipeline = device.createRenderPipeline({
        label: "pipeline",
        layout: pipelineLayout,
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

    function draw(i) {
        const encoder = device.createCommandEncoder();
        console.log('i', i);
        device.queue.writeBuffer(uniformBuffer, 0, new Uint32Array([i]));

        const pass = encoder.beginRenderPass({
            colorAttachments: [{
                view: context.getCurrentTexture().createView(),
                loadOp: "clear",
                clearValue: { r: 0, g: 0, b: 0.4, a: 1 },
                storeOp: "store",
            }]
        });
        pass.setBindGroup(0, bindGroup);

        pass.setPipeline(pipeline);
        pass.setVertexBuffer(0, vertexBuffer);
        pass.draw(vertices.length / 2); // 6 vertices

        pass.end();

        device.queue.submit([encoder.finish()]);
    }

    const MAX_FRAMES = 100;
    for (let i = 0; i < MAX_FRAMES; i++) {
        setTimeout(() => draw(i), i * 300);
    }
}

main();