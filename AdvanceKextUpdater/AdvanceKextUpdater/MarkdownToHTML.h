//
//  MarkdownToHTML.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 10/15/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#ifndef MarkdownToHTML_h
#define MarkdownToHTML_h

@interface MarkdownToHTML : NSObject {
    NSString *html_text;
    NSString *mkdown_text;
}

- (instancetype) initWithMarkdown: (NSString *) text;
- (NSString *) render;
@end
#endif /* MarkdownToHTML_h */
