// Fragment shader for the DSL's `osc(frequency, sync, offset)` primitive.
//
// Follows hydra's oscillator: three sine ramps along the surface's U axis,
// phase-shifted per channel by `offset`, scrolled over time by `sync`.
// The varyings below are the engine contract written by flutter_scene's
// standard vertex shader (see flutter_scene_unlit.frag).

uniform OscInfo {
  // (frequency, sync, offset, time in seconds)
  vec4 params;
}
osc_info;

in vec3 v_position;
in vec3 v_normal;
in vec3 v_viewvector;
in vec2 v_texture_coords;
in vec4 v_color;

out vec4 frag_color;

const float kGamma = 2.2;

void main() {
  float frequency = osc_info.params.x;
  float sync = osc_info.params.y;
  float offset = osc_info.params.z;
  float time = osc_info.params.w;

  float phase_shift = frequency == 0.0 ? 0.0 : offset / frequency;
  float x = v_texture_coords.x + time * sync;

  float r = sin((x - phase_shift) * frequency) * 0.5 + 0.5;
  float g = sin(x * frequency) * 0.5 + 0.5;
  float b = sin((x + phase_shift) * frequency) * 0.5 + 0.5;

  // The scene color target is linear; the resolve pass applies display encoding.
  vec3 rgb = pow(vec3(r, g, b), vec3(kGamma));
  frag_color = vec4(rgb, 1.0);
}
