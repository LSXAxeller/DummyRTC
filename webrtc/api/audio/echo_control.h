/*
 *  Copyright (c) 2018 The WebRTC project authors. All Rights Reserved.
 *
 *  Use of this source code is governed by a BSD-style license
 *  that can be found in the LICENSE file in the root of the source
 *  tree. An additional intellectual property rights grant can be found
 *  in the file PATENTS.  All contributing project authors may
 *  be found in the AUTHORS file in the root of the source tree.
 */

#ifndef API_AUDIO_ECHO_CONTROL_H_
#define API_AUDIO_ECHO_CONTROL_H_

#include <memory>

#include "rtc_base/checks.h"

namespace webrtc {

class AudioBuffer;

extern "C" {

    // Interface for an acoustic echo cancellation (AEC) submodule.
class EchoControl {
 public:
  // Analysis (not changing) of the render signal.
  RTC_EXPORT virtual void AnalyzeRender(AudioBuffer* render) = 0;

  // Analysis (not changing) of the capture signal.
  RTC_EXPORT virtual void AnalyzeCapture(AudioBuffer* capture) = 0;

  // Processes the capture signal in order to remove the echo.
  RTC_EXPORT virtual void ProcessCapture(AudioBuffer* capture, bool level_change) = 0;

  // As above, but also returns the linear filter output.
  RTC_EXPORT virtual void ProcessCapture(AudioBuffer* capture,
                              AudioBuffer* linear_output,
                              bool level_change) = 0;

  struct Metrics {
    double echo_return_loss;
    double echo_return_loss_enhancement;
    int delay_ms;
  };

  // Collect current metrics from the echo controller.
  RTC_EXPORT virtual Metrics GetMetrics() const = 0;

  // Provides an optional external estimate of the audio buffer delay.
  RTC_EXPORT virtual void SetAudioBufferDelay(int delay_ms) = 0;

  // Specifies whether the capture output will be used. The purpose of this is
  // to allow the echo controller to deactivate some of the processing when the
  // resulting output is anyway not used, for instance when the endpoint is
  // muted.
  // TODO(b/177830919): Make pure virtual.
  RTC_EXPORT virtual void SetCaptureOutputUsage(bool capture_output_used) {}

  // Returns wheter the signal is altered.
  RTC_EXPORT virtual bool ActiveProcessing() const = 0;

  virtual ~EchoControl() {}
};
}

// Interface for a factory that creates EchoControllers.
class EchoControlFactory {
 public:
  RTC_EXPORT virtual std::unique_ptr<EchoControl> Create(int sample_rate_hz,
                                              int num_render_channels,
                                              int num_capture_channels) = 0;

  virtual ~EchoControlFactory() = default;
};
}  // namespace webrtc

/*
// C-compatible wrapper interface
#ifdef __cplusplus
extern "C" {
#endif

// Opaque handle type for C interface
typedef void* EchoControlHandle;

// Forward declaration of the factory function needed by the wrapper
webrtc::EchoControlFactory* GetEchoControlFactory();

// Wrapper functions with inline implementations
RTC_EXPORT inline EchoControlHandle webrtc_echo_control_create(
    int sample_rate_hz,
    int num_render_channels,
    int num_capture_channels) {
  return static_cast<EchoControlHandle>(
      GetEchoControlFactory()->Create(sample_rate_hz,
                                    num_render_channels,
                                    num_capture_channels).release());
}

RTC_EXPORT inline void webrtc_echo_control_analyze_render(
    EchoControlHandle handle,
    webrtc::AudioBuffer* render) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  ec->AnalyzeRender(render);
}

RTC_EXPORT inline void webrtc_echo_control_analyze_capture(
    EchoControlHandle handle,
    webrtc::AudioBuffer* capture) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  ec->AnalyzeCapture(capture);
}

RTC_EXPORT inline void webrtc_echo_control_process_capture(
    EchoControlHandle handle,
    webrtc::AudioBuffer* capture,
    bool level_change) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  ec->ProcessCapture(capture, level_change);
}

RTC_EXPORT inline void webrtc_echo_control_process_capture_with_output(
    EchoControlHandle handle,
    webrtc::AudioBuffer* capture,
    webrtc::AudioBuffer* linear_output,
    bool level_change) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  ec->ProcessCapture(capture, linear_output, level_change);
}

RTC_EXPORT inline void webrtc_echo_control_get_metrics(
    EchoControlHandle handle,
    webrtc::EchoControl::Metrics* metrics) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  metrics* = ec->GetMetrics();
}

RTC_EXPORT inline void webrtc_echo_control_set_audio_buffer_delay(
    EchoControlHandle handle,
    int delay_ms) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  ec->SetAudioBufferDelay(delay_ms);
}

RTC_EXPORT inline void webrtc_echo_control_set_capture_output_usage(
    EchoControlHandle handle,
    bool capture_output_used) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  ec->SetCaptureOutputUsage(capture_output_used);
}

RTC_EXPORT inline bool webrtc_echo_control_active_processing(
    EchoControlHandle handle) {
  auto ec = static_cast<webrtc::EchoControl*>(handle);
  return ec->ActiveProcessing();
}

RTC_EXPORT inline void webrtc_echo_control_destroy(
    EchoControlHandle handle) {
  delete static_cast<webrtc::EchoControl*>(handle);
}

#ifdef __cplusplus
}  // extern "C"
#endif
*/

#endif  // API_AUDIO_ECHO_CONTROL_H_