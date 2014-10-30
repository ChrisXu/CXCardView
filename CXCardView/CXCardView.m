//
//  CXCardView.m
//  CardViewDemo
//
//  Created by Chris Xu on 2014/4/16.
//  Copyright (c) 2014年 ChrisXu. All rights reserved.
//

#import "CXCardView.h"
#import "CXCardContainerView.h"

@class CXCardBackgroundWindow;

const UIWindowLevel UIWindowLevelCXCardView = 1998.0; //UIWindowLevelAlert is 2000
const UIWindowLevel UIWindowLevelCXCardViewBackground = 1997.0;

const CGFloat kDefaultPendingTopOffset = -20.;
const CGFloat kDefaultPendingDegree = M_PI / 180/4;

static NSMutableArray *__cx_pending_cradview_queue;
static BOOL __cx_cardview_animating;
static CXCardBackgroundWindow *__cx_cardview_background_window;
static UIWindow *__cx_cardview_original_window;
static CXCardView *__cx_cardview_current_view;

@interface CXCardView ()
<CardViewDelegate>
{
    CGRect _originFrame;
    CGRect _keyboardBeginFrame;
    CGRect _keyboardEndFrame;
    BOOL _shouldSkipTransitionToPendding;
    dispatch_semaphore_t _sem;
}
@property (nonatomic, strong) UIWindow *oldKeyWindow;
@property (nonatomic, strong) UIWindow *cardViewWindow;
@property (nonatomic, assign, getter = isVisible) BOOL visible;
@property (nonatomic, assign, getter = isLayoutDirty) BOOL layoutDirty;
@property (nonatomic, assign) BOOL isAtPending;
@property (nonatomic, assign) BOOL isAnimatingToCenter;
@property (nonatomic, assign) BOOL isAnimatingToBottom;
@property (nonatomic, assign) BOOL isAnimatingToPending;
@property (nonatomic, assign) CGPoint pendingCenter;
@property (nonatomic, assign) CGPoint showingCenter;

+ (NSMutableArray *)sharedQueue;
+ (CXCardView *)currentCardView;
+ (CXCardView *)nextCardView;
+ (void)setCurrentCardView:(CXCardView *)cardView;
+ (BOOL)isAnimating;
+ (void)setAnimating:(BOOL)animating;
+ (UIWindow *)originalWindow;
+ (void)setOriginalWindow:(UIWindow *)window;

+ (void)showBackground;
+ (void)hideBackground;

- (void)initDefault;
- (void)setup;
- (void)tearDown;
- (void)validateLayout;
- (void)invalidateLayout;

- (BOOL)isCardViewExist;

- (void)moveToPending;
- (void)dismissWithCleanup:(BOOL)cleanup;

- (void)transitionToCenterCompletion:(void(^)(void))completion;
- (void)transitionToBottomCompletion:(void(^)(void))completion;
- (void)transitionToPendingCompletion:(void(^)(void))completion;
// Notification
- (void)keyboardWillShow:(NSNotification *)notification;
- (void)keyboardWillHide:(NSNotification *)notification;
@end

@interface CXCardBackgroundWindow : UIWindow

- (void)actionForTappedOnBackground:(UITapGestureRecognizer *)tap;

@end

@interface CXCardViewController : UIViewController

@property (nonatomic, strong) CXCardView *cardView;
@property (nonatomic, assign) BOOL rootViewControllerPrefersStatusBarHidden;

@end

@implementation CXCardView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)setDraggable:(BOOL)draggable
{
    if (_draggable == draggable) {
        return;
    }
    _draggable = draggable;
    self.containerView.draggable = _draggable;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
#pragma mark - Public Method
- (id)initWithView:(UIView *)view
{
    self = [super init];
    if (self) {
        _contentView = view;
        [self initDefault];
    }
    return self;
}

- (void)show
{
    if ([self isCardViewExist]) {
        return;
    }
    
    if (!self.oldKeyWindow) {
        self.oldKeyWindow = [[UIApplication sharedApplication] keyWindow];
    }
    
    if ([CXCardView sharedQueue].count == 0) {
        [CXCardView setOriginalWindow:[[UIApplication sharedApplication] keyWindow]];
    }
    
    if (![[CXCardView sharedQueue] containsObject:self]) {
        [[CXCardView sharedQueue] addObject:self];
    }
    
    if ([CXCardView isAnimating]) {
        return; // wait for next turn
    }
    
    if (self.isVisible) {
        return;
    }
    
    CXCardView *currentCardView = [CXCardView currentCardView];
    if (currentCardView.isVisible && !currentCardView.isAnimatingToBottom) {
        // new card is coming
        CXCardView *cardView = [CXCardView currentCardView];
        [cardView moveToPending];
        return;
    }
    
    self.visible = YES;
    
    [CXCardView setAnimating:YES];
    [CXCardView setCurrentCardView:self];
    [CXCardView showBackground];
    
    CXCardViewController *viewController = [[CXCardViewController alloc] initWithNibName:nil bundle:nil];
    viewController.cardView = self;
    viewController.rootViewControllerPrefersStatusBarHidden = self.oldKeyWindow.rootViewController.prefersStatusBarHidden;
    
    if (!self.cardViewWindow) {
        UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        window.opaque = NO;
        window.windowLevel = UIWindowLevelCXCardView;
        window.rootViewController = viewController;
        self.cardViewWindow = window;
    }
    
    if (![self.cardViewWindow isKeyWindow]) {
        [self.cardViewWindow makeKeyAndVisible];
    }
    
    if (CGPointEqualToPoint(_showingCenter, CGPointZero) && !self.isAtPending) {
        _showingCenter = _containerView.center;
    }
    
    if (!_isAnimatingToPending) {
        [self transitionToCenterCompletion:^{
            if (self.didShowHandler) {
                self.didShowHandler(self);
            }
            
            [CXCardView setAnimating:NO];
            
            NSInteger index = [[CXCardView sharedQueue] indexOfObject:self];
            if (index < [CXCardView sharedQueue].count - 1) {
                [self moveToPending]; // dismiss to show next card view
            }
        }];
    }
    else {
        _shouldSkipTransitionToPendding = YES;
    }
}

- (void)showLater
{
    if ([self isCardViewExist]) {
        return;
    }
    
//    if ([CXCardView isAnimating]) {
//        return; // wait for next turn
//    }
    
    if (self.isVisible) {
        return;
    }

    
    if (![[CXCardView sharedQueue] containsObject:self]) {
        if ([CXCardView sharedQueue].count > 0) {
            [[CXCardView sharedQueue] insertObject:self atIndex:0];
            
            CXCardView *lastCardView = [CXCardView sharedQueue][1];
            
            CXCardViewController *viewController = [[CXCardViewController alloc] initWithNibName:nil bundle:nil];
            viewController.cardView = self;
            viewController.rootViewControllerPrefersStatusBarHidden = self.oldKeyWindow.rootViewController.prefersStatusBarHidden;
            
            self.alpha = 0.;
            
            if (!self.cardViewWindow) {
                UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
                window.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                window.opaque = NO;
                window.windowLevel = UIWindowLevelCXCardView;
                window.rootViewController = viewController;
                self.cardViewWindow = window;
            }
            [self.cardViewWindow makeKeyAndVisible];
            
            if (!self.oldKeyWindow) {
                self.oldKeyWindow = lastCardView.oldKeyWindow;
                lastCardView.oldKeyWindow = self.cardViewWindow;
                [[CXCardView currentCardView].cardViewWindow makeKeyAndVisible];
            }
            
            if (CGPointEqualToPoint(_showingCenter, CGPointZero) && !self.isAtPending) {
                _showingCenter = _containerView.center;
            }
            
            CGPoint center = _showingCenter;
            CGFloat offsetMidY = CGRectGetMidY(_originFrame);
            CGFloat offsetMaxY = CGRectGetMaxY(_originFrame);
            CGPoint interruptCenter = center;
            interruptCenter.y -= (offsetMidY - kDefaultPendingTopOffset);
            _containerView.center = interruptCenter;
            
            CGPoint pendingCenter = center;
            pendingCenter.y -= (offsetMaxY - kDefaultPendingTopOffset);
            CGFloat degree = 0.25f * (offsetMaxY - kDefaultPendingTopOffset) * kDefaultPendingDegree;
            _containerView.transform = CGAffineTransformMakeRotation(degree);
            _containerView.center = pendingCenter;
            
            _isAnimatingToPending = YES;
            [UIView animateWithDuration:0.3 animations:^{
                self.alpha = 1.;
                _containerView.center = interruptCenter;
                _containerView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
                
                if (_shouldSkipTransitionToPendding) {
                    _shouldSkipTransitionToPendding = NO;
                    _isAnimatingToPending = NO;
                    [self transitionToCenterCompletion:^{
                        if (self.didShowHandler) {
                            self.didShowHandler(self);
                        }
                        
                        [CXCardView setAnimating:NO];
                        
                        NSInteger index = [[CXCardView sharedQueue] indexOfObject:self];
                        if (index < [CXCardView sharedQueue].count - 1) {
                            [self moveToPending]; // dismiss to show next card view
                        }
                    }];
                }
                else {
                    [self transitionToPendingCompletion:^{
                        if (_shouldSkipTransitionToPendding) {
                            [self transitionToCenterCompletion:^{
                                if (self.didShowHandler) {
                                    self.didShowHandler(self);
                                }
                                
                                [CXCardView setAnimating:NO];
                                
                                NSInteger index = [[CXCardView sharedQueue] indexOfObject:self];
                                if (index < [CXCardView sharedQueue].count - 1) {
                                    [self moveToPending]; // dismiss to show next card view
                                }
                            }];
                        }
                        else {
                            [UIView animateWithDuration:0.3 animations:^{
                                _containerView.alpha = 0.7;
                            }completion:^(BOOL finished) {
                                _isAnimatingToPending = NO;
                            }];
                        }
                    }];
                }
            }];
        }
        else {
            [self show];
            return;
            
        }
    }
}

- (void)dismiss
{
    [self dismissWithCleanup:YES];
}

+ (CXCardView *)showWithView:(UIView *)view draggable:(BOOL)draggable
{
    CXCardView *cardView = [[CXCardView alloc] initWithView:view];
    cardView.draggable = draggable;
    [cardView show];
    
    return cardView;
}

+ (CXCardView *)showLateWithView:(UIView *)view draggable:(BOOL)draggable
{
    CXCardView *cardView = [[CXCardView alloc] initWithView:view];
    cardView.draggable = draggable;
    [cardView showLater];
    
    return cardView;
}

+ (void)dismissCurrent
{
    [[CXCardView currentCardView] dismiss];
}

#pragma mark - Private Method
+ (NSMutableArray *)sharedQueue
{
    if (!__cx_pending_cradview_queue) {
        __cx_pending_cradview_queue = [NSMutableArray array];
    }
    return __cx_pending_cradview_queue;
}

+ (CXCardView *)currentCardView
{
    return __cx_cardview_current_view;
}

+ (CXCardView *)nextCardView
{
    CXCardView *nextCardView = nil;
    
    NSInteger index = [[CXCardView sharedQueue] indexOfObject:[CXCardView currentCardView]];
    if (index != NSNotFound && index < [CXCardView sharedQueue].count - 1) {
        nextCardView = [CXCardView sharedQueue][index + 1];
    }
    
    return nextCardView;
}

+ (void)setCurrentCardView:(CXCardView *)cardView
{
    __cx_cardview_current_view = cardView;
}

+ (BOOL)isAnimating
{
    return __cx_cardview_animating;
}

+ (void)setAnimating:(BOOL)animating
{
    __cx_cardview_animating = animating;
}

+ (UIWindow *)originalWindow
{
    return __cx_cardview_original_window;
}

+ (void)setOriginalWindow:(UIWindow *)window
{
    __cx_cardview_original_window = window;
}

+ (void)showBackground
{
    if (!__cx_cardview_background_window) {
        __cx_cardview_background_window = [[CXCardBackgroundWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
        __cx_cardview_background_window.alpha = 0.;
    }
    
    [__cx_cardview_background_window.layer removeAllAnimations];
    if (__cx_cardview_background_window.alpha == 0.) {
        [__cx_cardview_background_window makeKeyAndVisible];
        __cx_cardview_background_window.alpha = 0;
        [UIView animateWithDuration:0.3
                         animations:^{
                             __cx_cardview_background_window.alpha = 1;
                         }];
    }
}

+ (void)hideBackground
{
    [__cx_cardview_background_window.layer removeAllAnimations];
    [UIView animateWithDuration:0.35
                     animations:^{
                         __cx_cardview_background_window.alpha = 0;
                     }
                     completion:^(BOOL finished) {
                         if (finished) {
                             [__cx_cardview_background_window removeFromSuperview];
                             __cx_cardview_background_window = nil;
                         }
                     }];
}

- (void)initDefault
{
    self.draggable = YES;
    _moveToPedingDuration = 0.45;
    _moveToCenterDuration = 0.45;
    _moveToBottomDuration = 0.3;
}

-(CGRect)currentScreenBoundsDependOnOrientation{
    CGRect screenBounds = [UIScreen mainScreen].bounds ;
    CGFloat width = CGRectGetWidth(screenBounds)  ;
    CGFloat height = CGRectGetHeight(screenBounds) ;
    UIInterfaceOrientation interfaceOrientation = [UIApplication sharedApplication].statusBarOrientation;
    
    if(UIInterfaceOrientationIsPortrait(interfaceOrientation)){
        screenBounds.size = CGSizeMake(width, height);
    }else if(UIInterfaceOrientationIsLandscape(interfaceOrientation)){
        screenBounds.size = CGSizeMake(height, width);
    }
    return screenBounds ;
}

- (void)setup
{
    _contentView.frame = ({
        CGRect frame = _contentView.frame;
        frame.origin = CGPointZero;
        frame;
    });
    
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    CGRect frame = _contentView.frame;
    frame.origin.y = (CGRectGetHeight([self currentScreenBoundsDependOnOrientation]) - CGRectGetHeight(_contentView.frame))/2;
    float width=CGRectGetWidth([self currentScreenBoundsDependOnOrientation]);
    frame.origin.x = MIN(width, (width - CGRectGetWidth(frame))/2);

    _containerView = [[CXCardContainerView alloc] initWithFrame:frame];
    _containerView.draggable = _draggable;
    _containerView.delegate = self;
    [self addSubview:self.containerView];
    
    _containerView.backgroundColor = [UIColor clearColor];
//    _containerView.clipsToBounds = YES;
//    _containerView.layer.shadowOffset = CGSizeZero;
//    _containerView.layer.shadowOpacity = 0.5;
    
    [_containerView addSubview:_contentView];
    
    _originFrame = frame;
    _showingCenter = _containerView.center;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)tearDown
{
    [self.containerView removeFromSuperview];
    self.containerView.delegate = nil;
    _contentView = nil;
    
    self.cardViewWindow.hidden = YES;
    self.cardViewWindow = nil;
    self.layoutDirty = NO;
}

- (void)validateLayout
{
    if (!self.isLayoutDirty) {
        return;
    }
    self.layoutDirty = NO;
    
//    CGFloat height = [self preferredHeight];
//    CGFloat left = (self.bounds.size.width - self.containerWidth) * 0.5;
//    CGFloat top = (self.bounds.size.height - height) * 0.5;
//    _containerView.transform = CGAffineTransformIdentity;
//    _blurView.transform = CGAffineTransformIdentity;
//    if (_updateAnimated) {
//        _updateAnimated = NO;
//        [UIView animateWithDuration:0.3 animations:^{
//            _containerView.frame = CGRectMake(left, top, self.containerWidth, height);
//            _blurView.frame = CGRectMake(left, top, self.containerWidth, height);
//        }];
//    }
//    else {
//        _containerView.frame = CGRectMake(left, top, self.containerWidth, height);
//        _blurView.frame = CGRectMake(left, top, self.containerWidth, height);
//    }
//    _containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_containerView.bounds cornerRadius:_containerView.layer.cornerRadius].CGPath;
}

- (void)invalidateLayout
{
    self.layoutDirty = YES;
    [self setNeedsLayout];
}

- (BOOL)isCardViewExist
{
    for (CXCardView *cardView in [CXCardView sharedQueue]) {
        if (_contentView == cardView.contentView && [CXCardView currentCardView].isVisible) {
            return YES;
        }
    }
    
    return NO;
}

- (void)moveToPending
{
    void (^moveToPendingComplete)(void) = ^{
        
        [UIView animateWithDuration:0.3 animations:^{
            _containerView.alpha = 0.7;
        }];
        
        self.visible = NO;
        
        CXCardView *nextCardView = [CXCardView nextCardView];
        
        [CXCardView setCurrentCardView:nil];
        
        [CXCardView setAnimating:NO];
        
        if (nextCardView) {
            [nextCardView show];
        } else {
            // show last card view
            if ([CXCardView sharedQueue].count > 0) {
                CXCardView *cardView = [[CXCardView sharedQueue] lastObject];
                [cardView show];
            }
        }
        
    };
    
    [CXCardView setAnimating:YES];
    [self transitionToPendingCompletion:moveToPendingComplete];
    
}

- (void)dismissWithCleanup:(BOOL)cleanup
{
    BOOL isVisible = self.isVisible;
    
    if (isVisible) {
        if (self.willDismissHandler) {
            self.willDismissHandler(self);
        }
    }
    
    void (^dismissComplete)(void) = ^{
        self.visible = NO;
        [self tearDown];
        
        if (self == [CXCardView currentCardView]) {
            [CXCardView setCurrentCardView:nil];
        }
        
        if (cleanup) {
            if ([[CXCardView sharedQueue] indexOfObject:self] == 0 && [CXCardView sharedQueue].count >= 2) {
                CXCardView *secondCardView = [CXCardView sharedQueue][1];
                secondCardView.oldKeyWindow = [CXCardView originalWindow];
            }
            
            [[CXCardView sharedQueue] removeObject:self];
            
        }
        
        [CXCardView setAnimating:NO];
        
        if (isVisible) {
            if (self.didDismissHandler) {
                self.didDismissHandler(self);
            }
        }
        
        // show last card view
        if ([CXCardView sharedQueue].count > 0) {
            CXCardView *cardView = [[CXCardView sharedQueue] lastObject];
            [cardView show];
        }
        else {
            UIWindow *nextKeyWindow = [CXCardView originalWindow];
            NSArray *windows = [UIApplication sharedApplication].windows;
            NSInteger index = 0;
            
            if ([windows containsObject:nextKeyWindow]) {
                index = [windows indexOfObject:nextKeyWindow];
            }
            
            for (NSInteger i = index; i >= 0 ; i--) {
                UIWindow *window = [windows objectAtIndex:i];
                if (window.tag != kCXCardViewRemoveWindowIdentifier) {
                    nextKeyWindow = window;
                    break;
                }
            }
            
            [nextKeyWindow makeKeyAndVisible];
            
            if (nextKeyWindow == [CXCardView originalWindow]) {
                [CXCardView originalWindow].hidden = NO;
            }
        }
    };
    
    if (isVisible) {
        [self transitionToBottomCompletion:dismissComplete];
        
        if ([CXCardView sharedQueue].count == 1) {
            [CXCardView hideBackground];
        }
    }
    else {
        dismissComplete();
        
        if ([CXCardView sharedQueue].count == 0) {
            [CXCardView hideBackground];
        }
    }
}

- (void)transitionToCenterCompletion:(void(^)(void))completion
{
    CGPoint center = _showingCenter;
    CGFloat offset = CGRectGetMidY(_originFrame);
    CGPoint outCenter = center;
    outCenter.y -= offset*1.5;
    
    if (!self.isAtPending) {
        _containerView.center = outCenter;
        _containerView.transform = CGAffineTransformMakeRotation(0.25f * offset * kDefaultPendingDegree);
    }
    _isAnimatingToCenter = YES;
    [UIView animateKeyframesWithDuration:_moveToCenterDuration delay:0. options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
        _containerView.transform = CGAffineTransformIdentity;
        _containerView.center = _showingCenter;
        _containerView.alpha = 1.;
    } completion:^(BOOL finished) {
        _isAnimatingToCenter = NO;
        if (completion) {
            completion();
        }
    }];
}

- (void)transitionToBottomCompletion:(void(^)(void))completion
{
    CGPoint center = _containerView.center;
    CGFloat offset = CGRectGetHeight([UIScreen mainScreen].bounds) - CGRectGetMinY(_originFrame);
    center.y += offset*1.5;
    
    _isAnimatingToBottom = YES;
    [UIView animateKeyframesWithDuration:_moveToBottomDuration delay:0. options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
        self.center = center;
        self.transform = CGAffineTransformMakeRotation(0.25f * offset * M_PI / 180/4);
    } completion:^(BOOL finished) {
        _isAnimatingToBottom = NO;
        if (completion) {
            completion();
        }
    }];
}

- (void)transitionToPendingCompletion:(void(^)(void))completion
{
    CGPoint center = _showingCenter;
    CGFloat offset = CGRectGetMaxY(_originFrame);
    CGPoint pendingCenter = center;
    pendingCenter.y -= (offset - kDefaultPendingTopOffset);
    _pendingCenter = pendingCenter;
    CGFloat degree = 0.25f * (offset - kDefaultPendingTopOffset) * kDefaultPendingDegree;
    
    _isAnimatingToPending = YES;
    [UIView animateKeyframesWithDuration:_moveToPedingDuration delay:0. options:UIViewKeyframeAnimationOptionCalculationModeCubicPaced animations:^{
                         _containerView.transform = CGAffineTransformMakeRotation(degree);
                         _containerView.center = pendingCenter;
    }
    completion:^(BOOL finished) {
        _isAnimatingToPending = NO;
        _isAtPending = YES;
        if (completion) {
            completion();
        }
    }];
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    NSDictionary *userInfo = notification.userInfo;
    
    _keyboardBeginFrame = [userInfo[UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    _keyboardEndFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    if (CGRectIntersectsRect(_originFrame, _keyboardEndFrame) && !_isAtPending) {
        _containerView.draggable = NO;
        CGRect moveUpFrame = _originFrame;
        
        moveUpFrame = ({
            CGRect frame = moveUpFrame;
            frame.origin.y -= 100;
            frame;
        });
        
        [UIView animateWithDuration:0.45 animations:^{
            _containerView.frame = moveUpFrame;
        }];
    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    if (CGRectIntersectsRect(_originFrame, _keyboardEndFrame) && !_isAtPending) {
        _containerView.draggable = YES;
        [UIView animateWithDuration:0.45 animations:^{
            _containerView.frame = _originFrame;
        }];
    }
}
#pragma mark - CardViewDelegate
- (void)cardView:(CXCardContainerView *)card willDragToBottomWithProgress:(CGFloat)progress
{
    if ([CXCardView sharedQueue].count == 1) {
        __cx_cardview_background_window.alpha = (1 - progress);
    }
    
    NSInteger count = [CXCardView sharedQueue].count;
    if (count > 1) {
        CXCardView *cardView = [CXCardView sharedQueue][count - 2];
        CGPoint pendingCenter = cardView.pendingCenter;
        CGPoint showingCenter = cardView.showingCenter;
        CGPoint center = pendingCenter;
        CGFloat offset = showingCenter.y - pendingCenter.y;
        center.y += offset*progress;
        
        
        cardView.containerView.center = center;
        CGFloat degree = 0.25f * offset*(1 - progress) * kDefaultPendingDegree;

        cardView.containerView.alpha = 0.7 + 0.3*progress;
        cardView.containerView.transform = CGAffineTransformMakeRotation(degree);
    }
}

- (void)cardViewDidDragToBottom:(CXCardContainerView *)card
{
    [self dismissWithCleanup:YES];
}

- (void)cardViewDidCancelDragging:(CXCardContainerView *)card
{
    if (__cx_cardview_background_window.alpha != 1.) {
        [UIView animateWithDuration:0.3 animations:^{
            __cx_cardview_background_window.alpha = 1.;
        }];
    }
    
    NSInteger count = [CXCardView sharedQueue].count;
    if (count > 1) {
        CXCardView *cardView = [CXCardView sharedQueue][count - 2];
        [cardView transitionToPendingCompletion:nil];
    }
}
@end

@implementation CXCardBackgroundWindow

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        self.opaque = NO;
        self.windowLevel = UIWindowLevelCXCardViewBackground;
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(actionForTappedOnBackground:)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    [[UIColor colorWithWhite:0 alpha:0.5] set];
    CGContextFillRect(context, self.bounds);
}

- (void)actionForTappedOnBackground:(UITapGestureRecognizer *)tap
{
    
}

@end

@implementation CXCardViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

#pragma mark - View life cycle

- (void)loadView
{
    self.view = self.cardView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.cardView setup];
}

//- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
//{
////    [self.CardView resetTransition];
////    [self.CardView invalidateLayout];
//}

- (NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (BOOL)shouldAutorotate
{
    return YES;
}
- (BOOL)prefersStatusBarHidden
{
    return _rootViewControllerPrefersStatusBarHidden;
}
@end
