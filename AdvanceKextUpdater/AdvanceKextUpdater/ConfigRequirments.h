//
//  ConfigRequirments.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/6/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigRequirments_h
#define ConfigRequirments_h

@interface ConfigRequirments : NSObject {}
@property BOOL restrictInstall;
@end

@interface ConfigSWRequirments: ConfigRequirments {}
@property NSString *kernel_max; // Wildcard|NSString|null
@property NSString *kernel_min; // Wildcard|NSString|null

- (instancetype) initWithObject: (id) swRequirments;
@end

@interface ConfigHWRequirments: ConfigRequirments {}
@property NSArray<NSString *> *audio_codecs; // AudioCodec:Revision|AudioCodec
@property NSArray<NSString *> *connected_ids; // VendorID:ProductID
@property NSArray<NSString *> *cpu_regex; // CPU brand string matcher
// system_profiler SPDisplaysDataT *Chipset Model:/ {printf $2 "\n"}'
@property NSArray<NSString *> *gpu_regex; // GPU string matcher
@property NSArray<NSString *> *pci_ids; // VendorID:ProductID

- (instancetype) initWithObject: (id) hwRequirments;
@end

#endif /* ConfigRequirments_h */
