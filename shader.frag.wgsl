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

@group(0) @binding(0)
var<uniform> state: vec2u;
@group(0) @binding(1)
var<uniform> params: vec2u;
@group(0) @binding(2)
var<storage, read> worldBlocks: array<Block>;
@fragment
fn fragmentMain(@builtin(position) fragCoord: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    // set up camera
    var camX = 10.0;
    var camY = 8.0;
    var camZ = -90.0;

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