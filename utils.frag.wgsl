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

fn getMin(objs: array<SDFOutput, 8>) -> SDFOutput {
    var minDist = 1000.0;
    var minIndex = 0;
    for (var i = 0; i < 8; i += 1) {
        // minDist = min(minDist, objs[i].dist);
        if (minDist > objs[i].dist) {
            minIndex = i;
            minDist = objs[i].dist;
        }
    }
    return objs[minIndex];
}

// https://iquilezles.org/articles/normalsSDF/
// tetrahedron technique
fn getNormal(p: vec3f) -> vec3f {
    let h = 0.0001;
    let k = vec2f(1.0, - 1.0);

    return normalize(k.xyy * sceneSDF(p + k.xyy * h).dist + k.yyx * sceneSDF(p + k.yyx * h).dist + k.yxy * sceneSDF(p + k.yxy * h).dist + k.xxx * sceneSDF(p + k.xxx * h).dist);
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
