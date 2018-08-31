//
//  JSONParser.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/24/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef JSONParser_h
#define JSONParser_h

@interface JSONParser: NSObject {}
+ (id) parseFromFile: (NSString *) jsonFile;
+ (id) parse: (NSString *) jsonString;
@end

#endif /* JSONParser_h */
