// Copyright (c) 2015-2017 Anish Athalye (me@anishathalye.com)
// Released under GPLv3. See the included LICENSE.txt for details

#import "Model.h"
#import "Constants.h"
#import "util.h"
#import "NSArray+Functional.h"

@interface XYPoint : NSObject

@property float x;
@property float y;

- (id)initWithX:(float)x andY:(float)y;

@end

@implementation XYPoint

- (id)initWithX:(float)x andY:(float)y {
    self = [super init];
    if (self) {
        self.x = x;
        self.y = y;
    }
    return self;
}

- (NSDictionary *)asDictionary {
    return @{@"x": [NSNumber numberWithFloat:self.x],
             @"y": [NSNumber numberWithFloat:self.y]};
}

- (id)initWithDictionary:(NSDictionary *)dictionary {
    self = [super init];
    if (self && [dictionary isKindOfClass:[NSDictionary class]]) {
        NSNumber *x = [dictionary objectForKey:@"x"];
        if ([x isKindOfClass:[NSNumber class]]) {
            self.x = [x floatValue];
        }
        NSNumber *y = [dictionary objectForKey:@"y"];
        if ([y isKindOfClass:[NSNumber class]]) {
            self.y = [y floatValue];
        }
    }
    return self;
}

@end

@interface Model ()

@property (nonatomic, strong) NSMutableArray *points;

@end

@implementation Model

- (id)init {
    self = [super init];
    if (self) {
        self.points = [NSMutableArray new];
        [self restoreDefaults];
    }
    return self;
}

- (void)observeOutput:(float)output forInput:(float)input {
    // add point
    XYPoint *point = [[XYPoint alloc] initWithX:input andY:output];
    [self.points addObject:point];
    // ensure that they're sorted
    [self.points sortUsingComparator:^NSComparisonResult(XYPoint *obj1, XYPoint *obj2) {
        float first = obj1.x;
        float second = obj2.x;
        if (first < second) {
            return NSOrderedAscending;
        } else if (first > second) {
            return NSOrderedDescending;
        } else {
            return NSOrderedSame;
        }
    }];
    // get current inserted point
    NSInteger index = [self.points indexOfObject:point];
    // remove points that are not monotonically nonincreasing / not spaced apart enough
    NSMutableIndexSet *toDelete = [NSMutableIndexSet new];
    float prevx = point.x, prevy = point.y;
    for (NSInteger i = index - 1; i >= 0; i--) {
        XYPoint *p = [self.points objectAtIndex:i];
        if (p.y < prevy || (prevx - p.x) < MIN_X_SPACING) {
            [toDelete addIndex:i];
        } else {
            prevx = p.x;
            prevy = p.y;
        }
    }
    prevx = point.x;
    prevy = point.y; // reset these
    for (NSInteger i = index + 1; i < self.points.count; i++) {
        XYPoint *p = [self.points objectAtIndex:i];
        if (p.y > prevy || (p.x - prevx) < MIN_X_SPACING) {
            [toDelete addIndex:i];
        } else {
            prevx = p.x;
            prevy = p.y;
        }
    }
    [self.points removeObjectsAtIndexes:toDelete];
    [self synchronizeDefaults];
}

- (float)predictFromInput:(float)input {
    
    // nearest neighbor
    float bestdiff = FLT_MAX, besty = DEFAULT_BRIGHTNESS;
    for (XYPoint *p in self.points) {
//        NSLog(@"%.2f, %.2f",p.x, p.y);
        float diff = fabsf(p.x - input);
        if (diff < bestdiff) {
            bestdiff = diff;
            besty = p.y;
        }
    }
    return besty;

}

- (void)restoreDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *points = [[defaults arrayForKey:DEFAULTS_CALIBRATION_POINTS] map:^(NSDictionary *point) {
        return [[XYPoint alloc] initWithDictionary:point];
    }];
    if (points) {
        self.points = [points mutableCopy];
    }
}

- (void)synchronizeDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *encoded = [self.points map:^(XYPoint *point) {
        return [point asDictionary];
    }];
    [defaults setObject:encoded forKey:DEFAULTS_CALIBRATION_POINTS];
}

@end
