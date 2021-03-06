// Copyright (c) 2015-2017 Anish Athalye (me@anishathalye.com)
// Released under GPLv3. See the included LICENSE.txt for details

#import <Foundation/Foundation.h>

@interface BrightnessController : NSObject

@property (nonatomic, readonly) BOOL isRunning;

- (void)start;
- (void)stop;
- (void)reset;

@end
