//
//  AKUDiskManager.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 1/2/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AKUDiskManager : NSObject
@property NSString * _Nullable diskBSD; // BSDName
@property NSArray<NSDictionary *> *diskInfo;
@property NSDictionary *diskData;

/*!
 * Set disk BSD name
 */
-(void)setDisk:(NSString *)disk;
/*!
 * Whether the disk is mounted
 * @return Boolean value denoting the answer
 */
-(BOOL)isMounted;
/*!
 * Get the mount point of the volume
 * @return The mount point (path)
 */
-(NSString * _Nullable)getMountPoint;
/*!
 * Mount the volume
 * @return Whether the volume is mounted
 */
-(BOOL)mountVolume;
@end

NS_ASSUME_NONNULL_END
