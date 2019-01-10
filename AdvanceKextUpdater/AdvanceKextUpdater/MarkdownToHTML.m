//
//  MarkdownToHTML.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 10/15/18.
//  Copyright © 2018 Muntashir Al-Islam. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MMMarkdown/MMMarkdown.h>
#import "MarkdownToHTML.h"
#import "utils.h"

@implementation MarkdownToHTML

// No default initializer
- (instancetype)init {
    return nil;
}

- (instancetype)initWithMarkdown:(NSString *)text {
    // Parse Markdown
    NSError *error;
    mkdown_text = text;
    html_text = [MMMarkdown HTMLStringWithMarkdown:mkdown_text extensions:MMMarkdownExtensionsGitHubFlavored error:&error];
    if(error != nil){
        html_text = @"<p>Incomplete Markdown systax!</p>";
    }
    return self;
}

-(NSString *)render {
    NSString *cssFile = [NSBundle.mainBundle pathForResource:@"github-markdown" ofType:@"css"];
    return [NSString stringWithFormat:@"<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\"><style>%@ %@</style><style> .markdown-body{box-sizing:border-box;min-width:200px;max-width:980px;margin:0 auto;padding:45px;} @media (max-width: 767px) {.markdown-body{padding:15px;}}</style><article class=\"markdown-body\">%@</article>", (isDarkMode() ? @"html{-webkit-filter:invert(95%) hue-rotate(180deg) contrast(70%) !important; background: #fff;} .line-content {background-color: #fefefe;}" : @""), [NSString stringWithContentsOfFile:cssFile encoding:NSUTF8StringEncoding error:nil], html_text];
}
@end
