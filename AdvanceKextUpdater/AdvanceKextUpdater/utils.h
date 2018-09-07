//
//  utils.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 9/7/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef utils_h
#define utils_h

@interface NSString (VersionNumbers)
- (NSString *) shortenedVersionNumberString;
@end

@interface NSArray (MatchFromStringToRegex)
- (BOOL) usingArrayMemberAsRegexMatchString: (NSString *) string;
@end

#endif /* utils_h */
