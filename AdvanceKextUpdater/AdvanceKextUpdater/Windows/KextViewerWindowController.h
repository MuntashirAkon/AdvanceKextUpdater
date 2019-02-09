//
//  KextViewer.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 31/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "../KextConfig.h"

NS_ASSUME_NONNULL_BEGIN

#define COLOR_GREEN [NSColor colorWithCalibratedRed:0 green:143/255.0f blue:0 alpha:1.0f] // Success
#define COLOR_RED [NSColor redColor] // Failure
#define COLOR_ORANGE [NSColor orangeColor] // Warning

typedef enum {
    KextInstall,
    KextUpdate,
    KextRemove
} KextInstallerType;

@interface KextViewerWindowController : NSWindowController <NSApplicationDelegate>
-(instancetype)initWithKextConfig: (KextConfig *) kextConfig;
-(IBAction)installKext:(id)sender;
-(IBAction)updateKext:(id)sender;
-(IBAction)removeKext:(id)sender;
-(IBAction)fetchGuide:(id)sender;
@end

NS_ASSUME_NONNULL_END
