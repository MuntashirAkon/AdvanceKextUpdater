//
//  ConfigRequirments.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/6/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sys/types.h>  // size_t
#import <sys/sysctl.h> // sysctlbyname
#import <stdlib.h>     // malloc
#import "ConfigRequirments.h"
#import "utils.h"

@implementation ConfigRequirments
@synthesize restrictInstall;
@end

@implementation ConfigSWRequirments
@synthesize kernel_max;
@synthesize kernel_min;

- (instancetype) initWithObject: (id) swRequirments {
    self = [super init];
    // Initialize values
    [self setRestrictInstall:YES];
    kernel_min = nil;
    kernel_max = nil;
    if([swRequirments isKindOfClass:NSDictionary.class]){
        id tmpObj = [swRequirments objectForKey:@"restrict"];
        // Check for restrict first
        if(tmpObj != nil)
            [self setRestrictInstall:[tmpObj isEqual: @1] ? YES : NO];
        // Add kernel min, max
        tmpObj = [swRequirments objectForKey:@"kernel"];
        if([tmpObj isKindOfClass:NSString.class]) {
            kernel_min = tmpObj;
            kernel_max = nil;
        } else if([tmpObj isKindOfClass:NSDictionary.class]) {
            kernel_min = [tmpObj objectForKey:@"min"];
            kernel_max = [tmpObj objectForKey:@"max"];
        }
    }
    return self;
}

- (BOOL) matchCriteria {
    if(kernel_min == nil) return YES;
    // Match kernel version
    size_t len = 0;
    sysctlbyname(KERNEL_VERSION, NULL, &len, NULL, 0);
    if (len){
        char *kernel_version = malloc(len*sizeof(char));
        sysctlbyname(KERNEL_VERSION, kernel_version, &len, NULL, 0);
        NSString *kernel_v = [NSString stringWithUTF8String:kernel_version];
        free(kernel_version);
        if([kernel_min compare:kernel_v options:NSNumericSearch] != NSOrderedDescending){
            if(kernel_max == nil || [kernel_max compare:kernel_v options:NSNumericSearch] == NSOrderedDescending) {
                return YES;
            }
        }
    }
    return NO;
}
@end

@implementation ConfigHWRequirments
@synthesize audio_codecs;
@synthesize connected_ids;
@synthesize cpu_regex;
@synthesize gpu_regex;
@synthesize pci_ids;

- (instancetype) initWithObject: (id) hwRequirments {
    self = [super init];
    // Initialize values
    [self setRestrictInstall:YES];
    audio_codecs  = NSArray.array;
    connected_ids = NSArray.array;
    cpu_regex = NSArray.array;
    gpu_regex = NSArray.array;
    pci_ids   = NSArray.array;
    if([hwRequirments isKindOfClass:NSDictionary.class]){
        id tmpObj = [hwRequirments objectForKey:@"restrict"];
        // Check for restrict first
        if(tmpObj != nil)
            [self setRestrictInstall:[tmpObj isEqual: @1] ? YES : NO];
        // audio codecs
        audio_codecs  = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_audio"]];
        connected_ids = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_connected"]];
        cpu_regex = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_cpu"]];
        gpu_regex = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_gpu"]];
        pci_ids   = [self strOrArrayOrNullToArray:[hwRequirments objectForKey:@"match_pci"]];
    }
    return self;
}

- (NSArray *) strOrArrayOrNullToArray: (id) strOrArrayOrNull {
    NSMutableArray *tmpArr = NSMutableArray.array;
    if([strOrArrayOrNull isKindOfClass:NSString.class]){
        [tmpArr addObject:strOrArrayOrNull];
    } else if([strOrArrayOrNull isKindOfClass:NSArray.class]){
        return [strOrArrayOrNull copy];
    }
    return [tmpArr copy];
}

// BUG ALERT!!!
- (BOOL) matchCriteria {
    NSUInteger n_checks = 5; // 5 checks are to be run
    // Run checks
    // Audio Codec ID checks
    if(self.audio_codecs.count > 0) {
        NSArray<NSString *> *audioCodecs = [self getAudioCodecList];
        for(NSString *audioCodec in audioCodecs){
            if([self.audio_codecs indexOfObject:audioCodec] != NSNotFound) {
                --n_checks;
                break;
            }
        }
    } else --n_checks;
    // Connected IDs checks
    if(self.connected_ids.count > 0) {
        // TODO: Run check
        --n_checks;
    } else --n_checks;
    // CPU brand string checks
    if(self.cpu_regex.count > 0) {
        if([self.cpu_regex usingArrayMemberAsRegexMatchString: [self getCPUBrandString]]) --n_checks;
    } else --n_checks;
    // GPU model checks
    if(self.gpu_regex.count > 0) {
        NSArray<NSString *> *gpuList = [self getGPUList];
        for(NSString *gpu in gpuList){
            if([self.gpu_regex usingArrayMemberAsRegexMatchString: gpu])
                --n_checks;
        }
    } else --n_checks;
    // PCI IDs checks
    if(self.pci_ids.count > 0) {
        NSArray<pciDevice *> *pci_list = [pciDevice readIDs];
        NSString *pci_id;
        for(pciDevice *pci in pci_list){
            pci_id = [NSString stringWithFormat:kPCIFormat, pci.shadowVendor.integerValue, pci.shadowDevice.integerValue];
            if([self.pci_ids indexOfObject:pci_id] != NSNotFound) {
                --n_checks;
                break;
            }
        }
    } else --n_checks;
    return n_checks == 0 ? YES : NO;
}

- (NSString *) getCPUBrandString {
    size_t len = 0;
    sysctlbyname(CPU_BRAND_STRING, NULL, &len, NULL, 0);
    if (len){
        char *cpu_brand_string = malloc(len*sizeof(char));
        sysctlbyname(CPU_BRAND_STRING, cpu_brand_string, &len, NULL, 0);
        NSString *kv = [NSString stringWithUTF8String:cpu_brand_string];
        free(cpu_brand_string);
        return kv;
    }
    return nil;
}

// @see https://stackoverflow.com/a/18099669/4147849
- (NSArray<NSString *> *) getGPUList {
    NSMutableArray<NSString *> *gpuList = NSMutableArray.array;
    // Get dictionary of all the PCI Devicces
    CFMutableDictionaryRef matchDict = IOServiceMatching("IOPCIDevice");
    // Create an iterator
    io_iterator_t iterator;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, matchDict, &iterator) == kIOReturnSuccess){
        // Iterator for devices found
        io_registry_entry_t regEntry;
        while ((regEntry = IOIteratorNext(iterator))) {
            // Put this services object into a dictionary object.
            CFMutableDictionaryRef serviceDictionary;
            if (IORegistryEntryCreateCFProperties(regEntry, &serviceDictionary, kCFAllocatorDefault, kNilOptions) != kIOReturnSuccess){
                // Service dictionary creation failed.
                IOObjectRelease(regEntry);
                continue;
            }
            const void *GPUModel = CFDictionaryGetValue(serviceDictionary, @"model");
            
            if (GPUModel != nil) {
                if (CFGetTypeID(GPUModel) == CFDataGetTypeID()) {
                    // Create a string from the CFDataRef.
                    NSString *modelName = [[NSString alloc] initWithData:(__bridge NSData *)GPUModel encoding:NSASCIIStringEncoding];
                    [gpuList addObject:modelName];
                }
            }
            // Release the dictionary
            CFRelease(serviceDictionary);
            // Release the serviceObject
            IOObjectRelease(regEntry);
        }
        // Release the iterator
        IOObjectRelease(iterator);
    }
    return gpuList.copy;
}

// Modified from DPCIManager, 2012 (c) phpdev32
- (NSArray *) getAudioCodecList {
    NSMutableArray *temp = [NSMutableArray array];
    io_iterator_t itThis;
    io_service_t service;
    io_service_t parent;
    io_name_t name;
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("VoodooHDADevice"), &itThis) == KERN_SUCCESS) {
        while((service = IOIteratorNext(itThis))) {
            IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent);
            IORegistryEntryGetName(parent, name);
//            pciDevice *audio = [pciDevice create:parent];
            io_connect_t connect;
            if (IOServiceOpen(service, mach_task_self(), 0, &connect) == KERN_SUCCESS){
                mach_vm_address_t address;
                mach_vm_size_t size;
                if (IOConnectMapMemory64(connect, 0x2000, mach_task_self(), &address, &size, kIOMapAnywhere|kIOMapDefaultCache) == KERN_SUCCESS){
                    __block NSMutableArray *hda = [NSMutableArray array];
                    NSString *dump = [[NSString alloc] initWithBytes:(const void *)address length:size encoding:NSUTF8StringEncoding];
                    [[NSRegularExpression regularExpressionWithPattern:@"Codec ID: 0x([0-9a-f]{8})(?:\n.*){3}Revision: 0x([0-9a-f]{2})\n.*Stepping: 0x([0-9a-f]{2})" options:0 error:nil] enumerateMatchesInString:dump options:0 range:NSMakeRange(0, dump.length) usingBlock:^void(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop){
                        long codecid = strHexDec([dump substringWithRange:[result rangeAtIndex:1]]), revision = strHexDec([dump substringWithRange:[result rangeAtIndex:2]]) << 8 | strHexDec([dump substringWithRange:[result rangeAtIndex:3]]);
                        // Add AudioCodec
                        [hda addObject:[NSString stringWithFormat:@"%08lX", codecid]];
                        // Add AudioCodec:RevisionID
                        [hda addObject:[NSString stringWithFormat:@"%08lX:%06lX", codecid, revision]];
                    }];
                    [temp addObjectsFromArray:hda];
                    IOConnectUnmapMemory64(connect, 0x2000, mach_task_self(), address);
                }
                IOServiceClose(connect);
            }
            IOObjectRelease(parent);
            IOObjectRelease(service);
        }
        IOObjectRelease(itThis);
    }
    if (IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching("AppleHDAController"), &itThis) == KERN_SUCCESS){
        while((service = IOIteratorNext(itThis))) {
            IORegistryEntryGetParentEntry(service, kIOServicePlane, &parent);
            IORegistryEntryGetName(parent, name);
            io_service_t child;
//            pciDevice *audio = [pciDevice create:parent];
            io_iterator_t itChild;
            if (IORegistryEntryGetChildIterator(service, kIOServicePlane, &itChild) == KERN_SUCCESS){
                while ((child = IOIteratorNext(itChild))){
                    long codecid = [[pciDevice grabNumber:CFSTR("IOHDACodecVendorID") forService:child] longValue] & 0xFFFFFFFF;
                    long revision = [[pciDevice grabNumber:CFSTR("IOHDACodecRevisionID") forService:child] longValue] & 0xFFFFFF;
                    // Add AudioCodec
                    [temp addObject:[NSString stringWithFormat:@"%08lX", codecid]];
                    // Add AudioCodec:RevisionID
                    [temp addObject:[NSString stringWithFormat:@"%08lX:%06lX", codecid, revision]];
                    IOObjectRelease(child);
                }
                IOObjectRelease(itChild);
            }
            IOObjectRelease(parent);
            IOObjectRelease(service);
        }
        IOObjectRelease(itThis);
    }
    return [temp copy];
}
@end
