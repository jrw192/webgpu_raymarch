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

    return getMin(world);
    // return sphere1;
}

// march one ray
fn march(origin: vec3f, dir: vec3f) -> SDFOutput {
    var MAX_STEPS = 1000;
    var MAX_DIST = 1000.0;
    var MIN_DIST = 0.001;
    var totalDist = 0.0;
    for (var i = 0; i < MAX_STEPS; i++) {
        // get current position
        var currPos = origin + (dir * totalDist);

        // get nearest distance from point to scene
        let res = sceneSDF(currPos);
        let distToScene = res.dist;
        let material = res.material;
        let matType = material.matType;
        let color = material.color;

        // check for a hit
        if (distToScene < MIN_DIST) {
            return SDFOutput(totalDist, material);
        }

        // check for a miss
        if (totalDist > MAX_DIST) {
            return SDFOutput(- 1.0, Material(vec4f(0.0, 0.0, 0.0, 0.0), MATERIAL_LAMBERTIAN));
        }

        // march forward
        totalDist += distToScene;
    }
    return SDFOutput(- 1.0, Material(vec4f(0.0, 0.0, 0.0, 0.0), MATERIAL_LAMBERTIAN));
}

// https://iquilezles.org/articles/normalsSDF/
// tetrahedron technique
fn getNormal(p: vec3f) -> vec3f {
    let h = 0.0001;
    let k = vec2f(1.0, - 1.0);

    return normalize(k.xyy * sceneSDF(p + k.xyy * h).dist + k.yyx * sceneSDF(p + k.yyx * h).dist + k.yxy * sceneSDF(p + k.yxy * h).dist + k.xxx * sceneSDF(p + k.xxx * h).dist);

}

fn calcLight(originRay: vec3f, dirRay: vec3f, uv: vec2f) -> vec4f {
    var color = vec4f(0, 0, 0, 0);
    var throughput = vec4f(1, 1, 1, 1);

    var origin = originRay;
    var dir = dirRay;
    var seed = uv;
    for (var i = 0; i < 6; i++) {
        // march ray
        let res = march(origin, dir);
        let dist = res.dist;
        let material = res.material;

        // handle miss
        if (dist < 0) {
            // add sky
            // color += vec4f(.1, .4, .8, 1) * throughput;
            break;
        }

        // if hit:
        let hitPoint = origin + (dir * dist);
        let normal = getNormal(hitPoint);

        // if hits light source
        if (material.matType == MATERIAL_DIFFUSE_LIGHT) {
            let light = material.color.rgb * material.color.a;
            color += vec4f(light, 1) * throughput;
            break;
        }

        // if hits diffuse surface
        if (material.matType == MATERIAL_LAMBERTIAN) {
            // color += material.color * throughput;
            throughput *= material.color;

            // get new ray
            let bounceRay = getBounceRay(normal, seed);
            dir = bounceRay;
            origin = hitPoint + (normal * 0.001);
            seed = seed + vec2f(1.0, 1.0);
        }
    }

    return color;
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

@group(0) @binding(0)
var<uniform> state: vec2u;
@fragment
fn fragmentMain(@builtin(position) fragCoord: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    // set up camera
    var camX = 0.0;
    var camY = 0.0;
    var camZ = -5.0;

    // calculate rays
    let originRay = vec3f(camX, camY, camZ);
    let lookAt = vec3f(uv.x, uv.y, 0.0);
    let dirRay = normalize(lookAt - originRay);

    var seed = uv;
    var color = vec4f(0,0,0,0);
    let SAMPLE_COUNT = 100;
    for (var i = 0; i < SAMPLE_COUNT; i++) {
        seed = uv + vec2f(f32(i), f32(i));

        color += calcLight(originRay, dirRay, seed); 
    }
    color /= vec4f(f32(SAMPLE_COUNT),f32(SAMPLE_COUNT),f32(SAMPLE_COUNT),1.0);

    // march the ray
    let gamma = 2.2;
    let finalColor = pow(color.rgb, vec3f(1/gamma));
    
    return vec4f(finalColor, 1);
}