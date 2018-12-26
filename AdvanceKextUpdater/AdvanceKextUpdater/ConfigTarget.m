//
//  ConfigTarget.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 26/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConfigTarget.h"
#import "ConfigMacOSVersionControl.h"

NSString *const ctSLE = @"SLE";
NSString *const ctLE = @"LE";

@implementation ConfigTarget
@synthesize target;
- (instancetype) init {
    return nil;
}
- (instancetype) initWithTarget:(NSString *)target {
    if([target isEqualToString:ctSLE]){
        self->target = kSLE;
    } else {
        if ([ConfigMacOSVersionControl getMacOSVersionInInt] >= 11)
            self->target = kLE;
        else
            self->target = kSLE;
    }
    return self;
}
@end
