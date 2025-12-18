import package::types::{Instance, Uniforms};
import package::noise::{Frame, bitangent_noise, curl_noise};

@group(0) @binding(0) var<uniform> uniforms: Uniforms;
@group(0) @binding(1) var<storage, read_write> instances: array<Instance>;

const TAU = radians(360.0);
const SEGMENTS_PER_STRAND = 64;
const STEP_SIZE = 0.05;
const NOISE_SCALE = 0.5;
const GRID_SPACING = 0.1;
const TUBE_RADIUS = 0.01;

fn hsv2rgb( c : vec3<f32>) -> vec3<f32> {
  let K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
  let p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
  return c.z * mix(K.xxx, saturate(p - K.xxx), c.y);
}

@compute
@workgroup_size(16,16,1)
fn create_instances(
    @builtin(global_invocation_id) gid: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
    let grid_size = num_workgroups * vec3(16,16,1);
    let global_invocation_index =
        grid_size.y * grid_size.x * gid.z
        + grid_size.x * gid.y
        + gid.x;
    let total_invocations = grid_size.x * grid_size.y * grid_size.z;
    let x_init = f32(gid.x) * GRID_SPACING;
    let y_init = f32(gid.y) * GRID_SPACING;
    var end_position = vec3(x_init, 0.0, y_init);
    let offset_1 = vec3(100.0,uniforms.time,  100.0);
    let offset_2 = vec3( -100.0,uniforms.time, -150.0);
    var frame = curl_noise(end_position, offset_1, offset_2, NOISE_SCALE);
    var end_normal = frame.normal;
    var end_binormal = frame.binormal;
    //let colour = hsv2rgb(vec3(f32(global_invocation_index)/f32(total_invocations),0.4,1.0));
    let colour = vec3(f32(global_invocation_index)/f32(total_invocations));

    for (var i : u32 = 0; i < SEGMENTS_PER_STRAND; i++) {
        let start_position = end_position;
        let start_normal = end_normal;
        let start_binormal = end_binormal;
        frame = curl_noise(end_position, offset_1, offset_2, NOISE_SCALE);
        end_position += frame.tangent * STEP_SIZE;
        end_normal = frame.normal;
        end_binormal = frame.binormal;

        instances[global_invocation_index * SEGMENTS_PER_STRAND + i] =
            Instance(
                start_position,
                start_normal,
                start_binormal,
                end_position,
                end_normal,
                end_binormal,
                colour,
                TUBE_RADIUS,
            );
    }
}
