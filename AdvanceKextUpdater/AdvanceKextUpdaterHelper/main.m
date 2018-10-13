//
//  main.m
//  AdvanceKextUpdaterHelper
//
//  Created by Muntashir Al-Islam on 13/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "KextHandler.h"

#define INPUT_FILE @"args.in" // Don't change this

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        uid_t uid = getuid();
        if(uid != 0){
            printf("Helper tool must be run as root!\n");
            return 1;
        }
        // Analyse arguments
        NSError *error;
        NSString *arg = [NSString stringWithContentsOfFile:KextHandler.tmpPath encoding:NSUTF8StringEncoding error:&error];
        if(error) {
            printf("Error reading arguments!\n");
            return 1;
        }
        
    }
    return 0;
}
