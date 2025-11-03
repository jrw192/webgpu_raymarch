struct ComputeInput {
    @builtin(global_invocation_id) id: vec3<u32>
}


@group(0) @binding(0) var outputTexture: texture_storage_2d<rgba16float, write>;
@compute @workgroup_size(WORKGROUP_SIZE_PLACEHOLDER, WORKGROUP_SIZE_PLACEHOLDER, 1)
fn computeMain(input: ComputeInput) {
}