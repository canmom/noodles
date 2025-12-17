struct VertexInput {
    @location(0) position: vec3<f32>,
    @location(1) colour: vec3<f32>,
}

struct Instance {
    @location(2) start_position: vec3<f32>,
    @location(3) start_normal: vec3<f32>,
    @location(4) start_bitangent: vec3<f32>,
    @location(5) end_position: vec3<f32>,
    @location(6) end_normal: vec3<f32>,
    @location(7) end_bitangent: vec3<f32>,
    @location(8) radius: f32,
}

struct VertexOutput {
    @builtin(position) clip_position : vec4<f32>,
    @location(0) normal: vec3<f32>,
    @location(1) colour: vec3<f32>,
}

struct Uniforms {
    camera: mat4x4<f32>,
    light_direction: vec3<f32>,
    ambient: vec3<f32>,
}

@group(0) @binding(0) var<uniform> uniforms: Uniforms;

@vertex
fn vs_main(vert: VertexInput, instance: Instance) -> VertexOutput {
    let spline_position = mix(instance.start_position, instance.end_position, vert.position.z);
    let spline_normal = mix(instance.start_normal, instance.end_normal, vert.position.z);
    let spline_bitangent = mix(instance.start_bitangent, instance.end_bitangent, vert.position.z);

    let world_normal = vert.position.x * spline_normal + vert.position.y * spline_bitangent;
    let world_position = spline_position + world_normal * instance.radius;

    let clip_position = uniforms.camera * vec4(world_position, 1.0);

    return VertexOutput(clip_position, world_normal, vert.colour);
}

@fragment
fn fs_main(in: VertexOutput) -> @location(0) vec4<f32> {
    return vec4(in.colour * saturate(dot(uniforms.light_direction, in.normal))
        + in.colour * uniforms.ambient, 1.0);
}
