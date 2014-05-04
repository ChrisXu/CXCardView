//
//  DemoContentView.m
//  Examples
//
//  Created by Chris Xu on 2014/5/2.
//  Copyright (c) 2014年 CX. All rights reserved.
//

#import "DemoContentView.h"

@interface DemoContentView ()
{
    UIView *_backgroundView;
    UIButton *_dismissButton;
    UILabel *_description;
}

- (void)setup;
- (void)dismissButtonPressed:(UIButton *)button;

@end

@implementation DemoContentView

- (id)init
{
    self = [super init];
    if (self) {
        [self setup];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    _backgroundView.frame = self.bounds;
}
#pragma mark -
+ (DemoContentView *)defaultView
{
    DemoContentView *view = [[DemoContentView alloc] init];
    view.frame = CGRectMake( 0, 0, 300, 150);
    
    return view;
}

#pragma mark -
- (void)setup
{
    self.backgroundColor = [UIColor clearColor];
    
    self.layer.cornerRadius = 2.;
    self.layer.masksToBounds = NO;
    self.layer.shadowOpacity = 0.5;
    self.layer.shadowOffset = CGSizeMake(0.0, 1.);
    self.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.layer.shadowRadius = 2.;
    
    _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    _backgroundView.alpha = 0.8;
    _backgroundView.backgroundColor = [UIColor whiteColor];
    [self addSubview:_backgroundView];
    
    _dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _dismissButton.frame = CGRectMake(0, 150 - 44, 300, 44);
    _dismissButton.backgroundColor = [UIColor colorWithRed:0.737 green:0.863 blue:0.706 alpha:0.600];
    [_dismissButton addTarget:self action:@selector(dismissButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [_dismissButton setTitle:@"Dismiss" forState:UIControlStateNormal];
    [_dismissButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_dismissButton setTitleColor:[UIColor colorWithRed:0.431 green:0.706 blue:0.992 alpha:1.000] forState:UIControlStateHighlighted];
    [self addSubview:_dismissButton];
}

//Actions
- (void)dismissButtonPressed:(UIButton *)button
{
    if (self.dismissHandler) {
        self.dismissHandler(self);
    }
}
@end
