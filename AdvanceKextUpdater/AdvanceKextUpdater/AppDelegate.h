//
//  AppDelegate.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/21/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate> {
    NSArray *installedKexts;
    NSArray *allTheKexts;
    // For kextConfig
    NSString *guide;
    NSString *homepage;
}
@property NSDictionary *overview;
@property NSDictionary *allKexts;
@property NSDictionary *kextProperties;
@property NSDictionary *loadingTexts; // singleText|titleText with subtitleText

-(IBAction)fetchAllKextInfo:(NSTableView *)sender;
-(IBAction)fetchInstalledKextInfo:(NSTableView *)sender;
-(IBAction)fetchGuide:(NSButton *)sender;
-(IBAction)repairPermissions:(NSButton *)sender;
-(IBAction)rebuildCache:(NSButton *)sender;
-(IBAction)gotoHomepage:(NSButton *)sender;

@end

