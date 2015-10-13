//
//  CardContainerView.m
//  CardViewDemo
//
//  Created by Chris Xu on 2014/4/16.
//  Copyright (c) 2014年 ChrisXu. All rights reserved.
//

#import "CXCardContainerView.h"

@interface CXCardContainerView ()
{
    CGPoint _startPoint;
    CGPoint _startCenter;
    CGPoint _shift;
    
    BOOL _isDraggingToTop;
    BOOL _isDraggingToBottom;
}

@end

@implementation CXCardContainerView
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        _draggable = YES;
        _topTriggerOffset = CGRectGetHeight([UIScreen mainScreen].bounds)/4*1;
        _bottomTriggerOffset = CGRectGetHeight([UIScreen mainScreen].bounds)/4*3;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        _draggable = YES;
        _topTriggerOffset = CGRectGetHeight([UIScreen mainScreen].bounds)/4*1;
        _bottomTriggerOffset = CGRectGetHeight([UIScreen mainScreen].bounds)/4*3;
    }
    return self;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    _isDraggingToBottom = NO;
    _isDraggingToBottom  = NO;
    
    if (_draggable) {
        UITouch *touch = [[touches allObjects] firstObject];
        _startPoint = [touch locationInView:self];
        _startCenter = self.center;
        _shift = CGPointZero;
        
        if (_delegate && [_delegate respondsToSelector:@selector(cardView:touchesBeganAtPoint:)]) {
            [_delegate cardView:self touchesBeganAtPoint:_startPoint];
        }
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_draggable) {
        if (touches.count == 1)
        {
            UITouch *touch = [[touches allObjects] firstObject];
            CGPoint center = self.center;
            CGPoint currentLoc = [touch locationInView:self];
            CGPoint prevLoc = [touch previousLocationInView:self];
            
            CGFloat x_offset = (currentLoc.x - prevLoc.x);
            CGFloat y_offset = (currentLoc.y - prevLoc.y);
            
            _shift.y += y_offset;
            _shift.x += x_offset;
            
            center.y += y_offset;
            
//            NSLog(@"%f,%f",y_offset,_shift.y);
            self.center = center;
            CGFloat halfPi = (_startPoint.x > CGRectGetWidth([UIScreen mainScreen].bounds)/2) ? 180. : -180;
            self.transform = CGAffineTransformMakeRotation(0.25f * _shift.y * M_PI / halfPi/4);
            
            CGFloat progressOfDraggingToTop = 1 - (_topTriggerOffset - center.y)/(_topTriggerOffset - _startCenter.y);
            _isDraggingToTop = (progressOfDraggingToTop > 0);
            
            if (_isDraggingToTop) {
                if (_delegate && [_delegate respondsToSelector:@selector(cardView:willDragToTopWithProgress:)]) {
                    [_delegate cardView:self willDragToTopWithProgress:MIN(progressOfDraggingToTop, 1.)];
                }
            }
            
            CGFloat progressOfDraggingToBottom = 1 - (center.y - _bottomTriggerOffset)/(_startCenter.y - _bottomTriggerOffset);
            _isDraggingToBottom = (progressOfDraggingToBottom > 0);
            
            if (_isDraggingToBottom) {
                if (_delegate && [_delegate respondsToSelector:@selector(cardView:willDragToBottomWithProgress:)]) {
                    [_delegate cardView:self willDragToBottomWithProgress:MIN(progressOfDraggingToBottom, 1.)];
                }
            }
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_draggable) {
        if (_isDraggingToTop && _delegate && [_delegate respondsToSelector:@selector(cardViewDidDragToTop:)]) {
            BOOL dragToTop = (self.center.y < _topTriggerOffset);
            
            if (dragToTop) {
                CGFloat offset = CGRectGetHeight(self.frame);
                CGPoint center = self.center;
                center.y += offset;
                _shift.y += offset;
                CGFloat halfPi = (_startPoint.x > CGRectGetWidth([UIScreen mainScreen].bounds)/2) ? 180. : -180;
                
                [UIView animateKeyframesWithDuration:0.3 delay:0. options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
                    self.center = center;
                    self.transform = CGAffineTransformMakeRotation(0.25f * _shift.y * M_PI / halfPi/2);
                } completion:^(BOOL finished) {
                    [_delegate cardViewDidDragToTop:self];
                }];
                
                return;
            }
        }
        
        
        if (_isDraggingToBottom && _delegate && [_delegate respondsToSelector:@selector(cardViewDidDragToBottom:)]) {
            BOOL dragToBottom = (self.center.y > _bottomTriggerOffset);
            
            if (dragToBottom) {
                CGFloat offset = CGRectGetHeight(self.frame);
                CGPoint center = self.center;
                center.y += offset;
                _shift.y += offset;
                CGFloat halfPi = (_startPoint.x > CGRectGetWidth([UIScreen mainScreen].bounds)/2) ? 180. : -180;
                
                [UIView animateKeyframesWithDuration:0.3 delay:0. options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
                    self.center = center;
                    self.transform = CGAffineTransformMakeRotation(0.25f * _shift.y * M_PI / halfPi/2);
                } completion:^(BOOL finished) {
                    [_delegate cardViewDidDragToBottom:self];
                }];
                
                return;
            }
        }
        
        if (_delegate && [_delegate respondsToSelector:@selector(cardViewDidCancelDragging:)]) {
            [_delegate cardViewDidCancelDragging:self];
        }
        
        CGFloat duration = 0.3;
        
        [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseInOut animations:^{
            
            self.center = _startCenter;
            self.transform = CGAffineTransformMakeRotation(0);
            
        } completion:^(BOOL finished) {
            
        }];
    }
}

-(void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self touchesEnded:touches withEvent:event];
}

#pragma mark - Private Method
@end
