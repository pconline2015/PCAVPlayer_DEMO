//
//  ViewController.m
//  PCAVPlayer_DEMO
//
//  Created by PCOnline2015 on 16/8/4.
//  Copyright © 2016年 PCOnline. All rights reserved.
//

#import "ViewController.h"
#import "PCAVPlayer.h"

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)

@interface ViewController ()

@property (nonatomic,strong)UIView *avPlayerView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self setupAVPlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


-(void)setupAVPlayer{
    
    self.avPlayerView=[UIView new];
    self.avPlayerView.frame=CGRectMake(0, 100, SCREEN_WIDTH, SCREEN_WIDTH*395/702);
    [self.view addSubview:self.avPlayerView];
    
    NSString *videoUrl=@"http://auto.pcvideo.com.cn/pcauto/vpcauto/2016/05/19/1463629516997-vpcauto-74880-1.mp4";
    
    UIImage *thumbImage=[UIImage imageNamed:@"default.png"];
    
    [[PCAVPlayer instance] setVideoUrlStr: videoUrl];
    
    [PCAVPlayer instance].thumbImageView.image=thumbImage;
    
    [self.avPlayerView addSubview:[PCAVPlayer instance]];
    
    [PCAVPlayer instance].frame=  CGRectMake(0, 0, self.avPlayerView.frame.size.width, self.avPlayerView.frame.size.height);
    
    __weak typeof(self) wself=self;
    [PCAVPlayer instance].zoomInlock=^(){
        
        [PCAVPlayer instance].frame=  CGRectMake(0, 0, wself.avPlayerView.frame.size.width, wself.avPlayerView.frame.size.height);
        [wself.avPlayerView addSubview:[PCAVPlayer instance]];
        
    };
}


-(void)stopPlayer{
    
    [[PCAVPlayer instance] stopPlayer];
}


-(void)pausePlayer{
    
    [[PCAVPlayer instance] pausePlayer];
}


@end
