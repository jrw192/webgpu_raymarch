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
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.42, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0, 0.64, 0)), vec3f(0.1,0.1,0.1), greenMat);

    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn lShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.42, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.21, 0, 0)), vec3f(0.1,0.1,0.1), greenMat);
    
    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn squareShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.42, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.21, 0, 0)), vec3f(0.1,0.1,0.1), greenMat);

    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn zShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0.21, 0.21, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.21, 0.42, 0)), vec3f(0.1,0.1,0.1), greenMat);

    let sArr: array<SDFOutput, 4> = array(s1,s2,s3,s4);
    
    return shapeSDF(sArr);
}

fn sceneSDF(p: vec3f) -> SDFOutput {
    let lightMat = Material(vec4f(1, 1, 1, 10), MATERIAL_DIFFUSE_LIGHT);
    let light = boxSDF(vec3f(0, 0, -500.0), vec3f(100, 100, 0.01), lightMat);

    let m = Material(vec4f(1.0, 1.0, 1.0, 1.0), MATERIAL_LAMBERTIAN);
    var closestObj = light;
    for (var i: u32 = 1u; i < params.x; i = i + 1u) {
        let data = worldBlocks[i].pos;
        // shape encoded in data.w as float; cast to u32
        switch (u32(data.w)) {
            case 0u: {
                let piece = iShape(data.xyz, m);
                closestObj = minSDF(closestObj, piece);
            }
            case 1u: {
                let piece = lShape(data.xyz, m);
                closestObj = minSDF(closestObj, piece);
            }
            case 2u: {
                let piece = squareShape(data.xyz, m);
                closestObj = minSDF(closestObj, piece);
            }
            case default: {
                let piece = zShape(data.xyz, m);
                closestObj = minSDF(closestObj, piece);
            }
        }
    }
    // return closestObj;
    let piece = iShape(vec3f(0,0,0), m);
    return minSDF(light, piece);
}