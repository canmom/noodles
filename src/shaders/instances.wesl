import package::types::Instance;

@group(0) @binding(0) var<storage, read_write> instances: array<Instance>;

const TAU = radians(360.0);
const SEGMENTS_PER_STRAND = 64;

@compute
@workgroup_size(16,16,1)
fn create_instances(
    @builtin(global_invocation_id) gid: vec3<u32>,
    @builtin(num_workgroups) num_workgroups: vec3<u32>,
) {
    let workgroup_grid_size = num_workgroups * vec3(16,16,1);
    let global_invocation_index =
        workgroup_grid_size.y * workgroup_grid_size.x * gid.z
        + workgroup_grid_size.x * gid.y
        + gid.x;
    let radius = f32(gid.x) * 0.1;
    let height = f32(gid.y) * 0.1;
    var end_position = vec3(radius, 0.0, height);
    var end_normal = vec3(1.0, 0.0, 0.0);
    let bitangent = vec3(0.0,0.0,1.0);
    let tube_radius = 0.02;
    for (var i : u32 = 0; i < SEGMENTS_PER_STRAND; i++) {
        let start_position = end_position;
        let start_normal = end_normal;
        let t = f32(i+1)/f32(SEGMENTS_PER_STRAND);
        let cos_sin = vec2(cos(t*TAU), sin(t*TAU));
        end_position = vec3(radius * cos_sin, height);
        end_normal = vec3(cos_sin, 0.0);

        let colour = vec3(t,0.0,1.0-t);

        instances[global_invocation_index * SEGMENTS_PER_STRAND + i] =
            Instance(
                start_position,
                start_normal,
                bitangent,
                end_position,
                end_normal,
                bitangent,
                colour,
                tube_radius,
            );
    }
}
