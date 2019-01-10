//
//  AboutWindowController.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 10/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "AboutWindowController.h"

@interface AboutWindowController ()

@end

@implementation AboutWindowController{
    IBOutlet NSTextField *appName;
    IBOutlet NSTextField *appVersion;
    IBOutlet NSTextField *copyrightText;
    IBOutlet NSImageView *appIcon;
}

- (NSNibName) windowNibName {
    return @"About";
}

- (void)windowDidLoad {
    [super windowDidLoad];
    appIcon.image = [NSApp applicationIconImage];
    appIcon.imageScaling = NSImageScaleAxesIndependently;
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    appName.stringValue = [infoDictionary objectForKey:@"CFBundleName"];
#if DEBUG
    appVersion.stringValue = [NSString stringWithFormat:@"Version %@ Build %@ (Debug)", [infoDictionary objectForKey:@"CFBundleShortVersionString"], [infoDictionary objectForKey:@"CFBundleVersion"]];
#else
    appVersion.stringValue = [NSString stringWithFormat:@"Version %@ Build %@", [infoDictionary objectForKey:@"CFBundleShortVersionString"], [infoDictionary objectForKey:@"CFBundleVersion"]];
#endif
    copyrightText.stringValue = [infoDictionary objectForKey:@"NSHumanReadableCopyright"];
    NSLog(@"%@", infoDictionary);
}

-(IBAction)openRepoLink:(id)sender{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [NSWorkspace.sharedWorkspace openURL:[NSURL URLWithString:@"https://github.com/MuntashirAkon/AdvanceKextUpdater"]];
    });
}

@end
