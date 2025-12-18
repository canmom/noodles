import package::types::{Instance, VertexInput, VertexOutput, Uniforms};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

@vertex
fn vs_main(vert: VertexInput, instance: Instance) -> VertexOutput {
    let spline_position = mix(instance.start_position, instance.end_position, vert.position.z);
    let spline_normal = mix(instance.start_normal, instance.end_normal, vert.position.z);
    let spline_bitangent = mix(instance.start_bitangent, instance.end_bitangent, vert.position.z);

    let world_normal = vert.position.x * spline_normal + vert.position.y * spline_bitangent;
    let world_position = spline_position + world_normal * instance.radius;

    let clip_position = uniforms.camera * vec4(world_position, 1.0);

    return VertexOutput(clip_position, world_normal, instance.colour);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return vec4(in.colour * (saturate(dot(uniforms.light_direction, in.normal)) + uniforms.ambient), 1.0);
}
