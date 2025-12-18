struct VertexInput {
    @location(0) position: vec3<f32>,
}

struct Instance {
    @location(1) start_position: vec3<f32>,
    @location(2) start_normal: vec3<f32>,
    @location(3) start_bitangent: vec3<f32>,
    @location(4) end_position: vec3<f32>,
    @location(5) end_normal: vec3<f32>,
    @location(6) end_bitangent: vec3<f32>,
    @location(7) colour: vec3<f32>,
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
    time: f32,
    ambient: vec3<f32>,
}
