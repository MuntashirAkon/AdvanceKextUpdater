//
//  ZSSUserDefaults.h
//  Cachly
//
//  Created by Nicholas Hubbard on 10/27/15.
//  Copyright © 2015 Zed Said Studio LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ZSSUserDefaults : NSObject

/**
 *  Default
 *
 *  @return object
 */
+ (id)standardUserDefaults;

/**
 *  Write changes to disk
 *
 */
- (void)synchronizeChanges;

/**
 *  Sets defaults that are saved in memory, but not written to disk. These must be set everytime you launch your app as these are not written to disk.
 *
 *  @param defaults Defaults
 */
- (void)registerDefaults:(NSDictionary *)defaults;

/**
 *  Dictionary of all keys and values
 *
 *  @return NSDictionary
 */
- (NSDictionary *)dictionaryRepresentation;

/**
 *  Set the object for key
 *
 *  @param value       Object to set
 *  @param defaultName Key
 */
- (void)setObject:(id)value forKey:(NSString *)defaultName;

/**
 *  Object for given key
 *
 *  @param defaultName Key
 *
 *  @return object
 */
- (id)objectForKey:(NSString *)defaultName;

/**
 *  Set bool value
 *
 *  @param boolValue   Boolean
 *  @param defaultName Key
 */
- (void)setBool:(BOOL)boolValue forKey:(NSString *)defaultName;

/**
 *  Bool for key
 *
 *  @param defaultName Key
 *
 *  @return BOOL
 */
- (BOOL)boolForKey:(NSString *)defaultName;

/**
 *  Set Float Value
 *
 *  @param value       Float value
 *  @param defaultName Key
 */
- (void)setFloat:(float)value forKey:(NSString *)defaultName;

/**
 *  Float value for key
 *
 *  @param defaultName Key
 *
 *  @return float
 */
- (float)floatForKey:(NSString *)defaultName;

/**
 *  Set Integer value
 *
 *  @param value       Integer
 *  @param defaultName Key
 */
- (void)setInteger:(NSInteger)value forKey:(NSString *)defaultName;

/**
 *  Integer for key
 *
 *  @param defaultName Key
 *
 *  @return NSInteger
 */
- (NSInteger)integerForKey:(NSString *)defaultName;

/**
 *  Set double for key
 *
 *  @param value       Double
 *  @param defaultName Key
 */
- (void)setDouble:(double)value forKey:(NSString *)defaultName;

/**
 *  Double for key
 *
 *  @param defaultName Key
 *
 *  @return double
 */
- (double)doubleForKey:(NSString *)defaultName;

/**
 *  Remove object for key
 *
 *  @param defaultName Key
 */
- (void)removeObjectForKey:(NSString *)defaultName;

/**
 *  Reset preferences
 */
- (void)reset;

@end
