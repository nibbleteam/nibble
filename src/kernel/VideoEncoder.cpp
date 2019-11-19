#include <kernel/VideoEncoder.hpp>
#include <devices/GPU.hpp>

VideoEncoder::VideoEncoder(const Path& output_path): frame(0) {
  // Configure output settings

  if (x264_param_default_preset(&configuration, "ultrafast", nullptr) < 0) {
    // FIXME
  }

  // No logs
  configuration.i_log_level = X264_LOG_NONE;

  configuration.i_bitdepth = 8;
  configuration.i_csp = X264_CSP_I420;
  configuration.i_width = GPU_VIDEO_WIDTH*2;
  configuration.i_height = GPU_VIDEO_HEIGHT*2;

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
  output = MP4Create(output_path.get_path().c_str(), 0);

  MP4SetTimeScale(output, 90000);

  video = MP4AddH264VideoTrack(
    output,
    90000,
    90000/30,
    GPU_VIDEO_WIDTH*2, GPU_VIDEO_HEIGHT*2,
    0x64,
    0x00,
    0x1f,
    3
  ); // 4 length bytes before each NAL unit

  MP4SetVideoProfileLevel(output, 0x7F);
}

VideoEncoder::~VideoEncoder() {
  // Write delayed frames

  while (x264_encoder_delayed_frames(encoder)) {
    int frame_size = x264_encoder_encode(encoder, &nal, &i_nal, nullptr, &output_pic);

    if (frame_size < 0) {

    } else if (frame_size > 0) {
      MP4WriteSample(output, video, nal->p_payload, frame_size, MP4_INVALID_DURATION, 0, 1);
    }
  }

  MP4Close(output);

  x264_encoder_close(encoder);
  x264_picture_clean(&input_pic);
}

bool VideoEncoder::capture_frame(const uint8_t* rgba_frame) {
  static const int luma_size = GPU_VIDEO_MEM_SIZE*4;
  static const int chroma_size = luma_size/4;

  static const float k[9] = {
    0.2126, 0.7152, 0.0722,
    -0.09991, -0.33609, 0.436,
    0.615, -0.55861, -0.05639
  };

  for (int y=0;y<GPU_VIDEO_HEIGHT;y++) {
    for (int x=0;x<GPU_VIDEO_WIDTH;x++) {
      const int chroma_p = y*GPU_VIDEO_WIDTH+x;
      const int rgba_p = chroma_p*3;
      const int luma_p = (y*GPU_VIDEO_WIDTH*2+x)*2;

      // Extract colors
      const uint8_t
        r = rgba_frame[rgba_p]*0.8593+16,
        g = rgba_frame[rgba_p+1]*0.8593+16,
        b = rgba_frame[rgba_p+2]*0.8593+16;

      // Merge all in chroma
      const uint8_t y = yuv_clamp(5 + (r*k[0] + g*k[1] + b*k[2]), 235);
      // Merge into cb and cr
      const uint8_t cb = yuv_clamp(128 + (r*k[3] + g*k[4] + b*k[5])*1.024, 240);
      const uint8_t cr = yuv_clamp(128 + (r*k[6] + g*k[7] + b*k[8])*1.024, 240);

      input_pic.img.plane[0][luma_p] = y;
      input_pic.img.plane[0][luma_p+1] = y;
      input_pic.img.plane[0][luma_p+GPU_VIDEO_WIDTH*2] = y;
      input_pic.img.plane[0][luma_p+GPU_VIDEO_WIDTH*2+1] = y;

      input_pic.img.plane[1][chroma_p] = cb;
      input_pic.img.plane[2][chroma_p] = cr;
    }
  }

  input_pic.i_pts = frame++;
  int frame_size = x264_encoder_encode(encoder, &nal, &i_nal, &input_pic, &output_pic);

  if (frame_size < 0) {
    // FIXME
  } else if (frame_size > 0) {
    MP4WriteSample(output, video, nal->p_payload, frame_size, MP4_INVALID_DURATION, 0, 1);
  }

  return true;
}

uint8_t VideoEncoder::subsample_chroma(const uint8_t* rgba_frame, const int p, const int color) {
  // Round to even
  const int chroma_p = p&!1;

  return 0;
}
