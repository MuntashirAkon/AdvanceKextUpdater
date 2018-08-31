//
//  ConfigKextVersionControl.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/27/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigKextVersionControl_h
#define ConfigKextVersionControl_h

@interface ConfigKextVersionControl: NSObject {}
@property NSString *kextName;
@property NSString *version;
@property BOOL      uptoLatest;

- (void) setVersionString: (NSString *) version;
@end

@interface ConfigRequiredKexts: ConfigKextVersionControl {}
+ (NSArray<ConfigRequiredKexts *> *) initWithDictionaryOrNull: (id) requiredKexts;
@end

@interface ConfigConflictKexts: ConfigKextVersionControl {}
@property NSString *action;
+ (NSArray<ConfigConflictKexts *> *) initWithDictionaryOrNull: (id) conflictKexts;
@end

@interface ConfigReplacedByKexts: ConfigKextVersionControl {}
@property NSString *sinceMacOSVersion;

+ (NSArray<ConfigReplacedByKexts *> *) initWithDictionaryOrNull: (id) replacedByKexts;
@end

#endif /* ConfigKextVersionControl_h */
