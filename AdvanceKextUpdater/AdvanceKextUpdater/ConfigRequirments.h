//
//  ConfigRequirments.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/6/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigRequirments_h
#define ConfigRequirments_h

#import "PCI.h"

#define KERNEL_VERSION "kern.osrelease"
#define CPU_BRAND_STRING "machdep.cpu.brand_string"

@interface ConfigRequirments : NSObject {}
@property BOOL restrictInstall;
@end

@interface ConfigSWRequirments: ConfigRequirments {}
@property NSString *kernel_max; // Wildcard|NSString|null
@property NSString *kernel_min; // Wildcard|NSString|null

- (instancetype) initWithObject: (id) swRequirments;
- (BOOL) matchCriteria;
@end

@interface ConfigHWRequirments: ConfigRequirments {}
@property NSArray<NSString *> *audio_codecs;  // AudioCodec:Revision|AudioCodec
@property NSArray<NSString *> *connected_ids; // VendorID:ProductID
@property NSArray<NSString *> *cpu_regex;     // CPU brand string matcher
@property NSArray<NSString *> *gpu_regex;     // GPU string matcher
@property NSArray<NSString *> *pci_ids;       // VendorID:ProductID

- (instancetype) initWithObject: (id) hwRequirments;
- (BOOL) matchCriteria;
@end

#endif /* ConfigRequirments_h */
