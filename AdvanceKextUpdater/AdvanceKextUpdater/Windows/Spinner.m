//
//  Spinner.m
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 31/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

#import "Spinner.h"

@interface Spinner ()
@property NSString *titleText;
@property NSString *subtitleText;
@property NSString *singleText;
@property IBOutlet NSTextField *titleTextField;
@property IBOutlet NSTextField *subtitleTextField;
@property IBOutlet NSTextField *singleTextField;
@property IBOutlet NSProgressIndicator *spinner;
@end

@implementation Spinner

-(instancetype)init{return nil;}

-(instancetype)initWithTitle: (NSString *)title {
    self = [super init];
    _titleText = @"";
    _subtitleText = @"";
    _singleText = title;
    return self;
}

-(instancetype)initWithTitle: (NSString *)title AndSubtitle: (NSString *)subtitle {
    self = [super init];
    _titleText = title;
    _subtitleText = subtitle;
    _singleText = @"";
    return self;
}

-(NSNibName)windowNibName {
    return @"Spinner";
}

-(void)windowDidLoad {
    [super windowDidLoad];
    [self reload];
}

-(void)close {
    [_spinner stopAnimation:self];
    [super close];
}

-(instancetype)setTitle:(NSString *)title {
    _titleText = @"";
    _subtitleText = @"";
    _singleText = title;
    return self;
}

-(instancetype)setTitle:(NSString *)title AndSubtitile:(NSString *)subtitle {
    _titleText = title;
    _subtitleText = subtitle;
    _singleText = @"";
    return self;
}

-(instancetype)reload {
    [_titleTextField setStringValue:_titleText];
    [_subtitleTextField setStringValue:_subtitleText];
    [_singleTextField setStringValue:_singleText];
    [_spinner startAnimation:self];
    return self;
}
@end
