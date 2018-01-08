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
@property float lastSet;
@property pid_t lastApp;
@property bool noticed;
@property float lastNoticed;

- (void)tick:(NSTimer *)timer;

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
        self.lastSet = -1; // this causes tick to notice that the brightness has changed significantly
                           // which causes it to create a new data point for the current screen
        self.lastApp = 0;
        self.noticed = false;
        self.lastNoticed = 0;
    }
    return self;
}

- (BOOL)isRunning {
    return self.timer && [self.timer isValid];
}

- (void)start {
    if (self.timer) {
        [self.timer invalidate];
    }
    self.timer = [NSTimer scheduledTimerWithTimeInterval:TICK_INTERVAL
                                                  target:self
                                                selector:@selector(tick:)
                                                userInfo:nil
                                                 repeats:YES];
}

- (void)stop {
    [self.timer invalidate];
    self.timer = nil;
}

- (void)tick:(NSTimer *)timer {
    // check if backlight has been manually changed
    float setPoint = [self getBrightness];
    if (self.noticed || fabsf(self.lastSet - setPoint) > CHANGE_NOTICE) {
        if (!self.noticed) {
            self.noticed = true;
            self.lastNoticed = setPoint;
            return; // wait till next tick to see if it's still changing
        }
        if (fabsf(setPoint - self.lastNoticed) > CHANGE_NOTICE) {
            self.lastNoticed = setPoint;
            return; // it's still changing
        } else {
            // get screen content lightness
            CGImageRef contents = CGDisplayCreateImage(kCGDirectMainDisplay);
            if (!contents) {
                return;
            }
            double lightness = [self computeLightness:contents];
            CFRelease(contents);
            
            [self.model observeOutput:setPoint forInput:lightness];
            self.noticed = false;
            
            float brightness = [self.model predictFromInput:lightness];
            
            [self setBrightness:brightness];
            
            pid_t windowName = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
            self.lastApp = windowName;
            
        }
    } else {
        
        pid_t windowName = NSWorkspace.sharedWorkspace.frontmostApplication.processIdentifier;
        if (windowName == self.lastApp){
            return;
        }
        self.lastApp = windowName;
        
        // get screen content lightness
        CGImageRef contents = CGDisplayCreateImage(kCGDirectMainDisplay);
        if (!contents) {
            return;
        }
        double lightness = [self computeLightness:contents];
        CFRelease(contents);
        
        float brightness = [self.model predictFromInput:lightness];
        [self setBrightness:brightness];
        
    }
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
    self.lastSet = [self getBrightness]; // not just storing `level` cause weird rounding stuff
}

@end
