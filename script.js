// Helper function to load shader files
async function loadShaders(urls) {
    const shaders = await Promise.all(urls.map(url =>
        fetch(url).then(res => {
            if (!res.ok) throw new Error(`Could not load ${url}`);
            return res.text();
        })
    ));

    return shaders.join('\n');
}

const FRAG_SHADERS = ['./utils.frag.wgsl', './tetris.frag.wgsl', './shader.frag.wgsl'];;

const GRID_DIMENSIONS = {x: 10, y: 10, z: 10};
const GRID_SIZE = GRID_DIMENSIONS.x * GRID_DIMENSIONS.y * GRID_DIMENSIONS.z;
const WORLD_SIZE = 4;

// builds list of all the pieces on the screen and their positions
function createWorld() {
    // pack as Float32Array of length WORLD_SIZE * 4
    // layout per element: [pos.x, pos.y, pos.z, shapeAsFloat]
    const arr = new Float32Array(WORLD_SIZE * 4);
    for (let i = 0; i < WORLD_SIZE; i++) {
        const base = i * 4;
        arr[base + 0] = Math.floor(Math.random() * 11) * 0.2 - 1; // x
        arr[base + 1] = 0.0; // y
        arr[base + 2] = Math.floor(Math.random() * 11) * 0.2 - 1; // z
        arr[base + 3] = i % 4; // shape (0 = I)
    }
    return arr;
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

    // ------------ uniform buffer for frame id ------------
    const uniformArray = new Uint32Array([1]); // Single number
    const uniformBuffer = device.createBuffer({
        label: "uniform buffer",
        size: 8,
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(uniformBuffer, 0, uniformArray);
    
    // ------------ uniform buffer for input params ------------
    const paramsArray = new Uint32Array([WORLD_SIZE]); // Single number
    const paramsBuffer = device.createBuffer({
        label: "params uniform buffer",
        size: 8,
        usage: GPUBufferUsage.UNIFORM | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(paramsBuffer, 0, paramsArray);

    // ------------ block buffer  ------------
    const blockArray = createWorld(); // Float32Array packed as [x,y,z,shapeFloat]

    const blockBuffer = device.createBuffer({
        label: "state buffer",
        size: blockArray.byteLength,
        usage: GPUBufferUsage.STORAGE | GPUBufferUsage.COPY_DST,
    });
    device.queue.writeBuffer(blockBuffer, 0, blockArray);

    // ------------ vertex + frag shader module ------------
    const vertexShaderCode = await loadShaders(['./shader.vert.wgsl']);
    const fragmentShaderCode = await loadShaders(FRAG_SHADERS);
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
        }, {
            binding: 1,
            visibility: GPUShaderStage.VERTEX | GPUShaderStage.FRAGMENT | GPUShaderStage.COMPUTE,
            buffer: {}
        }, {
            binding: 2,
            visibility: GPUShaderStage.FRAGMENT,
            buffer: {type: "read-only-storage"}
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
        {
            binding: 1,
            resource: { buffer: paramsBuffer }
        },
        {
            binding: 2,
            resource: { buffer: blockBuffer }
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

    const MAX_FRAMES = 1;
    for (let i = 0; i < MAX_FRAMES; i++) {
        setTimeout(() => draw(i), i * 300);
    }
}

main();