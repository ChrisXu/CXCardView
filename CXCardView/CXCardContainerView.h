//
//  CardContainerView.h
//  CardViewDemo
//
//  Created by Chris Xu on 2014/4/16.
//  Copyright (c) 2014年 ChrisXu. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef struct {
    CGFloat rx;
    CGFloat ry;
} SKActiveArea;

SKActiveArea SKActiveAreaMake(CGSize size);

@protocol CardViewDelegate;

@interface CXCardContainerView : UIView

@property (nonatomic, weak) id<CardViewDelegate> delegate;
@property (nonatomic, assign) BOOL draggable;
@property (nonatomic, assign) CGFloat topTriggerOffset; //default is CGRectGetHeight([UIScreen mainScreen].bounds)/4*1
@property (nonatomic, assign) CGFloat bottomTriggerOffset; //default is CGRectGetHeight([UIScreen mainScreen].bounds)/4*3

@end

@protocol CardViewDelegate <NSObject>

@optional
- (void)cardView:(CXCardContainerView *)card touchesBeganAtPoint:(CGPoint)startpoint;
- (void)cardView:(CXCardContainerView *)card touchesMovedWithOffset:(CGFloat)offset;
- (void)cardView:(CXCardContainerView *)card willDragToBottomWithProgress:(CGFloat)progress;
- (void)cardViewDidDragToTop:(CXCardContainerView *)card;
- (void)cardViewDidDragToBottom:(CXCardContainerView *)card;
- (void)cardViewDidCancelDragging:(CXCardContainerView *)card;

- (void)cardView:(CXCardContainerView *)card willDragToTopWithProgress:(CGFloat)progress;
- (CGAffineTransform)transformForDragToTop:(CXCardContainerView *)card;
- (CGAffineTransform)transformForDragToBottom:(CXCardContainerView *)card;
@end