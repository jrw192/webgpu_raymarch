struct ComputeInput {
    @builtin(global_invocation_id) id: vec3<u32>
}

@group(0) @binding(0) var outputTexture: texture_storage_2d<rgba16float, write>;
@group(0) @binding(1)
var<uniform> params: vec3u;
@group(0) @binding(2)
var<storage, read> worldBlocks: array<Block>;
@group(0) @binding(3)
var<storage, read_write> gameState: array<u32>;
@compute @workgroup_size(WORKGROUP_SIZE_PLACEHOLDER, WORKGROUP_SIZE_PLACEHOLDER, 1)
fn computeMain(input: ComputeInput) {
    let GRID_X = params[0];
    let GRID_Y = params[1];
    let GRID_Z = params[2];
    let activePiece = worldBlocks[0];

    // check if at bottom
    if (activePiece.pos.y == -1.0) {
        // write to state buffer
        let shape = u32(activePiece.pos.w);
        let coords = shapeCoords(shape);

        for (var i = 0; i < coords.length; i += 1) {
            let index = coord.x + (coord.y * f32(GRID_X)) + (coord.z * f32(GRID_X) * f32(GRID_Y));
            gameState[index] = 1;
        }
    }
}