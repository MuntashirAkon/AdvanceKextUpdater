//
//  ZSSUserDefaults.m
//  Cachly
//
//  Created by Nicholas Hubbard on 10/27/15.
//  Copyright © 2015 Zed Said Studio LLC. All rights reserved.
//

#import "ZSSUserDefaults.h"
#import "../../AdvanceKextUpdater/KextHandler.h"

@interface ZSSUserDefaults ()
@property (nonatomic, strong) NSMutableDictionary *cachedDefaults;
@property (nonatomic, strong) NSMutableDictionary *defaults;
@property (nonatomic, strong) NSString *user;
@property (nonatomic) BOOL debug;
@end

@implementation ZSSUserDefaults

+ (id)standardUserDefaults {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
        [_sharedObject setup];
    });
    
    return _sharedObject;
}

- (NSString *)directoryPath {
    return KextHandler.appPath;
}

- (NSString *)filePath {
    return KextHandler.PreferencesFile;
}

- (NSDictionary *)dictionary {
    return [[NSDictionary alloc] initWithContentsOfFile:[self filePath]];
}

- (void)setup {
    // Check for existence of directory
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self directoryPath]]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:[self directoryPath] withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    // Write a plist to disk with if there is not already one
    if (![[NSFileManager defaultManager] fileExistsAtPath:[self filePath]]) {
        NSMutableDictionary *info = [[NSMutableDictionary alloc] init];
        [info writeToFile:[self filePath] atomically:YES];
    }
    
    // Setup the unsaved dictionary
    self.cachedDefaults = [NSMutableDictionary dictionaryWithDictionary:[self dictionary]];
    self.defaults = [NSMutableDictionary dictionaryWithDictionary:[self dictionary]];
    
}

- (void)synchronizeChanges {
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
       
        if (self.cachedDefaults) {
            if (self.debug) {
                NSLog(@"%@ \n%@", [self filePath], self.cachedDefaults);
            }
            [self.cachedDefaults writeToFile:[self filePath] atomically:YES];
        }
        
        self.cachedDefaults = [NSMutableDictionary dictionaryWithDictionary:[self dictionary]];
        
    });
    
}

- (void)registerDefaults:(NSDictionary *)defaults {
    
    self.defaults = [NSMutableDictionary dictionaryWithDictionary:defaults];
    [self.defaults addEntriesFromDictionary:[self cachedDefaults]];
    
}

- (NSDictionary *)dictionaryRepresentation {
    return [NSDictionary dictionaryWithDictionary:self.defaults];
}


#pragma mark - Read/Write Objects

- (void)setObject:(id)value forKey:(NSString *)defaultName {
    if (value && defaultName) {
        [self.cachedDefaults setObject:value forKey:defaultName];
        [self.defaults setObject:value forKey:defaultName];
    }
}

- (id)objectForKey:(NSString *)defaultName {
    return [self.defaults objectForKey:defaultName];
}

#pragma mark - Read/Write Bool

- (void)setBool:(BOOL)boolValue forKey:(NSString *)defaultName {
    if (defaultName) {
        [self.cachedDefaults setObject:@(boolValue) forKey:defaultName];
        [self.defaults setObject:@(boolValue) forKey:defaultName];
    }
}

- (BOOL)boolForKey:(NSString *)defaultName {
    return [[self.defaults objectForKey:defaultName] boolValue];
}

#pragma mark - Read/Write float

- (void)setFloat:(float)value forKey:(NSString *)defaultName {
    if (defaultName) {
        [self.cachedDefaults setObject:@(value) forKey:defaultName];
        [self.defaults setObject:@(value) forKey:defaultName];
    }
}

- (float)floatForKey:(NSString *)defaultName {
    return [[self.defaults objectForKey:defaultName] floatValue];
}


#pragma mark - Read/Write Integer

- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName {
    if (defaultName) {
        [self.cachedDefaults setObject:@(value) forKey:defaultName];
        [self.defaults setObject:@(value) forKey:defaultName];
    }
}

- (NSInteger)integerForKey:(NSString *)defaultName {
    return [[self.defaults objectForKey:defaultName] integerValue];
}


#pragma mark - Read/Write Double

- (void)setDouble:(double)value forKey:(NSString *)defaultName {
    if (defaultName) {
        [self.cachedDefaults setObject:@(value) forKey:defaultName];
        [self.defaults setObject:@(value) forKey:defaultName];
    }
}

- (double)doubleForKey:(NSString *)defaultName {
    return [[self.defaults objectForKey:defaultName] doubleValue];
}

#pragma mark - Remove object

- (void)removeObjectForKey:(NSString *)defaultName {
    if ([self.defaults objectForKey:defaultName]) {
        [self.defaults removeObjectForKey:defaultName];
    }
}

- (void)reset {
    [self.cachedDefaults removeAllObjects];
    [self synchronizeChanges];
}

@end
