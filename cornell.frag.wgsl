fn sceneSDF(p: vec3f) -> SDFOutput {
    let plainMat = Material(vec4f(1.0, 1.0, 1.0, 1.0), MATERIAL_LAMBERTIAN);
    let lightMat = Material(vec4f(1, 1, 1, 10), MATERIAL_DIFFUSE_LIGHT);
    let greenMat = Material(vec4f(0.0, 1.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let redMat = Material(vec4f(1.0, 0.0, 0.0, 1.0), MATERIAL_LAMBERTIAN);
    let sphere1 = sphereSDF(translate(p, vec3f(0.4, 0.3, 0.0)), 0.3, redMat);
    // let yPlane = planeSDF(p, vec3f(0,1,0), 1.0, plainMat);
    let box1 = boxSDF(rotateY(translate(p, vec3f(- 0.25, - 0.30, 0)), 10), vec3f(0.2, 0.45, 0.2), plainMat);
    let box2 = boxSDF(rotateY(translate(p, vec3f(0.25, - 0.55, - 0.5)), - 10), vec3f(0.2, 0.2, 0.2), plainMat);

    let wall1 = boxSDF(translate(p, vec3f(- 0.75, 0, 0)), vec3f(0.001, 2, 2), redMat);
    let wall2 = boxSDF(translate(p, vec3f(0.75, 0, 0)), vec3f(0.001, 2, 2), greenMat);
    let wall3 = boxSDF(translate(p, vec3f(0, 0.75, 0)), vec3f(2, 0.001, 2), plainMat);
    let wall4 = boxSDF(translate(p, vec3f(0, - 0.75, 0)), vec3f(2, 0.001, 2), plainMat);
    let wall5 = boxSDF(translate(p, vec3f(0, 0, 2)), vec3f(2, 2, 0.001), plainMat);

    let light = boxSDF(translate(p, vec3f(0, 0.7401, 0)), vec3f(0.25, 0.001, 0.25), lightMat);

    let world: array<SDFOutput, 8> = array(wall1, wall2, wall3, wall4, wall5, light, box1, box2);

    var best = world[0];
    for (var i: u32 = 1u; i < 8u; i = i + 1u) {
        best = minSDF(best, world[i]);
    }
    return best;
    // return sphere1;
}