
fn iShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.42, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0, 0.64, 0)), vec3f(0.1,0.1,0.1), greenMat);

    return getMin(array(s1,s2,s3,s4,EMPTY,EMPTY,EMPTY,EMPTY), 4);
}

fn lShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.42, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.21, 0, 0)), vec3f(0.1,0.1,0.1), greenMat);

    return getMin(array(s1,s2,s3,s4,EMPTY,EMPTY,EMPTY,EMPTY), 4);
}

fn squareShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0, 0.42, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.21, 0, 0)), vec3f(0.1,0.1,0.1), greenMat);

    return getMin(array(s1,s2,s3,s4,EMPTY,EMPTY,EMPTY,EMPTY), 4);
}

fn zShape(p: vec3f, m: Material) -> SDFOutput {
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let s1 = boxSDF(p, vec3f(0.1,0.1,0.1), m); 
    let s2 = boxSDF(translate(p, vec3f(0, 0.21, 0)), vec3f(0.1,0.1,0.1), greenMat);
    let s3 = boxSDF(translate(p, vec3f(0.21, 0.21, 0)), vec3f(0.1,0.1,0.1), m);
    let s4 = boxSDF(translate(p, vec3f(0.21, 0.42, 0)), vec3f(0.1,0.1,0.1), greenMat);

    return getMin(array(s1,s2,s3,s4,EMPTY,EMPTY,EMPTY,EMPTY), 4);
}

fn sceneSDF(p: vec3f) -> SDFOutput {
    let lightMat = Material(vec4f(1, 1, 1, 10), MATERIAL_DIFFUSE_LIGHT);
    let light = boxSDF(translate(p, vec3f(0,0, -500.0)), vec3f(100, 100, 0.01), lightMat);
    
    let plainMat = Material(vec4f(1.0, 1.0, 1.0, 1.0), MATERIAL_LAMBERTIAN);

    let iPiece = zShape(translate(p, vec3f(0,0,-5.0)), plainMat);

    let world: array<SDFOutput, 8> = array(light, iPiece, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY, EMPTY);

    return getMin(world, 2);
}