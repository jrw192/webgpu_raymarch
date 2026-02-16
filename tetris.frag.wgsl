fn sceneSDF(p: vec3f) -> SDFOutput {
    let lightMat = Material(vec4f(1, 1, 1, 10), MATERIAL_DIFFUSE_LIGHT);
    let light = boxSDF(translate(p, vec3f(0,0, -500.0)), vec3f(100, 100, 0.01), lightMat);
    
    let plainMat = Material(vec4f(1.0, 1.0, 1.0, 1.0), MATERIAL_LAMBERTIAN);
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let stateSDF = gameStateShape(p, state, params, plainMat);

    // let testPiece = zShape(translate(p, vec3f(0,0,-5.0)), plainMat);
    var closestObj = light;
        let data = worldBlocks[0].pos;
        // shape encoded in data.w as float; cast to u32
        switch (u32(data.w)) {
            case 0u: {
                let piece = iShape(translate(p, data.xyz), greenMat);
                closestObj = minSDF(closestObj, piece);
            }
            case 1u: {
                let piece = lShape(translate(p, data.xyz), greenMat);
                closestObj = minSDF(closestObj, piece);
            }
            case 2u: {
                let piece = squareShape(translate(p, data.xyz), greenMat);
                closestObj = minSDF(closestObj, piece);
            }
            case default: {
                let piece = zShape(translate(p, data.xyz), greenMat);
                closestObj = minSDF(closestObj, piece);
            }
        }
    

    // return closestObj;
    return minSDF(stateSDF, light);
}