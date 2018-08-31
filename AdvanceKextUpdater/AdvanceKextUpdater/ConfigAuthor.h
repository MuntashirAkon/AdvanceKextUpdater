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
}
@property NSString *name;
@property NSString *email;
@property NSString *homepage;

+ (NSArray *) createFromArrayOfDictionary: (NSArray *) AuthorDictionary;
@end;

#endif /* ConfigAuthor_h */
