//
//  ConfigAuthor.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/23/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigAuthor_h
#define ConfigAuthor_h

@interface ConfigAuthor: NSObject {
    @public // Public properties
    NSString *name;
    NSString *email;
    NSString *homepage;
}
- (instancetype) initWithDictionary: (NSDictionary *) AuthorDictionary;
+ (NSArray *) createFromArrayOfDictionary: (NSArray *) AuthorDictionary;
@end;

#endif /* ConfigAuthor_h */
