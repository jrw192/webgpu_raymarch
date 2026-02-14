fn shapeSDF(sArr: array<SDFOutput, 4>) -> SDFOutput {
    var closest = sArr[0];
    for (var i = 0; i < 4; i += 1) {
        closest = minSDF(closest, sArr[i]);
    }
    return closest;
}
fn iShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.2, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.4, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0, 0.6, 0)), vec3f(0.1,0.1,0.1), greenMat);

    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn lShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.2, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.4, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.2, 0, 0)), vec3f(0.1,0.1,0.1), greenMat);
    
    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn squareShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.2, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.4, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.2, 0, 0)), vec3f(0.1,0.1,0.1), greenMat);

    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn zShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.2, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0.2, 0.2, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.2, 0.4, 0)), vec3f(0.1,0.1,0.1), greenMat);

    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn sceneSDF(p: vec3f) -> SDFOutput {
    let lightMat = Material(vec4f(1, 1, 1, 10), MATERIAL_DIFFUSE_LIGHT);
    let light = boxSDF(translate(p, vec3f(0,0, -500.0)), vec3f(100, 100, 0.01), lightMat);
    
    let plainMat = Material(vec4f(1.0, 1.0, 1.0, 1.0), MATERIAL_LAMBERTIAN);
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);

    // let testPiece = zShape(translate(p, vec3f(0,0,-5.0)), plainMat);
    var closestObj = light;
    for (var i = 0u; i < params.x; i++) {
        let data = worldBlocks[i].pos;
        // shape encoded in data.w as float; cast to u32
        switch (u32(data.w)) {
            case 0u: {
                let piece = iShape(translate(p, data.xyz), plainMat);
                closestObj = minSDF(closestObj, piece);
            }
            case 1u: {
                let piece = lShape(translate(p, data.xyz), plainMat);
                closestObj = minSDF(closestObj, piece);
            }
            case 2u: {
                let piece = squareShape(translate(p, data.xyz), plainMat);
                closestObj = minSDF(closestObj, piece);
            }
            case default: {
                let piece = zShape(translate(p, data.xyz), plainMat);
                closestObj = minSDF(closestObj, piece);
            }
        }
    }

    return closestObj;
}