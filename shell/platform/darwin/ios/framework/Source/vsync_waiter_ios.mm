// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

#include "flutter/shell/platform/darwin/ios/framework/Source/vsync_waiter_ios.h"

#include <utility>

#include <Foundation/Foundation.h>
#include <QuartzCore/CADisplayLink.h>
#include <UIKit/UIKit.h>
#include <mach/mach_time.h>

#include "flutter/common/task_runners.h"
#include "flutter/fml/logging.h"
#include "flutter/fml/trace_event.h"

@interface VSyncClient : NSObject

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner
                          callback:(flutter::VsyncWaiter::Callback)callback;

- (void)await;

- (void)invalidate;

//------------------------------------------------------------------------------
/// @brief      The display refresh rate used for reporting purposes. The engine does not care
///             about this for frame scheduling. It is only used by tools for instrumentation. The
///             engine uses the duration field of the link per frame for frame scheduling.
///
/// @attention  Do not use the this call in frame scheduling. It is only meant for reporting.
///
/// @return     The refresh rate in frames per second.
///
- (float)displayRefreshRate;

@end

namespace flutter {

VsyncWaiterIOS::VsyncWaiterIOS(flutter::TaskRunners task_runners)
    : VsyncWaiter(std::move(task_runners)),
      client_([[VSyncClient alloc] initWithTaskRunner:task_runners_.GetUITaskRunner()
                                             callback:std::bind(&VsyncWaiterIOS::FireCallback,
                                                                this,
                                                                std::placeholders::_1,
                                                                std::placeholders::_2)]) {}

VsyncWaiterIOS::~VsyncWaiterIOS() {
  // This way, we will get no more callbacks from the display link that holds a weak (non-nilling)
  // reference to this C++ object.
  [client_.get() invalidate];
}

void VsyncWaiterIOS::AwaitVSync() {
  [client_.get() await];
}

// |VsyncWaiter|
float VsyncWaiterIOS::GetDisplayRefreshRate() const {
  return [client_.get() displayRefreshRate];
}

}  // namespace flutter

@implementation VSyncClient {
  flutter::VsyncWaiter::Callback callback_;
  fml::scoped_nsobject<NSObject<OS_dispatch_source>> gcd_timer_;
}

- (instancetype)initWithTaskRunner:(fml::RefPtr<fml::TaskRunner>)task_runner
                          callback:(flutter::VsyncWaiter::Callback)callback {
  self = [super init];

  if (self) {
    callback_ = std::move(callback);
    dispatch_queue_t queue = dispatch_get_global_queue(QOS_CLASS_USER_INTERACTIVE, 0);
    gcd_timer_ = fml::scoped_nsobject<NSObject<OS_dispatch_source>> {
        [dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue) retain]
    };
    dispatch_source_set_timer(gcd_timer_.get(), DISPATCH_TIME_NOW, 0.016675 * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(gcd_timer_.get(), ^{
            fml::TimePoint frame_start_time = fml::TimePoint::Now();
            fml::TimePoint frame_target_time = frame_start_time + fml::TimeDelta::FromSecondsF(0.016675);
            dispatch_suspend(gcd_timer_.get());
            callback_(frame_start_time, frame_target_time);
            });
  }

  return self;
}

- (float)displayRefreshRate {
  if (@available(iOS 10.3, *)) {
    auto preferredFPS = display_link_.get().preferredFramesPerSecond;  // iOS 10.0

    // From Docs:
    // The default value for preferredFramesPerSecond is 0. When this value is 0, the preferred
    // frame rate is equal to the maximum refresh rate of the display, as indicated by the
    // maximumFramesPerSecond property.

    if (preferredFPS != 0) {
      return preferredFPS;
    }

    return [UIScreen mainScreen].maximumFramesPerSecond;  // iOS 10.3
  } else {
    return 60.0;
  }
}

- (void)await {
    dispatch_resume(gcd_timer_.get());
}

- (void)invalidate {
    dispatch_source_cancel(gcd_timer_.get());
}

- (void)dealloc {
  [self invalidate];

  [super dealloc];
}

@end
