// https://iquilezles.org/articles/normalsSDF/
// tetrahedron technique
fn getNormal(p: vec3f) -> vec3f {
    let h = 0.0001;
    let k = vec2f(1.0, - 1.0);

    return normalize(k.xyy * sceneSDF(p + k.xyy * h).dist + k.yyx * sceneSDF(p + k.yyx * h).dist + k.yxy * sceneSDF(p + k.yxy * h).dist + k.xxx * sceneSDF(p + k.xxx * h).dist);
}