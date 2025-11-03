struct VertexOutput {
  @builtin(position) fragCoord: vec4f,
  @location(0) uv: vec2f,
};

@vertex
fn vertexMain(@builtin(vertex_index) in_vertex_index: u32) -> VertexOutput {
  var out: VertexOutput;

  // This "big triangle" trick covers the entire screen (clip space).
  // We generate 3 vertices to form one triangle.
  let x = f32(in_vertex_index / 2u) * 4.0 - 1.0;
  let y = f32(in_vertex_index % 2u) * 4.0 - 1.0;
  
  out.fragCoord = vec4f(x, y, 0.0, 1.0);
  out.uv = vec2f(x,y);
  
  return out;
}