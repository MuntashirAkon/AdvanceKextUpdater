//
//  Spinner.h
//  AdvanceKextUpdater
//
//  Created by Muntashir Al-Islam on 31/1/19.
//  Copyright © 2019 Muntashir Al-Islam. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface Spinner : NSWindowController
-(instancetype)initWithTitle: (NSString *)title;
-(instancetype)initWithTitle: (NSString *)title AndSubtitle: (NSString *)subtitle;
-(instancetype)setTitle:(NSString *)title;
-(instancetype)setTitle:(NSString *)title AndSubtitile:(NSString *)subtitle;
-(instancetype)setSubtitile:(NSString *)subtitle;
-(instancetype)reload;
@end

NS_ASSUME_NONNULL_END
