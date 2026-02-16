const MATERIAL_LAMBERTIAN: u32 = 0u;
const MATERIAL_DIFFUSE_LIGHT: u32 = 1u;

struct Material {
    color: vec4f,
    matType: u32,
}

struct SDFOutput {
    dist: f32,
    material: Material,
}

struct Block {
    // pack position in xyz and encode shape in w as a float to avoid
    // alignment/padding mismatches between JS and WGSL
    pos: vec4<f32>,
}


const EMPTY = SDFOutput(1000.0, Material(vec4f(1.0, 1.0, 1.0, 1.0), MATERIAL_LAMBERTIAN));

// -------------------------- SDFs --------------------------

fn sphereSDF(p: vec3f, s: f32, m: Material) -> SDFOutput {
    // return length(p) - s;
    return SDFOutput(length(p) - s, m);
}

fn boxSDF(p: vec3f, b: vec3f, m: Material) -> SDFOutput {
    let q = abs(p) - b;
    let dist = length(max(q, vec3f(0.0, 0.0, 0.0))) + min(max(q.x, max(q.y, q.z)), 0);
    return SDFOutput(dist, m);
}

fn planeSDF(p: vec3f, n: vec3f, h: f32, m: Material) -> SDFOutput {
    let dist = dot(p, n) + h;
    return SDFOutput(dist, m);
}

fn translate(p: vec3f, t: vec3f) -> vec3f {
    return p - t;
}

const PI: f32 = radians(180.0);

fn rotateY(p: vec3f, a: f32) -> vec3f {
    let theta = (PI / 100) * a;
    let sinTheta = sin(theta);
    let cosTheta = cos(theta);
    return vec3f((cosTheta * p.x) + (sinTheta * p.z), p.y, (- sinTheta * p.x) + (cosTheta * p.z));
}

fn minSDF(a: SDFOutput, b: SDFOutput) -> SDFOutput {
    if (a.dist < b.dist) {
        return a;
    }
    return b;
}


fn getRandomInUnitSphere(seed: vec2f) -> vec3f {
    var r1 = rand(seed);
    var r2 = rand(seed + vec2f(1.0, 1.0));
    var r3 = rand(seed + vec2f(-1.0, -1.0));
    let remapped = vec3f(r1,r2,r3) * 2.0 - 1.0;
    return normalize(remapped); 
}

fn getBounceRay(normal: vec3f, seed: vec2f) -> vec3f {
    let random = getRandomInUnitSphere(seed);

    if (dot(random, normal) > 0) {
        return random;
    }
    return -random;
}

fn unitVecFrom(input: vec3f) -> vec3f {
    let length = sqrt(pow(input.x, 2) + pow(input.y, 2) + pow(input.z, 2));
    return input / length;
}

// todo: add seed as input later
fn rand(seed: vec2f) -> f32 {
    return fract(sin(dot(seed, vec2f(12.9898, 78.233))) * 43758.5453);
}