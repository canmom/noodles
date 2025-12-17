mod attributes;

use bytemuck::bytes_of;
use glam::{Mat4, Vec3, vec3};
use std::f32::consts::{PI, TAU};
use wgpu::util::DeviceExt;

use self::attributes::{TubeInstance, Vertex};

#[repr(C)]
#[derive(Debug, Copy, Clone, bytemuck::Zeroable, bytemuck::Pod)]
struct Uniforms {
    camera: Mat4,
    light_direction: Vec3,
    _padding_1: u32,
    ambient: Vec3,
    _padding_2: u32,
}

pub struct Pipelines {
    render_pipeline: wgpu::RenderPipeline,
    bind_group: wgpu::BindGroup,
    uniform_buffer: wgpu::Buffer,
    cylinder_vertex_buffer: wgpu::Buffer,
    instance_buffer: wgpu::Buffer,
}

impl Pipelines {
    const SIDES: usize = 8;
    const VERTICES: usize = 2 * Self::SIDES + 2;
    const SEGMENTS: usize = 4096;

    pub fn new(device: &wgpu::Device, surface_format: wgpu::TextureFormat) -> Self {
        let shaders = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Noodles vertex shader"),
            source: wgpu::ShaderSource::Wgsl(include_str!("shaders/tube.wgsl").into()),
        });

        let uniform_buffer = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("Noodle uniform buffer"),
            size: (std::mem::size_of::<Uniforms>() as u64).div_ceil(16) * 16,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });

        let render_pipeline = device.create_render_pipeline(&wgpu::RenderPipelineDescriptor {
            label: Some("Noodles render pipeline"),
            layout: None,
            vertex: wgpu::VertexState {
                module: &shaders,
                entry_point: Some("vs_main"),
                compilation_options: Default::default(),
                buffers: &[Vertex::LAYOUT, TubeInstance::LAYOUT],
            },
            primitive: wgpu::PrimitiveState {
                topology: wgpu::PrimitiveTopology::TriangleStrip,
                strip_index_format: None,
                front_face: wgpu::FrontFace::Ccw,
                cull_mode: Some(wgpu::Face::Back),
                polygon_mode: wgpu::PolygonMode::Fill,
                unclipped_depth: false,
                conservative: false,
            },
            depth_stencil: Some(wgpu::DepthStencilState {
                format: wgpu::TextureFormat::Depth32Float,
                depth_write_enabled: true,
                depth_compare: wgpu::CompareFunction::Greater,
                stencil: Default::default(),
                bias: Default::default(),
            }),
            multisample: Default::default(),
            fragment: Some(wgpu::FragmentState {
                module: &shaders,
                entry_point: Some("fs_main"),
                compilation_options: Default::default(),
                targets: &[Some(wgpu::ColorTargetState {
                    format: surface_format,
                    blend: Some(wgpu::BlendState::REPLACE),
                    write_mask: wgpu::ColorWrites::ALL,
                })],
            }),
            multiview: None,
            cache: None,
        });

        let bind_group_layout = render_pipeline.get_bind_group_layout(0);

        let bind_group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: Some("Noodle bind group"),
            layout: &bind_group_layout,
            entries: &[wgpu::BindGroupEntry {
                binding: 0,
                resource: uniform_buffer.as_entire_binding(),
            }],
        });

        let cylinder_vertex_buffer = Self::create_cylinder(device);

        let instance_buffer = Self::create_sinusoid_instances(device);

        Self {
            render_pipeline,
            bind_group,
            uniform_buffer,
            cylinder_vertex_buffer,
            instance_buffer,
        }
    }

    pub fn update_uniforms(
        &self,
        queue: &wgpu::Queue,
        camera_pos: Vec3,
        camera_target: Vec3,
        aspect_ratio: f32,
    ) {
        let projection = Mat4::perspective_infinite_reverse_rh(PI / 6.0, aspect_ratio, 0.5);
        let view = Mat4::look_at_rh(camera_pos, camera_target, vec3(0.0, 0.0, 1.0));
        let new_uniforms = Uniforms {
            camera: projection * view,
            light_direction: vec3(-0.5, -0.2, 1.0).normalize(),
            _padding_1: 0,
            ambient: vec3(0.05, 0.05, 0.07),
            _padding_2: 0,
        };
        queue.write_buffer(&self.uniform_buffer, 0, bytes_of(&new_uniforms));
    }

    fn create_cylinder(device: &wgpu::Device) -> wgpu::Buffer {
        let vertices: [Vertex; Self::VERTICES] = std::array::from_fn(|i| {
            let side = i / 2;
            let end = i % 2;
            let angle = TAU * (side as f32) / (Self::SIDES as f32);
            Vertex {
                position: Vec3 {
                    x: angle.cos(),
                    y: angle.sin(),
                    z: end as f32,
                },
            }
        });
        device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Noodle vertex buffer"),
            contents: bytemuck::cast_slice(&vertices),
            usage: wgpu::BufferUsages::VERTEX,
        })
    }

    fn create_sinusoid_instances(device: &wgpu::Device) -> wgpu::Buffer {
        const SEGMENTS_PER_STRAND: usize = 1024;
        let spacing = TAU / (SEGMENTS_PER_STRAND as f32);
        let instances: [TubeInstance; Self::SEGMENTS] = std::array::from_fn(|i| {
            let strand = i / SEGMENTS_PER_STRAND;
            let i = i % SEGMENTS_PER_STRAND;
            let t = spacing * (i as f32);
            let t_next = spacing * ((i + 1) as f32);

            TubeInstance {
                start_position: vec3(strand as f32, t, t.sin()),
                end_position: vec3(strand as f32, t_next, t_next.sin()),
                start_bitangent: vec3(-1.0, 0.0, 0.0),
                end_bitangent: vec3(-1.0, 0.0, 0.0),
                start_normal: vec3(0.0, -t.cos(), 1.0).normalize(),
                end_normal: vec3(0.0, -t_next.cos(), 1.0).normalize(),
                colour: vec3(1.0, 1.0, 1.0),
                radius: 0.05,
            }
        });
        device.create_buffer_init(&wgpu::util::BufferInitDescriptor {
            label: Some("Noodle instance buffer"),
            contents: bytemuck::cast_slice(&instances),
            usage: wgpu::BufferUsages::VERTEX,
        })
    }

    pub fn render(&self, render_pass: &mut wgpu::RenderPass) {
        render_pass.set_pipeline(&self.render_pipeline);
        render_pass.set_bind_group(0, &self.bind_group, &[]);
        render_pass.set_vertex_buffer(0, self.cylinder_vertex_buffer.slice(..));
        render_pass.set_vertex_buffer(1, self.instance_buffer.slice(..));
        render_pass.draw(0..(Self::VERTICES as u32), 0..(Self::SEGMENTS as u32))
    }
}
