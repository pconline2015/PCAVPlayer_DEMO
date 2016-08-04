//
//  PCAVPlayerViewController.m
//  PCAVPlayer_DEMO
//
//  Created by PCOnline2015 on 16/8/4.
//  Copyright © 2016年 PCOnline. All rights reserved.
//

#import "PCAVPlayerViewController.h"

@interface PCAVPlayerViewController ()

@end

@implementation PCAVPlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)init
{
    if ((self = [super init]))
    {
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(zoomMin:) name:@"setZoomMin" object:nil];
    }
    
    return self;
}

- (BOOL) shouldAutorotate
{
    return YES;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationLandscapeRight;
}

-(void)zoomMin:(NSNotification *)notification{
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
}


@end
