//
//  ConfigSuggestion.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 8/31/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef ConfigSuggestion_h
#define ConfigSuggestion_h

@interface ConfigSuggestion: NSObject {}

@property NSString *name;
@property NSString *text;

+(NSArray *) createFromArray: (NSArray *) suggestions;

@end

#endif /* ConfigSuggestion_h */
