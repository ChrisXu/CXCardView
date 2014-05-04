//
//  DemoContentView.h
//  Examples
//
//  Created by Chris Xu on 2014/5/2.
//  Copyright (c) 2014年 CX. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DemoContentView;
typedef void(^ActionHandler)(DemoContentView *view);
@interface DemoContentView : UIView

@property (nonatomic, copy) ActionHandler dismissHandler;

+ (DemoContentView *)defaultView;

@end
