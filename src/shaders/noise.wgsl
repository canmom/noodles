// http://www.jcgt.org/published/0009/03/02/
fn hash( u : vec3<u32>) -> vec3<f32> {
    var v = u;
    v = v * 1664525u + 1013904223u;

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    v ^= v >> vec3(16);

    v.x += v.y*v.z;
    v.y += v.z*v.x;
    v.z += v.x*v.y;

    return vec3<f32>(v) * (1.0/f32(0xffffffffu));
}

//adapted from Inigo Quilez
//https://iquilezles.org/articles/gradientnoise/
fn noised( x : vec3<f32> ) -> vec4<f32>
{
  // grid
  let i = vec3<u32>(floor(x));

  let f = fract(x);

  // quintic interpolant
  let u = f*f*f*(f*(f*6.0-15.0)+10.0);
  let du = 30.0*f*f*(f*(f-2.0)+1.0);

  // gradients
  let ga = hash( i+vec3(0,0,0) );
  let gb = hash( i+vec3(1,0,0) );
  let gc = hash( i+vec3(0,1,0) );
  let gd = hash( i+vec3(1,1,0) );
  let ge = hash( i+vec3(0,0,1) );
  let gf = hash( i+vec3(1,0,1) );
  let gg = hash( i+vec3(0,1,1) );
  let gh = hash( i+vec3(1,1,1) );

  // projections
  let va = dot( ga, f-vec3(0.0,0.0,0.0) );
  let vb = dot( gb, f-vec3(1.0,0.0,0.0) );
  let vc = dot( gc, f-vec3(0.0,1.0,0.0) );
  let vd = dot( gd, f-vec3(1.0,1.0,0.0) );
  let ve = dot( ge, f-vec3(0.0,0.0,1.0) );
  let vf = dot( gf, f-vec3(1.0,0.0,1.0) );
  let vg = dot( gg, f-vec3(0.0,1.0,1.0) );
  let vh = dot( gh, f-vec3(1.0,1.0,1.0) );

  // interpolations
  let k0 = va-vb-vc+vd;
  let g0 = ga-gb-gc+gd;
  let k1 = va-vc-ve+vg;
  let g1 = ga-gc-ge+gg;
  let k2 = va-vb-ve+vf;
  let g2 = ga-gb-ge+gf;
  let k3 = -va+vb+vc-vd+ve-vf-vg+vh;
  let g3 = -ga+gb+gc-gd+ge-gf-gg+gh;
  let k4 = vb-va;
  let g4 = gb-ga;
  let k5 = vc-va;
  let g5 = gc-ga;
  let k6 = ve-va;
  let g6 = ge-ga;

  return vec4( va + k4*u.x + k5*u.y + k6*u.z + k0*u.x*u.y + k1*u.y*u.z + k2*u.z*u.x + k3*u.x*u.y*u.z,    // value
               ga + g4*u.x + g5*u.y + g6*u.z + g0*u.x*u.y + g1*u.y*u.z + g2*u.z*u.x + g3*u.x*u.y*u.z +   // derivatives
               du * (vec3(k4,k5,k6) +
                     vec3(k0,k1,k2)*u.yzx +
                     vec3(k2,k0,k1)*u.zxy +
                     k3*u.yzx*u.zxy ));
}

struct Frame {
    normal: vec3<f32>,
    binormal: vec3<f32>,
    tangent: vec3<f32>,
}

fn bitangent_noise(position: vec3<f32>, offset: vec3<f32>, scale: f32) -> Frame {
    let noise_up = noised(position * scale).yzw;
    let noise_down = noised(position * scale + offset).yzw;
    let tangent = normalize(cross(noise_up, noise_down));
    let normal = normalize(noise_up);
    let binormal = normalize(cross(normal,tangent));
    return Frame(normal,binormal,tangent);
}

fn curl_noise(position: vec3<f32>, offset_y: vec3<f32>, offset_z: vec3<f32>, scale: f32) -> Frame {
    let gx = noised(position * scale).yzw;
    let gy = noised(position * scale + offset_y).yzw;
    let gz = noised(position * scale + offset_z).yzw;
    let tangent = vec3(gz.y - gy.z, gx.z - gz.x, gy.x - gx.y);
    let tangent_norm = normalize(tangent);
    let normal = normalize(cross(tangent_norm, vec3(0.0,1.0,0.0)));
    let binormal = cross(normal,tangent_norm);
    return Frame(normal,binormal,tangent_norm);
}
