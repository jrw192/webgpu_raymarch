fn sphereSDF(c: vec3f, p: vec3f, s: f32) -> f32 {
    return length(p-c) - s;
}

fn boxSDF( p: vec3f, b: vec3f) -> f32 {
  let q = abs(p) - b;
  return length(max(q,vec3f(0.0,0.0,0.0))) +
        min(max(q.x,
                max(q.y,q.z)),
            0);
}

fn torusSDF(p: vec3f, t: vec2f) -> f32 {
  let q = vec2f(length(p.xz)-t.x,p.y);
  return length(q)-t.y;
}

fn xPlaneSDF(p: vec3f, x: f32) -> f32 {
    return p.x - x;
}

fn yPlaneSDF(p: vec3f, y: f32) -> f32 {
    return p.y - y;
}

fn zPlaneSDF(p: vec3f, z: f32) -> f32 {
    return p.z - z;
}

fn sceneSDF(p: vec3f) -> f32 {
    let sphere1 = sphereSDF(vec3f(-0.3,-0.5,0), p, 0.5);
    let sphere2 = sphereSDF(vec3f(0.5,0.5,0), p, 0.2);
    let sphere3 = sphereSDF(vec3f(0.0,0.0,10), p, 2.5);
    let plane =  xPlaneSDF(p, -0.5);
    let box = boxSDF(p, vec3f(0.4,0.2,0.2));
    let torus = torusSDF(p, vec2f(0.3,0.2));

    var world = min(min(sphere1, sphere2), sphere3);

    return world;
}

// march one ray
fn march(origin: vec3f, dir: vec3f) -> f32 {
    var MAX_STEPS = 100;
    var MAX_DIST = 100.0;
    var MIN_DIST = 0.01;
    var totalDist = 0.0;
    for (var i = 0; i < MAX_STEPS; i++) {
        // get current position
        var currPos = origin + (dir * totalDist);

        // get nearest distance from point to scene
        var distToScene = sceneSDF(currPos);

        // check for a hit
        if (distToScene < MIN_DIST) {
            return totalDist;
        }

        // check for a miss
        if (totalDist > MAX_DIST) {
            return -1.0;
        }

        // march forward
        totalDist += distToScene;
    }
    return -1.0;
}

// https://iquilezles.org/articles/normalsSDF/
// tetrahedron technique
fn getNormal(p: vec3f) -> vec3f {
    let h = 0.0001;
    let k = vec2f(1.0,-1.0);

    return normalize(k.xyy * sceneSDF(p + k.xyy*h) +
                     k.yyx * sceneSDF(p + k.yyx*h) +
                     k.yxy * sceneSDF(p + k.yxy*h) +
                     k.xxx * sceneSDF(p + k.xxx*h));

}

@group(0) @binding(0) var<uniform> state: vec2u;
@fragment
fn fragmentMain(@builtin(position) fragCoord: vec4f, @location(0) uv: vec2f) -> @location(0) vec4f {
    // set up camera
    var camX = 0.0;
    var camY = 0.0;
    var camZ = -5.0;

    if (state[0] % 4 == 0) {
        camX = -0.5;
    }
    if (state[0] % 4 == 1) {
        camX = 0.0;
    }
    if (state[0] % 4 == 2) {
        camX = 0.5;
    }
    if (state[0] % 4 == 3) {
        camX = 0.0;
    }

    // calculate rays
    let originRay = vec3f(camX, camY, camZ);
    let lookAt = vec3f(uv.x,uv.y,0.0);
    let dirRay = normalize(lookAt - originRay);

    // march the ray
    let marchDist = march(originRay, dirRay);

    // determine color
    if (marchDist < 0) {
        // nothing hit, return background
        return vec4f(0.3,0.0,0.6,1.0);
    } else {
        // calculate shading
        let normal = getNormal(originRay + dirRay * marchDist);
        let lightDir = normalize(vec3f(1.0,1.0,-1.0));
        let diffuse = max(dot(normal, lightDir), 0.0);
        let lightColor = vec3f(1.0,1.0,1.0);
        let finalColor = lightColor * diffuse;
        
        return vec4f(finalColor, 1.0);
    }

    // return vec4f(0,.4,.4,1);
}