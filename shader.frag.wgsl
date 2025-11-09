struct SDFOutput {
    dist: f32,
    color: vec4f,
}

fn sphereSDF(p: vec3f, s: f32, c: vec4f) -> SDFOutput {
    // return length(p) - s;
    return SDFOutput(length(p)-s, c);
}

fn boxSDF(p: vec3f, b: vec3f, c: vec4f) -> SDFOutput {
    let q = abs(p) - b;
    let dist = length(max(q,vec3f(0.0,0.0,0.0))) +
        min(max(q.x,
                max(q.y,q.z)),
            0);
    return SDFOutput(dist, c);
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

fn planeSDF(p: vec3f, n: vec3f, h: f32, c: vec4f) -> SDFOutput {
  let dist = dot(p,n) + h;
  return SDFOutput(dist, c);
}

fn translate(p: vec3f, t: vec3f) -> vec3f {
    return p - t;
}

const PI: f32 = radians(180.0);

fn rotateY(p: vec3f, a: f32) -> vec3f {
    let theta = (PI / 100) * a;
    let sinTheta = sin(theta);
    let cosTheta = cos(theta);
    return vec3f((cosTheta*p.x) + (sinTheta*p.z), p.y, (-sinTheta*p.x) + (cosTheta*p.z));
}

fn getMin(objs: array<SDFOutput, 6>) -> SDFOutput {
    var minDist = 1000.0;
    var minIndex = 0;
    for (var i = 0; i < 6; i += 1) {
        // minDist = min(minDist, objs[i].dist);
        if (minDist > objs[i].dist) {
            minIndex = i;
            minDist = objs[i].dist;
        }
    }
    return objs[minIndex];
}

fn sceneSDF(p: vec3f) -> SDFOutput {
    let sphere1 = sphereSDF(translate(p, vec3f(0.4, 0.3, 0.0)), 0.3, vec4f(0.0,0.3,0.8,1.0));
    let yPlane = planeSDF(p, vec3f(0,1,0), 1.0, vec4f(0.5,0.5,0.5,1.0));
    // let yPlane = yPlaneSDF(p, -2.0);translate box sdftranslate box sdf
    let box1 = boxSDF(rotateY(translate(p, vec3f(-0.25,-0.30,0)), 10), vec3f(0.2,0.45,0.2), vec4f(0.5,0.5,0.5,1.0));
    let box2 = boxSDF(rotateY(translate(p, vec3f(0.25,-0.55,-.5)), -10), vec3f(0.2,0.2,0.2), vec4f(0.5,0.5,0.5,1.0));

    let wall1 = boxSDF(translate(p, vec3f(-0.75,0,0)), vec3f(0.001,2,2), vec4f(1.0,0.0,0.0,1.0));
    let wall2 = boxSDF(translate(p, vec3f(0.75,0,0)), vec3f(0.001,2,2), vec4f(0.0,1.0,0.0,1.0));
    let wall3 = boxSDF(translate(p, vec3f(0,0.75,0)), vec3f(2,0.001,2), vec4f(0.5,0.5,0.5,1.0));
    let wall4 = boxSDF(translate(p, vec3f(0,-0.75,0)), vec3f(2,0.001,2), vec4f(0.5,0.5,0.5,1.0));
    let wall5 = boxSDF(translate(p, vec3f(0,-0.75,0)), vec3f(2,2,0.001), vec4f(0.5,0.5,0.5,1.0));

    let torus = torusSDF(p, vec2f(0.3,0.2));

    let world: array<SDFOutput, 6> = array(wall1, wall2, wall3, wall4, box1, box2);

    return getMin(world);
    // return sphere1;
}

// march one ray
fn march(origin: vec3f, dir: vec3f) -> SDFOutput {
    var MAX_STEPS = 1000;
    var MAX_DIST = 1000.0;
    var MIN_DIST = 0.005;
    var totalDist = 0.0;
    for (var i = 0; i < MAX_STEPS; i++) {
        // get current position
        var currPos = origin + (dir * totalDist);

        // get nearest distance from point to scene
        let res = sceneSDF(currPos);
        let distToScene = res.dist;
        let color = res.color;

        // check for a hit
        if (distToScene < MIN_DIST) {
            return SDFOutput(totalDist, color);
        }

        // check for a miss
        if (totalDist > MAX_DIST) {
            return SDFOutput(-1.0, vec4f(0.0,0.0,0.0,0.0));
        }

        // march forward
        totalDist += distToScene;
    }
    return SDFOutput(-1.0, vec4f(0.0,0.0,0.0,0.0));
}

// https://iquilezles.org/articles/normalsSDF/
// tetrahedron technique
fn getNormal(p: vec3f) -> vec3f {
    let h = 0.0001;
    let k = vec2f(1.0,-1.0);

    return normalize(k.xyy * sceneSDF(p + k.xyy*h).dist +
                     k.yyx * sceneSDF(p + k.yyx*h).dist +
                     k.yxy * sceneSDF(p + k.yxy*h).dist +
                     k.xxx * sceneSDF(p + k.xxx*h).dist);

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
    let res = march(originRay, dirRay);
    let marchDist = res.dist;
    let marchColor = res.color;

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
        
        return vec4f(finalColor, 1.0) * marchColor;
    }

    // return vec4f(0,.4,.4,1);
}