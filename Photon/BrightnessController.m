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
//@property float lastSet;
@property float lastNoticed;
@property bool running;
@property int ticksPassed;
@property bool noticed;

- (void)tick:(NSTimer *)timer;
- (void) activated;

// even though the screen gradually transitions between brightness levels,
// getBrightness returns the level to which the brightness is set
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

- (void)start {
    self.running = true;
    [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(activated) name:NSWorkspaceDidActivateApplicationNotification object:nil];
//    if (self.timer) {
//        [self.timer invalidate];
//    }
//    self.timer = [NSTimer scheduledTimerWithTimeInterval:TICK_INTERVAL
//                                                  target:self
//                                                selector:@selector(tick:)
//                                                userInfo:nil
//                                                 repeats:YES];
}

- (void)stop {
    [[[NSWorkspace sharedWorkspace] notificationCenter] removeObserver:self];
    [self.timer invalidate];
    self.timer = nil;
    self.running = false;
}

- (void) activated {
    if (self.timer) {
        
    } else {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:TICK_INTERVAL
                                                      target:self
                                                    selector:@selector(tick:)
                                                    userInfo:nil
                                                     repeats:YES];
        self.ticksPassed = 0;

    }
    
    self.lastSet = -1; // this causes tick to notice that the brightness has changed significantly
    // which causes it to create a new data point for the current screen
    self.noticed = false;
    self.lastNoticed = 0;
}

//- (void)tick:(NSTimer *)timer {
//    NSLog(@"tick");
//    // check if backlight has been manually changed
//    float setPoint = [self getBrightness];
//    if (self.noticed || fabsf(self.lastSet - setPoint) > CHANGE_NOTICE) {
//        if (!self.noticed) {
//            NSLog(@"just noticed");
//            self.noticed = true;
//            self.lastNoticed = setPoint;
//            return; // wait till next tick to see if it's still changing
//        }
//        if (fabsf(setPoint - self.lastNoticed) > CHANGE_NOTICE) {
//            NSLog(@"still noticing");
//            self.lastNoticed = setPoint;
//            return; // it's still changing
//        } else {
//            NSLog(@"stopped noticing");
//            // get screen content lightness
//            CGImageRef contents = CGDisplayCreateImage(kCGDirectMainDisplay);
//            if (!contents) {
//                NSLog(@"failed to get contents");
//                return;
//            }
//            NSLog(@"got contents, sending to model");
//            double lightness = [self computeLightness:contents];
//            CFRelease(contents);
//
//            [self.model observeOutput:setPoint forInput:lightness];
//            self.noticed = false;
//
//            float brightness = [self.model predictFromInput:lightness];
//
//            [self setBrightness:brightness];
//
//            pid_t windowName = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
//            self.lastApp = windowName;
//
//        }
//    } else {
//
//        pid_t windowName = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
//        if (windowName == self.lastApp){
//            return;
//        }
//        NSLog(@"app change");
//        self.lastApp = windowName;
//
//        // get screen content lightness
//        CGImageRef contents = CGDisplayCreateImage(kCGDirectMainDisplay);
//        if (!contents) {
//            return;
//        }
//        double lightness = [self computeLightness:contents];
//        CFRelease(contents);
//
//        float brightness = [self.model predictFromInput:lightness];
//        [self setBrightness:brightness];
//
//    }
//}
- (void)reset {
    [self.timer invalidate];
    self.timer = nil;
    [self.model reset];
    [self.model observeOutput:[self getBrightness] forInput:[self getLightness]];
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
    NSLog(@"setting to %f", level);
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
//    self.lastSet = [self getBrightness]; // not just storing `level` cause weird rounding stuff
}

@end
