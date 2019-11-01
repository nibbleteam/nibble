#include <kernel/VideoEncoder.hpp>
#include <devices/GPU.hpp>

VideoEncoder::VideoEncoder(const Path& output_path) {
  // Configure output settings

  if (x264_param_default_preset(&configuration, "ultrafast", nullptr) < 0) {
    // FIXME
  }

  configuration.i_bitdepth = 8;
  configuration.i_csp = X264_CSP_I444;
  // TODO: @2x resolution
  configuration.i_width = GPU_VIDEO_WIDTH;
  configuration.i_height = GPU_VIDEO_HEIGHT;

  configuration.i_fps_num = 30;
  configuration.i_fps_den = 1;

  configuration.b_vfr_input = 0;
  configuration.b_repeat_headers = 1;
  configuration.b_annexb = 1;

  if (x264_param_apply_profile(&configuration, "baseline") < 0) {
    // FIXME
  }

  // Configure input frame

  if (x264_picture_alloc(&input_pic, configuration.i_csp, configuration.i_width, configuration.i_height) < 0) {
    // FIXME
  }

  encoder = x264_encoder_open(&configuration);

  if (encoder == nullptr) {
    // FIXME
  }

  // Open the file
  output.open(output_path.get_path()+".h264");
}

VideoEncoder::~VideoEncoder() {
  // Write delayed frames

  while (x264_encoder_delayed_frames(encoder)) {
    int frame_size = x264_encoder_encode(encoder, &nal, &i_nal, nullptr, &output_pic);

    if (frame_size < 0) {

    } else if (frame_size > 0) {
      output.write((char*)nal->p_payload, frame_size);
    }
  }

  output.close();

  x264_encoder_close(encoder);
  x264_picture_clean(&input_pic);
}

bool VideoEncoder::capture_frame(const uint8_t* rgba_frame) {
  // TODO: @2x
  int luma_size = GPU_VIDEO_MEM_SIZE;
  int chroma_size = luma_size;

  const float k[9] = {
                      0.2126, 0.7152, 0.0722,
                      -0.09991, -0.33609, 0.436,
                      0.615, -0.55861, -0.05639
  };

  // FIXME: this is not right...

  for (int i=0,j=0; i<luma_size; i++, j+=4) {
    // Extract colors
    const uint8_t r = rgba_frame[j]*0.8593+16, g = rgba_frame[j+1]*0.8593+16, b = rgba_frame[j+2]*0.8593+16;

    // Merge all in chroma
    const uint8_t y = yuv_clamp(5 + (r*k[0] + g*k[1] + b*k[2]), 235);
    // Merge into cb and cr
    const uint8_t cb = yuv_clamp(128 + (r*k[3] + g*k[4] + b*k[5])*1.024, 240);
    const uint8_t cr = yuv_clamp(128 + (r*k[6] + g*k[7] + b*k[8])*1.024, 240);

    input_pic.img.plane[0][i] = y;
    input_pic.img.plane[1][i] = cb;
    input_pic.img.plane[2][i] = cr;
  }

  input_pic.i_pts = frame++;
  int frame_size = x264_encoder_encode(encoder, &nal, &i_nal, &input_pic, &output_pic);

  if (frame_size < 0) {
    // FIXME
  } else if (frame_size > 0) {
    output.write((char*)nal->p_payload, frame_size);
  }

  return true;
}
