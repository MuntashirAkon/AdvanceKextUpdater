//
//  ConfigTarget.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 26/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigTarget_h
#define ConfigTarget_h

FOUNDATION_EXPORT NSString *const ctSLE;
FOUNDATION_EXPORT NSString *const ctLE;
@interface ConfigTarget : NSObject
@property (strong, nonatomic, readonly) NSString * target;
- (instancetype) initWithTarget: (NSString *) target;
@end
#endif /* ConfigTarget_h */
