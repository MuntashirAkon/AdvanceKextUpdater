//
//  hasInternetConnection.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/30/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#include <SystemConfiguration/SystemConfiguration.h>

// @see https://stackoverflow.com/a/18750343/4147849
static inline BOOL hasInternetConnection() {
    BOOL returnValue = NO;
    
    struct sockaddr zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sa_len = sizeof(zeroAddress);
    zeroAddress.sa_family = AF_INET;
    
    SCNetworkReachabilityRef reachabilityRef = SCNetworkReachabilityCreateWithAddress(NULL, (const struct sockaddr*)&zeroAddress);
    
    if (reachabilityRef != NULL){
        SCNetworkReachabilityFlags flags = 0;
        if(SCNetworkReachabilityGetFlags(reachabilityRef, &flags)) {
            BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
            BOOL connectionRequired = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
            returnValue = (isReachable && !connectionRequired) ? YES : NO;
        }
        CFRelease(reachabilityRef);
    }
    
    return returnValue;
}
