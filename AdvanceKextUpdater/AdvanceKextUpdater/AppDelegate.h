//
//  AppDelegate.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KextHandler.h"

#define COLOR_GREEN [NSColor colorWithCalibratedRed:0 green:143/255.0f blue:0 alpha:1.0f] // Success
#define COLOR_RED [NSColor redColor] // Failure
#define COLOR_ORANGE [NSColor orangeColor] // Warning

typedef enum {
    KextInstall,
    KextUpdate,
    KextRemove
} KextInstallerType;

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    KextHandler *kextHandler;
    NSMutableArray<NSString *> *installedKexts;
    NSArray<NSString *> *allTheKexts;
    NSDictionary<NSString *, NSURL *> *remoteKexts;
    // For kextConfig
    NSString *guide;
    NSString *homepage;
    // For Task
    KextInstallerType taskType;
}
@property NSDictionary *overview;
@property NSDictionary *allKexts;
@property NSDictionary *kextProperties;
@property NSDictionary *loadingTexts; // singleText|titleText with subtitleText

-(IBAction)fetchAllKextInfo:(NSTableView *)sender;
-(IBAction)fetchInstalledKextInfo:(NSTableView *)sender;
-(IBAction)fetchGuide:(NSButton *)sender;
-(IBAction)fetchSuggestions:(NSButton *)sender;
-(IBAction)repairPermissions:(NSButton *)sender;
-(IBAction)rebuildCache:(NSButton *)sender;
-(IBAction)gotoHomepage:(NSButton *)sender;
-(IBAction)installKext:(NSButton *)sender;
-(IBAction)updateKext:(NSButton *)sender;
-(IBAction)removeKext:(NSButton *)sender;
-(IBAction)closeTaskViwer:(NSButton *)sender;
-(IBAction)runTask:(NSButton *)sender;

/// Default preferences
+(NSDictionary *)appDefaults;
@end

