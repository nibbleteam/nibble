#ifndef NIBBLE_VIDEO_ENCODER_H
#define NIBBLE_VIDEO_ENCODER_H

#include <kernel/filesystem.hpp>
#include <x264.h>
#include <mp4v2.h>

#define yuv_clamp(x, high) max(min(int(x), high), 16)

class VideoEncoder {
  x264_param_t configuration;

  x264_picture_t input_pic;
  x264_picture_t output_pic;

  x264_t *encoder;

  // TODO: Figure out what are those
  x264_nal_t *nal;
  int i_nal;

  int frame;

  MP4FileHandle output;
  MP4TrackId video;
public:
  VideoEncoder(const Path&);
  ~VideoEncoder();

  bool capture_frame(const uint8_t*);
private:
  static uint8_t subsample_chroma(const uint8_t*, const int, const int);
};

#endif /* NIBBLE_VIDEO_ENCODER_H */
