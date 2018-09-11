//
//  ConfigBinary.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/12/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigBinary_h
#define ConfigBinary_h

#define CB_RELEASE @"rel"
#define CB_DEBUG   @"dev"

@interface BinaryHandler: NSObject {}
@property (strong, nonatomic, readonly) NSString *url;
@property (strong, nonatomic, readonly) NSString *script;
@property (strong, nonatomic, readonly) NSString *location;

- (instancetype) initWithDict: (id) binaryDict;
@end

@interface ConfigBinary: NSObject {}
@property (strong, nonatomic, readonly) BinaryHandler *recommended;
@property (strong, nonatomic, readonly) BinaryHandler *dev;
@property (strong, nonatomic, readonly) BinaryHandler *rel;
@property (strong, nonatomic, readonly) NSString *postInstallScript;

- (instancetype) initWithDict: (NSDictionary *) binaryDict;
@end

#endif /* ConfigBinary_h */
