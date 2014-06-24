//
//  CXCardView.h
//  CardViewDemo
//
//  Created by Chris Xu on 2014/4/16.
//  Copyright (c) 2014年 ChrisXu. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSInteger const kCXCardViewRemoveWindowIdentifier = 82713;

@class CXCardView, CXCardContainerView;
typedef void(^CXCardViewHandler)(CXCardView *cardView);
@interface CXCardView : UIView

@property (nonatomic, copy) CXCardViewHandler willShowHandler;
@property (nonatomic, copy) CXCardViewHandler didShowHandler;
@property (nonatomic, copy) CXCardViewHandler willMoveToPenddingHandler;
@property (nonatomic, copy) CXCardViewHandler didMoveToPenddingHandler;
@property (nonatomic, copy) CXCardViewHandler willDismissHandler;
@property (nonatomic, copy) CXCardViewHandler didDismissHandler;

@property (nonatomic, assign) BOOL draggable;
@property (nonatomic, assign) NSTimeInterval moveToCenterDuration;
@property (nonatomic, assign) NSTimeInterval moveToBottomDuration;
@property (nonatomic, assign) NSTimeInterval moveToPedingDuration;
@property (nonatomic, strong, readonly) UIView *contentView;
@property (nonatomic, strong, readonly) CXCardContainerView *containerView;

/**
 *  Show the cardView with view immediately.
 *
 *  @param view      Your custom view.
 *  @param draggable Set No to disable view dragging. Default is YES.
 *
 *  @return A cardView instance
 */
+ (CXCardView *)showWithView:(UIView *)view draggable:(BOOL)draggable;

/**
 *  Show the cardView with view immediately at pending postion.
 *
 *  @param view      Your custom view.
 *  @param draggable Set No to disable view dragging. Default is YES.
 *
 *  @return A cardView instance
 */
+ (CXCardView *)showLateWithView:(UIView *)view draggable:(BOOL)draggable;

/**
 *  To dismiss the current cardView. If you want to dismiss the specific card view, please use the `dismiss` class mtehod.
 */
+ (void)dismissCurrent;

/**
 *  Init with content view where you show the information.
 *
 *  @param view Your custom view.
 *
 *  @return A cardView instance
 */
- (id)initWithView:(UIView *)view;

/**
 *  To show this card at showing position.
 */
- (void)show;

/**
 *  To show this card at pending position.
 */
- (void)showLater;

/**
 *  To dismiss the cardView. Recommend to use.
 */
- (void)dismiss;

@end
