//
//  ViewController.m
//  Examples
//
//  Created by Chris Xu on 2014/4/30.
//  Copyright (c) 2014年 CX. All rights reserved.
//

#import "ViewController.h"
#import "DemoContentView.h"
#import "CXCardView.h"

@interface ViewController ()
{
    DemoContentView *_firstContentView;
    DemoContentView *_secondContentView;
}

- (void)showDefaultContentView;
- (void)showLaterDefaultContentView;
- (void)showContetnViewWithTextField;

- (void)demoOneButtonPressed:(UIButton *)button;
- (void)demoTwoButtonPressed:(UIButton *)button;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    CGSize screenSize = [UIScreen mainScreen].bounds.size;
    
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(20, screenSize.height * 0.75, 300, 100);
    label.numberOfLines = 0.;
    label.textAlignment = NSTextAlignmentLeft;
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Avenir-Roman" size:14.];
    label.text = @"You could create any view as the content view of your card.";
    [self.view addSubview:label];
    
    UIButton *demoButtonOne = [UIButton buttonWithType:UIButtonTypeCustom];
    demoButtonOne.frame = CGRectMake(10, screenSize.height * 0.9, 130, 44);
    demoButtonOne.backgroundColor = [UIColor clearColor];
    [demoButtonOne addTarget:self action:@selector(demoOneButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [demoButtonOne setTitle:@"Show later" forState:UIControlStateNormal];
    [demoButtonOne setTitleColor:[UIColor colorWithRed:0.431 green:0.706 blue:0.992 alpha:1.000] forState:UIControlStateHighlighted];
    [self.view addSubview:demoButtonOne];
    
    UIButton *demoButtonTwo = [UIButton buttonWithType:UIButtonTypeCustom];
    demoButtonTwo.frame = CGRectMake(screenSize.width - 140, screenSize.height * 0.9, 130, 44);
    demoButtonTwo.backgroundColor = [UIColor clearColor];
    [demoButtonTwo addTarget:self action:@selector(demoTwoButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    [demoButtonTwo setTitle:@"Show textField" forState:UIControlStateNormal];
    [demoButtonTwo setTitleColor:[UIColor colorWithRed:0.431 green:0.706 blue:0.992 alpha:1.000] forState:UIControlStateHighlighted];
    [self.view addSubview:demoButtonTwo];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self showDefaultContentView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark -
- (void)showDefaultContentView
{
    if (!_firstContentView) {
        _firstContentView = [DemoContentView defaultView];
        
        UILabel *descriptionLabel = [[UILabel alloc] init];
        descriptionLabel.frame = CGRectMake(20, 8, 260, 100);
        descriptionLabel.numberOfLines = 0.;
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        descriptionLabel.backgroundColor = [UIColor clearColor];
        descriptionLabel.textColor = [UIColor blackColor];
        descriptionLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:14.];
        descriptionLabel.text = @"This is a draggable view. You could drag it down to dismiss";
        [_firstContentView addSubview:descriptionLabel];
        
        [_firstContentView setDismissHandler:^(DemoContentView *view) {
            // to dismiss current cardView. Also you could call the `dismiss` method.
            [CXCardView dismissCurrent];
        }];
    }
    
    [CXCardView showWithView:_firstContentView draggable:YES];
}

- (void)showLaterDefaultContentView
{
//    [self showDefaultContentView];
    
    double delayInSeconds = 0.5;
    dispatch_time_t popTime1 = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime1, dispatch_get_main_queue(), ^(void){
        for (NSInteger i = 0; i < 2; i++) {
            DemoContentView *otherView = [DemoContentView defaultView];
            
            UILabel *descriptionLabel = [[UILabel alloc] init];
            descriptionLabel.frame = CGRectMake(20, 8, 260, 100);
            descriptionLabel.numberOfLines = 0.;
            descriptionLabel.textAlignment = NSTextAlignmentLeft;
            descriptionLabel.backgroundColor = [UIColor clearColor];
            descriptionLabel.textColor = [UIColor blackColor];
            descriptionLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:14.];
            descriptionLabel.text = @"You could use this as a low priority content to show without block user";
            [otherView addSubview:descriptionLabel];
            
            CXCardView *cardView = [[CXCardView alloc] initWithView:otherView];
            
            [otherView setDismissHandler:^(DemoContentView *view) {
                [cardView dismiss];
            }];
            
            [cardView showLater];
        }
    });
    
    double NewDelayInSeconds = 1.5;
    dispatch_time_t popTime2 = dispatch_time(DISPATCH_TIME_NOW, NewDelayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime2, dispatch_get_main_queue(), ^(void){
        
        DemoContentView *otherView = [DemoContentView defaultView];
        
        UILabel *descriptionLabel = [[UILabel alloc] init];
        descriptionLabel.frame = CGRectMake(20, 8, 260, 100);
        descriptionLabel.numberOfLines = 0.;
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        descriptionLabel.backgroundColor = [UIColor clearColor];
        descriptionLabel.textColor = [UIColor blackColor];
        descriptionLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:14.];
        descriptionLabel.text = @"This is a high priority content to show.";
        [otherView addSubview:descriptionLabel];
        
        CXCardView *cardView = [[CXCardView alloc] initWithView:otherView];
        
        [otherView setDismissHandler:^(DemoContentView *view) {
            [cardView dismiss];
        }];
        
        [cardView show];
        
    });
}

- (void)showContetnViewWithTextField
{
    if (!_secondContentView) {
        
        _secondContentView = [DemoContentView defaultView];
        
        UILabel *descriptionLabel = [[UILabel alloc] init];
        descriptionLabel.frame = CGRectMake(20, 8, 260, 60);
        descriptionLabel.numberOfLines = 0.;
        descriptionLabel.textAlignment = NSTextAlignmentLeft;
        descriptionLabel.backgroundColor = [UIColor clearColor];
        descriptionLabel.textColor = [UIColor blackColor];
        descriptionLabel.font = [UIFont fontWithName:@"Avenir-Roman" size:14.];
        descriptionLabel.text = @"This is a demo to present the change when the keyboard will show.";
        [_secondContentView addSubview:descriptionLabel];
        
        UITextField *textField = [[UITextField alloc] init];
        textField.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.4];
        textField.frame = CGRectMake(20, 64, 260, 30);
        textField.placeholder = @"Type here!";
        [_secondContentView addSubview:textField];
    }
    
    CXCardView *cardView = [[CXCardView alloc] initWithView:_secondContentView];
    
    [_secondContentView setDismissHandler:^(DemoContentView *view) {
        [cardView dismiss];
    }];
    
    [cardView show];
}
//Actions
- (void)demoOneButtonPressed:(UIButton *)button
{
    [self showLaterDefaultContentView];
}

- (void)demoTwoButtonPressed:(UIButton *)button
{
    [self showContetnViewWithTextField];
}
@end
