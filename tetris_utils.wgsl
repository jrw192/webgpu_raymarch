fn shapeCoords(shape: u32) -> array<vec3f, 4> {
    // Return the local offsets of the 4 boxes that make up each tetromino
    // These match the translations used in the corresponding *Shape SDF functions.
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
                vec3f(0.0, 0.2, 0.0),
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