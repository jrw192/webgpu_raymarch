fn shapeCoords(shape: u32) -> array<vec3f, 4> {
    switch (shape) {
        case 0u: { // I
            return array<vec3f, 4>(
                vec3f(0.0, 0.0, 0.0),
                vec3f(0.0, 0.1, 0.0),
                vec3f(0.0, 0.2, 0.0),
                vec3f(0.0, 0.3, 0.0)
            );
        }
        case 1u: { // L
            return array<vec3f, 4>(
                vec3f(0.0, 0.0, 0.0),
                vec3f(0.0, 0.1, 0.0),
                vec3f(0.0, 0.2, 0.0),
                vec3f(0.1, 0.0, 0.0)
            );
        }
        case 2u: { // square
            return array<vec3f, 4>(
                vec3f(0.0, 0.0, 0.0),
                vec3f(0.0, 0.1, 0.0),
                vec3f(0.1, 0.1, 0.0),
                vec3f(0.1, 0.0, 0.0)
            );
        }
        case default: { // Z
            return array<vec3f, 4>(
                vec3f(0.0, 0.0, 0.0),
                vec3f(0.0, 0.1, 0.0),
                vec3f(0.1, 0.1, 0.0),
                vec3f(0.1, 0.2, 0.0)
            );
        }
    }
}

fn shapeFromCoords(p: vec3f, m: Material, coords: array<vec3f, 4>) -> SDFOutput {
    var sArr: array<SDFOutput, 4>;
    for (var i = 0; i < 4; i += 1) {
        sArr[i] = boxSDF(translate(p, coords[i]), vec3f(0.05, 0.05, 0.05), m);
    }

    return shapeSDF(sArr);
}

fn shapeSDF(sArr: array<SDFOutput, 4>) -> SDFOutput {
    var closest = sArr[0];
    for (var i = 0; i < 4; i += 1) {
        closest = minSDF(closest, sArr[i]);
    }
    return closest;
}
fn iShape(p: vec3f, m: Material) -> SDFOutput {
    return shapeFromCoords(p, m, shapeCoords(0u));
}

fn lShape(p: vec3f, m: Material) -> SDFOutput {
    return shapeFromCoords(p, m, shapeCoords(1u));
}

fn squareShape(p: vec3f, m: Material) -> SDFOutput {
    return shapeFromCoords(p, m, shapeCoords(2u));
}

fn zShape(p: vec3f, m: Material) -> SDFOutput {
    return shapeFromCoords(p, m, shapeCoords(3u));
}

fn coordsToIndex(coord: vec3f, params: vec3u) -> i32 {
    let GRID_X = params[0];
    let GRID_Y = params[1];
    let GRID_Z = params[2];

    let ix = u32(round((coord.x + 1.0) / 0.2));
    let iy = u32(round((-1.0 + 1.0) / 0.2));
    let iz = u32(round((coord.z + 1.0) / 0.2));
    if (ix >= params.x || iy >= params.y || iz >= params.z) {
        return -1;
    }
    let index = ix + (iy * GRID_X) + (iz * GRID_X * GRID_Y);

    return i32(index);
}

fn indexToCoords(index: u32, params: vec3u) -> vec3f {
    let GRID_X = params[0];
    let GRID_Y = params[1];
    
    let ix = index % GRID_X;
    let iy = (index / GRID_X) % GRID_Y;
    let iz = index / (GRID_X * GRID_Y);

    let x = (f32(ix) * 0.2) - 1.0;
    let y = (f32(iy) * 0.2) - 1.0;
    let z = (f32(iz) * 0.2) - 1.0;

    return vec3f(x, y, z);
}

fn gameStateShape(p: vec3f, state: vec2<u32>, params: vec3u, m: Material) -> SDFOutput {
    // var sdf = boxSDF(vec3f(1000,1000,1000), vec3f(0.05, 0.05, 0.05), m);
    // for (var i = 0u; i < 1000; i+= 1) {
    //     let val = state[i];

    //     if (val == 1) {
    //         let coords = indexToCoords(i, params);
    //         let box = boxSDF(p, vec3f(0.05, 0.05, 0.05), m);
    //         sdf = minSDF(sdf, box);
    //     }
    // }
    // return sdf;

    let pIndex = coordsToIndex(p, params);
    if (pIndex < 0) {
        return SDFOutput(1000, m);
    }
    let val = state[pIndex];
    if (val == 1) {
        let box = boxSDF(p, vec3f(0.05, 0.05, 0.05), m);
        return box;
    }

    return SDFOutput(0.2, m);
}