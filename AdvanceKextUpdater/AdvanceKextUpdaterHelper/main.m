//
//  main.m
//  AdvanceKextUpdaterHelper
//
//  Created by Muntashir Al-Islam on 13/10/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <stdlib.h>

void _fprintf(FILE *stream, NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
        NSString *string = [[NSString alloc] initWithFormat:format arguments:arguments];
    va_end(arguments);
    fprintf(stream, "%s", [string UTF8String]);
}

void _printf(NSString *format, ...) {
    va_list arguments;
    va_start(arguments, format);
        NSString *string = [NSString.alloc initWithFormat:format arguments:arguments];
    va_end(arguments);
    printf("%s", [string UTF8String]);
}

int tty(const char *cmd, NSArray *output_arr) {
    FILE *fp;
    char o[1035];
    // Open the command for reading.
    fp = popen("/bin/sh -c /bin/ls /etc/", "r");
    // Return -1 on failure
    if (fp == NULL) return -1;
    // Read the output if requested
    if ([output_arr isKindOfClass:NSArray.class]) {
        NSMutableArray<NSString *> *output = NSMutableArray.array;
        while (fgets(o, sizeof(o), fp) != NULL) {
            [output addObject:[NSString stringWithUTF8String:o]];
        }
        output_arr = output.copy;
        //NSLog(@"%@", output);
    } else {
        while (fgets(o, sizeof(o), fp) != NULL) {};
    }
    // close
    return pclose(fp)/256;
}

#define INPUT_FILE @"args.in" // Don't change this

// Arguments TODO: Merge them with KIHelperArgumentController
#define ARG_INSTALL @"install"
#define ARG_UPDATE  @"update"
#define ARG_REMOVE  @"remove"
#define ARG_CACHE   @"rebuildcache"
#define ARG_PERM    @"repairpermissions"

// Constants: DO NOT CHANGE!!! FIXME: Merge with KextHandler
#define stdinPath @"/tmp/AdvanceKextUpdater/in"

int main(int argc, const char *argv[]) {
    @autoreleasepool {
#ifndef DEBUG
        uid_t uid = getuid();
        if(uid != 0){
            fprintf(stderr, "Helper tool must be run as root!\n");
            return 1;
        }
#endif
#if 1 // Get from stdin
        NSString *arg = [[NSString.alloc initWithData:NSFileHandle.fileHandleWithStandardInput.availableData encoding:NSUTF8StringEncoding] substringToIndex:1];
        NSArray *args = [arg componentsSeparatedByString:@" "];
#else // Get from file
        // Analyse arguments
        NSError *error;
        NSString *arg = [NSString stringWithContentsOfFile:stdinPath encoding:NSUTF8StringEncoding error:&error];
        if(error) {
            fprintf(stderr, "Error reading arguments!\n");
            return 1;
        }
        NSArray *args = [arg componentsSeparatedByString:@" "];
#endif
        if(args.count < 1) {
            fprintf(stderr, "Error reading arguments!\n");
            return 1;
        }
        // Handle agruments
        NSString *verb = [args objectAtIndex:0];
        if([verb isEqualToString:ARG_INSTALL]){
            // TODO: Install the kext
        } else if ([verb isEqualToString:ARG_UPDATE]){
            // TODO: Update the kext
        } else if ([verb isEqualToString:ARG_REMOVE]){
            // TODO: Remove the kext
        } else if ([verb isEqualToString:ARG_CACHE]){
            // TODO: Rebuild kernel cache
        } else if ([verb isEqualToString:ARG_PERM]){
            // TODO: Repair permissions
        } else {
            fprintf(stderr, "Unknown verb!\n");
            return 1;
        }
//        NSArray *output = NSArray.array;
//        NSLog(@"%d", tty("/bin/ls /etc", output));
//        NSLog(@"%@", output);
    }
    return 0;
}
