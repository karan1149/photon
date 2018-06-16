// Copyright (c) 2015-2017 Anish Athalye (me@anishathalye.com)
// Released under GPLv3. See the included LICENSE.txt for details

#import "AppDelegate.h"
#import "Constants.h"
#import "BrightnessController.h"
#import "EMCLoginItem.h"

@interface AppDelegate ()

@property (strong, nonatomic) IBOutlet NSMenu *statusMenu;
@property (strong, nonatomic) IBOutlet NSMenuItem *toggle;
@property (strong, nonatomic) IBOutlet NSMenuItem *startupItem;
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (strong, nonatomic) BrightnessController *brightnessController;
@property (strong, nonatomic) EMCLoginItem *loginController;
@property bool startupItemChecked;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [self.statusItem setMenu:self.statusMenu];
    NSImage *statusImage = [NSImage imageNamed:@"StatusBarImageTemplate"];
    [self.statusItem setImage:statusImage];
    [self.statusItem setHighlightMode:YES];
    

    self.brightnessController = [BrightnessController new];
    [self.brightnessController start];
    [self.toggle setTitle:STOP];
    
    
    
    self.loginController = [EMCLoginItem new];
    if (![self.loginController isLoginItem]) {
        [self.loginController addLoginItem];
    }
    
    [self.startupItem setState:NSOnState];
    self.startupItemChecked = true;
    
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // do not need to do anything
}

- (IBAction)menuActionQuit:(id)sender {
    [NSApp terminate:self];
}

- (IBAction)menuActionToggle:(id)sender {
    if (self.brightnessController.isRunning) {
        [self.brightnessController stop];
        [self.toggle setTitle:START];
    } else {
        [self.brightnessController start];
        [self.toggle setTitle:STOP];
    }
}

- (IBAction)startupItemToggle:(id)sender {
    if (self.startupItemChecked) {
        if ([self.loginController isLoginItem]) {
            [self.loginController removeLoginItem];
        }
        [self.startupItem setState:NSOffState];
        self.startupItemChecked = false;
    } else {
        if (![self.loginController isLoginItem]) {
            [self.loginController addLoginItem];
        }
        [self.startupItem setState:NSOnState];
        self.startupItemChecked = true;
    }
}



- (IBAction)resetItem:(id)sender {
    [self.brightnessController reset];
}
@end
