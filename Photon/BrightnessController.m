// Copyright (c) 2015-2017 Anish Athalye (me@anishathalye.com)
// Released under GPLv3. See the included LICENSE.txt for details

#import "BrightnessController.h"
#import "Model.h"
#import "Constants.h"
#import "util.h"
#import <IOKit/graphics/IOGraphicsLib.h>
#import <ApplicationServices/ApplicationServices.h>
#import <AppKit/AppKit.h>

@interface BrightnessController ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) Model *model;
@property float lastNoticed;
@property bool running;
@property int ticksPassed;
@property bool noticed;

- (void)tick:(NSTimer *)timer;
- (void) activated;
- (void) observeSetPoint:(float) setPoint;
- (double)getLightness;
- (float)getBrightness;
- (void)setBrightness:(float) level;
- (double)computeLightness:(CGImageRef) image;

@end

@implementation BrightnessController

- (id)init {
    self = [super init];
    if (self) {
        self.model = [Model new];
        self.running = false;
    }
    return self;
}

- (BOOL)isRunning {
    return self.running;
}

/*
 Starts, maintaining invariant that observer is set, model has at least one point.
 Also makes a timer to observe any changes.
 */
- (void)start {
    self.running = true;
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(activated) name:NSWorkspaceDidActivateApplicationNotification object:nil];
    [self.model observeOutput:[self getBrightness] forInput:[self getLightness]];
    [self makeTimer];
}

/*
 Stops, relaxing invariants, stopping any timers that are running.
 */
- (void)stop {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [self.timer invalidate];
    self.timer = nil;
    self.running = false;
}
- (void) activated {
    [self makeTimer];
}

/*
 Sets a timer if one is not set, resetting timer
 state regardless.
 */
- (void) makeTimer {
    self.ticksPassed = 0;
    self.noticed = false;
    self.lastNoticed = [self getBrightness];
    if (!self.timer) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:TICK_INTERVAL
                                                      target:self
                                                    selector:@selector(tick:)
                                                    userInfo:nil
                                                     repeats:YES];
    }
}

/*
 Has the model observe a given set point and updates the
 brightness to match the model.
 */
- (void) observeSetPoint: (float) setPoint {
    double lightness = [self getLightness];
    if (lightness < 0) return;
    [self.model observeOutput:setPoint forInput:lightness];
}

/*
 Timer tick. On first tick, set brightness to prediction.
 On later ticks, check if brightness has changed. If so, update seen
 and check again. If not, do nothing, unless we just finished noticing
 changes or we run out of time. In this case, update the model
 with the current observation and remove the timer.
 */
- (void)tick:(NSTimer *)timer {
    if (self.ticksPassed == 0){
        double lightness = [self getLightness];
        if (lightness < 0) return;
        
        float brightness = [self.model predictFromInput:lightness];
        
        [self setBrightness:brightness];
        self.lastNoticed = brightness;
        self.ticksPassed += 1;
        return;
    }
    self.ticksPassed += 1;
    // check if backlight has been manually changed
    float setPoint = [self getBrightness];
    if (fabsf(setPoint - self.lastNoticed) > CHANGE_NOTICE) {
        self.lastNoticed = setPoint;
        self.noticed = true;
        return; // it's still changing
    } else {
        if (self.noticed || self.ticksPassed * TICK_INTERVAL > WAIT_TIME){
            [self observeSetPoint:setPoint];
            [self.timer invalidate];
            self.timer = nil;
            return;
        }
    }
}

/*
 Remove timer, reset model points, and observe the current situation.
 */
- (void)reset {
    [self.timer invalidate];
    self.timer = nil;
    [self.model reset];
    [self.model observeOutput:[self getBrightness] forInput:[self getLightness]];
}

/*  Utils */

- (double)getLightness {
    CGImageRef contents = CGDisplayCreateImage(kCGDirectMainDisplay);
    if (!contents) {
        return -1;
    }
    double lightness = [self computeLightness:contents];
    CFRelease(contents);
    return lightness;
}

- (double)computeLightness:(CGImageRef) image {
    CFDataRef dataRef = CGDataProviderCopyData(CGImageGetDataProvider(image));
    const unsigned char *data = CFDataGetBytePtr(dataRef);

    size_t width = CGImageGetWidth(image);
    size_t height = CGImageGetHeight(image);

    double lightness = 0;
    const unsigned int kSkip = 16; // uniformly sample screen pixels
    // find RMS lightness value
    if (data) {
        for (size_t y = 0; y < height; y += kSkip) {
            for (size_t x = 0; x < width; x += kSkip) {
                const unsigned char *dptr = &data[(width * y + x) * 4];
                double l = srgb_to_lightness(dptr[0], dptr[1], dptr[2]);

                lightness += l * l;
            }
        }
    }
    lightness = sqrt(lightness / (width * height / (kSkip * kSkip)));

    CFRelease(dataRef);

    return lightness;
}

- (float)getBrightness {
    float level = 1.0f;
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &iterator);
    if (result == kIOReturnSuccess) {
        io_object_t service;
        while ((service = IOIteratorNext(iterator))) {
            IODisplayGetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), &level);
            IOObjectRelease(service);
        }
    }
    return level;
}

- (void)setBrightness:(float)level {
    io_iterator_t iterator;
    kern_return_t result = IOServiceGetMatchingServices(kIOMasterPortDefault,
                                                        IOServiceMatching("IODisplayConnect"),
                                                        &iterator);
    if (result == kIOReturnSuccess) {
        io_object_t service;
        while ((service = IOIteratorNext(iterator))) {
            IODisplaySetFloatParameter(service, kNilOptions, CFSTR(kIODisplayBrightnessKey), level);
            IOObjectRelease(service);
        }
    }
}

@end
