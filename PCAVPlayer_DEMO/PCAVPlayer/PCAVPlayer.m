//
//  PCAVPlayer.m
//  PCMClient4
//
//  Created by PCOnline2015 on 16/5/26.
//  Copyright © 2016年 太平洋网络. All rights reserved.
//

#import "PCAVPlayer.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "PCAVPlayerViewController.h"
#import "AppDelegate.h"
#import "Reachability.h"


#define BTN_SMALL_PLAY @"btn_player_play.png"
#define BTN_SMALL_PAUSE @"btn_player_pause.png"

#define BTN_ZOOM_MIN @"btn_zoom_min.png"
#define BTN_ZOOM_MAX @"btn_zoom_max.png"

#define BTN_RETRY @"btn_retry.png"
#define BTN_PLAYER_SLIDER @"btn_player_slider.png"

#define BTN_BIG_PLAY @"btn_player_big_play.png"




#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)

#define NETWORK_ERROR_NOWIFI 1
#define NETWORK_ERROR_NONETWORK 2

#define PCColor(r,g,b,a) ([UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a])


@interface PCAVPlayer()

@property (strong, nonatomic) AVPlayerLayer *avPlayerLayer;
@property (weak, nonatomic) IBOutlet UIView *screenView;
@property (weak, nonatomic) IBOutlet UIView *controllerView;
@property (weak, nonatomic) IBOutlet UISlider *playerSlider;
@property (weak, nonatomic) IBOutlet UIButton *zoomBtn;
@property (strong, nonatomic) AVPlayer *avPlayer;
@property (nonatomic,assign)BOOL isPlaying;
@property (nonatomic,strong)NSString *videoUrlStr;
@property (weak, nonatomic) IBOutlet UIButton *btnPlay;
@property (nonatomic,assign)BOOL currentStateZoomMax;
@property (nonatomic,strong) PCAVPlayerViewController *pcAVPlayerViewController;
@property (weak, nonatomic) IBOutlet UIProgressView *bufferProgress;
@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *playerActivity;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (nonatomic,strong) UIView *networkErrorView;
@property (weak, nonatomic) IBOutlet UIButton *retryBtn;
@property (nonatomic,strong) UIImage *imageview;
@property (nonatomic,assign) BOOL isNewViedio;
@property (nonatomic,strong) UILabel *errorLabel;
@property (nonatomic,strong)UIButton *errorButton;
@property (nonatomic,strong)UILabel *errorLabel2;



@end

@implementation PCAVPlayer


+ (PCAVPlayer *)instance//视频播放器单例
{
    static PCAVPlayer *_PCAVPlayer;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _PCAVPlayer = [[PCAVPlayer alloc] init];
    });

    return _PCAVPlayer;
}


-(id)init
{
    self  =  [super init];
    if (self !=nil){
        
         NSArray *nibView= [[NSBundle mainBundle]loadNibNamed:@"PCAVPlayer" owner:self options:nil];
        PCAVPlayer *view=[nibView objectAtIndex:0];
        self = view;
        [self addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil];
        [self setUI];
        [self setNetworkErrorView];
        [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(updateSliderTimer) userInfo:nil repeats:YES];
        self.avPlayerLayer = [[AVPlayerLayer alloc] init];
        self.avPlayer= [[AVPlayer alloc] init];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.avPlayer.currentItem];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackgroundNotification:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        
        self.isPlaying=NO;
    }
    return self;
}



-(void)setUI{
    [self.playerSlider setThumbImage:[UIImage imageNamed:BTN_PLAYER_SLIDER] forState:UIControlStateNormal];
    
    self.screenView.userInteractionEnabled = YES;
    UITapGestureRecognizer *tapGesture=[[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(screenTouch:)];
    [self addGestureRecognizer:tapGesture];
    tapGesture.delegate = self;
    
}



-(NSUInteger)supportedInterfaceOrientations{
    return UIInterfaceOrientationLandscapeLeft;
}





-(void)setVideoUrlStr:(NSString *)urlStr{
    
    
    if ([urlStr isEqualToString:self.currentUri]==NO){
      self.currentUri=urlStr;
    }else{
        return;
    }
   
    self.isNewViedio=YES;
    
    
    self.screenView.frame=self.frame;
    
    self.screenView.backgroundColor=[UIColor blackColor];
    
    self.avPlayerLayer.frame = CGRectMake(0, 0, self.screenView.frame.size.width, self.screenView.frame.size.height);
    
    [self.screenView bringSubviewToFront:self.controllerView];
    
    self.isPlaying=NO;
    
    
    
    self.currentStateZoomMax=NO;
    
    [self.playerActivity startAnimating];
    
    self.playerActivity.hidden=NO;
    
    
    [self.btnPlayBig setImage:[UIImage imageNamed:BTN_BIG_PLAY] forState:UIControlStateNormal];
    
    self.controllerView.hidden=YES;
    
    [self.screenView bringSubviewToFront: self.thumbImageView];
    
    self.thumbImageView.backgroundColor=[UIColor grayColor];

    self.thumbImageView.hidden=NO;
    
    self.playerActivity.hidden=YES;
    
    self.btnPlayBig.hidden=NO;
    
    [self.screenView bringSubviewToFront:self.btnPlayBig];
    
    
}

-(void)loadVideo:(NSString *)urlStr{
    
    
    NSURL *movieURL = [NSURL URLWithString:urlStr];
    

    
    AVPlayerItem *playerItemNew = [AVPlayerItem playerItemWithURL:movieURL];
    


    if (self.avPlayer.currentItem) {
        
        @try {
            [[self.avPlayer currentItem] removeObserver:self forKeyPath:@"status"];
            [[self.avPlayer currentItem] removeObserver:self forKeyPath:@"loadedTimeRanges"];
            [[self.avPlayer currentItem] removeObserver:self forKeyPath:@"playbackBufferEmpty"];
            [[self.avPlayer currentItem] removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
            [self.avPlayer  removeObserver:self forKeyPath:@"rate"];
            
        }
        @catch (NSException *exception) {
            NSLog(@"exception=%@",exception);
        }
        
        
        [self.avPlayer replaceCurrentItemWithPlayerItem:playerItemNew];
        
        
    }else{
        
        [self.avPlayer replaceCurrentItemWithPlayerItem:playerItemNew];
        
        self.avPlayerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
        
        [self.screenView.layer addSublayer:self.avPlayerLayer];
        
        self.avPlayerLayer.player=self.avPlayer;
        
        
    }
    
    
    [[self.avPlayer currentItem]addObserver:self
                                 forKeyPath:@"status"
                                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                    context:nil];
    
    [[self.avPlayer currentItem]addObserver:self
                                 forKeyPath:@"loadedTimeRanges"
                                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                    context:nil];
    
    [[self.avPlayer currentItem]addObserver:self
                                 forKeyPath:@"playbackBufferEmpty"
                                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                    context:nil];
    
    [[self.avPlayer currentItem]addObserver:self
                                 forKeyPath:@"playbackLikelyToKeepUp"
                                    options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                                    context:nil];
    
    
    [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionNew context:nil];
    
    
   
    
    
}


- (void)observeValueForKeyPath:(NSString*) path
                      ofObject:(id)object
                        change:(NSDictionary*)change
                       context:(void*)context
{
   
    if ([path isEqualToString:@"frame"]){
        
       
        [self performSelector:@selector(setavPlayerLayerFrame) withObject:nil afterDelay:0.1];
    
    }else if ([path isEqualToString:@"status"]){
        
        AVPlayerItemStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status)
        {
            case AVPlayerItemStatusUnknown:
            {
                NSLog(@"AVPlayerItemStatusUnknown");
                [_playerActivity stopAnimating];
                _playerActivity.hidden=YES;
            }
                break;
                
            case AVPlayerItemStatusReadyToPlay:
            {
                
                if (self.isNewViedio){
                    
                    [self.btnPlay setImage:[UIImage imageNamed:BTN_SMALL_PAUSE] forState:UIControlStateNormal];
                    [self.avPlayer play];
                    self.isPlaying=YES;
                    self.isNewViedio=NO;
                     self.thumbImageView.hidden=YES;
                    [UIApplication sharedApplication].idleTimerDisabled=YES;//不自动锁屏
                }
                
                [_playerActivity stopAnimating];
                _playerActivity.hidden=YES;
                self.controllerView.hidden=YES;
                
            }
                break;
                
            case AVPlayerItemStatusFailed:
            {
                __weak typeof (self) wself= self;
                
                [[self.avPlayer currentItem]removeObserver:self forKeyPath:@"status"];
                [[self.avPlayer currentItem]removeObserver:self forKeyPath:@"loadedTimeRanges"];
                [[self.avPlayer currentItem]removeObserver:self forKeyPath:@"playbackBufferEmpty"];
                [[self.avPlayer currentItem]removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
                
                dispatch_async(dispatch_get_main_queue(), ^void(){
                    [_playerActivity stopAnimating];
                     _playerActivity.hidden=YES;
                    [wself  showNetworkError:NETWORK_ERROR_NONETWORK];
                    
                    
                });
            }
                break;
        }
    }else if ([path isEqualToString:@"loadedTimeRanges"]){
        
        CMTime duration = [[self.avPlayer currentItem] duration];
        if (CMTIME_IS_INVALID(duration)) {
            return;
        }
        Float64 durationTime = CMTimeGetSeconds(duration);
        Float64 bufferTime = [self availableDuration];
        if (isnan(durationTime) || isnan(bufferTime) || durationTime == 0) {
            return;
        }
        
        [self.bufferProgress setProgress:bufferTime/durationTime animated:YES];

    }
}

- (float)availableDuration
{
    NSArray *loadedTimeRanges = [[self.avPlayer currentItem] loadedTimeRanges];
    // Check to see if the timerange is not an empty array, fix for when video goes on airplay
    // and video doesn't include any time ranges
    if ([loadedTimeRanges count] > 0) {
        CMTimeRange timeRange = [[loadedTimeRanges objectAtIndex:0] CMTimeRangeValue];
        Float64 startSeconds = CMTimeGetSeconds(timeRange.start);
        Float64 durationSeconds = CMTimeGetSeconds(timeRange.duration);
        return (startSeconds + durationSeconds);
    } else {
        return 0.0f;
    }
}

-(void)setavPlayerLayerFrame{
    
     self.avPlayerLayer.frame = CGRectMake(0, 0, self.screenView.frame.size.width, self.screenView.frame.size.height);
    
    [self.controllerView bringSubviewToFront:self.playerSlider];

    
}

- (IBAction)playBtnClick:(id)sender {
    if(self.isPlaying){
        self.btnPlayBig.hidden=NO;
        [self.avPlayer pause];
        self.isPlaying=NO;
        UIImage *image=[UIImage imageNamed:BTN_SMALL_PLAY];
        [self.btnPlay setImage:image forState:UIControlStateNormal];
        [UIApplication sharedApplication].idleTimerDisabled=NO;//自动锁屏
    }else{
        
        [self.avPlayer play];
        self.isPlaying=YES;
         self.btnPlayBig.hidden=YES;
         UIImage *image=[UIImage imageNamed:BTN_SMALL_PAUSE];
        [self.btnPlay setImage:image forState:UIControlStateNormal];
         [UIApplication sharedApplication].idleTimerDisabled=YES;//不自动锁屏
    }
    
}

- (IBAction)zoomBtnClick:(id)sender {
    
    [self removeFromSuperview];
    if (self.currentStateZoomMax==NO){
        self.currentStateZoomMax=YES;
        UIImage *image=[UIImage imageNamed:BTN_ZOOM_MIN];
        [self.zoomBtn setImage:image forState:UIControlStateNormal];
        
        
         AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
         self.pcAVPlayerViewController=[[PCAVPlayerViewController alloc]init];
        [self.pcAVPlayerViewController.view addSubview:self];
         self.frame=CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        [appDelegate.window.rootViewController presentViewController:self.pcAVPlayerViewController animated:NO completion:nil];
        
    }else{
        
         self.currentStateZoomMax=NO;
 
        [self.pcAVPlayerViewController dismissViewControllerAnimated:NO completion:nil];
         UIImage *image=[UIImage imageNamed:BTN_ZOOM_MAX];
        [self.zoomBtn setImage:image forState:UIControlStateNormal];
        
        if (self.zoomInlock) {
            self.zoomInlock();
        }
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return (interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight);
}


- (IBAction)btnPlayBigClick:(id)sender {
    
    self.btnPlayBig.hidden=YES;
    if (self.isNewViedio){
        
         Reachability *r = [Reachability reachabilityWithHostName:@"www.apple.com"];
        
         switch ([r currentReachabilityStatus]) {
            case NotReachable:
             {
                [self showNetworkError:NETWORK_ERROR_NONETWORK];
                 return;
             }
                break;
           
            case ReachableViaWWAN://使用3G
             {
                 [self showNetworkError:NETWORK_ERROR_NOWIFI];
                 return;
             }
                 
                break;
        }
        
        
        
        [self loadVideo:self.currentUri];
        
         self.playerActivity.hidden=NO;
        
       
    
    }else{
         [self.avPlayer play];
        
          self.isPlaying=YES;

        UIImage *image=[UIImage imageNamed:BTN_SMALL_PAUSE];
        [self.btnPlay setImage:image forState:UIControlStateNormal];
        [UIApplication sharedApplication].idleTimerDisabled=YES;//不自动锁屏
        
    }
    
      self.thumbImageView.hidden=YES;
    
     [self.screenView sendSubviewToBack:self.thumbImageView];
}


- (void)screenTouch:(UITapGestureRecognizer *)gesture
{
        if (self.isNewViedio){
           return;
        }
    
        if (self.controllerView.hidden){
            self.controllerView.hidden=NO;
            [self.screenView bringSubviewToFront:self.controllerView];
        }else{
            self.controllerView.hidden=YES;
        }

}
#pragma mark UIGestureRecognizerDelegate
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch{
    
    if ([touch.view isMemberOfClass:[UIButton class]]) {
        //放过button点击拦截
        return NO;
    }else{
        return YES;
    }
    
}


#pragma mark 更新播放进度
- (void)updateSliderTimer
{
    
   
    AVPlayerItem * playerItem=[self.avPlayer currentItem];
    
    if (playerItem .duration.timescale != 0) {
       
        self.currentTimeLabel.hidden=NO;
        
        self.playerSlider.value = CMTimeGetSeconds([playerItem currentTime]) / (playerItem.duration.value / playerItem.duration.timescale); //当前进度
       
        
        //当前时长进度progress
        NSInteger proMin = (NSInteger)CMTimeGetSeconds([_avPlayer currentTime]) / 60;//当前秒
        NSInteger proSec = (NSInteger)CMTimeGetSeconds([_avPlayer currentTime]) % 60;//当前分钟
        //    NSLog(@"%d",_playerItem.duration.timescale);
        //    NSLog(@"%lld",_playerItem.duration.value/1000 / 60);
        //duration 总时长
        
        NSInteger durMin = (NSInteger)playerItem.duration.value / playerItem.duration.timescale / 60;//总秒
        NSInteger durSec = (NSInteger)playerItem.duration.value / playerItem.duration.timescale % 60;//总分钟
       
        
        [self.currentTimeLabel setTextColor:PCColor(95, 95, 95, 1)];
        
        NSString *plaiTtext=[NSString stringWithFormat:@"%02ld:%02ld / %02ld:%02ld", proMin, proSec, durMin, durSec];

        
        NSMutableAttributedString *colorTtext = [[NSMutableAttributedString alloc] initWithString:plaiTtext ];
        
        NSInteger separator= [plaiTtext rangeOfString:@"/"].location;
        
        [colorTtext addAttribute:NSForegroundColorAttributeName value:PCColor(163, 163, 163, 1) range:NSMakeRange(0,separator)];
        
        self.currentTimeLabel.attributedText = colorTtext;
        
       
    }else{
        
        
        self.currentTimeLabel.hidden=YES;
    }
    
}

#pragma mark 改变播放进度
- (IBAction)playerSliderChange:(id)sender {
    
    if (_avPlayer.status == AVPlayerStatusReadyToPlay) {
        
        //    //计算出拖动的当前秒数
        CGFloat total = (CGFloat)[self.avPlayer currentItem].duration.value /[self.avPlayer currentItem].duration.timescale;
        
        //    NSLog(@"%f", total);
        
        NSInteger dragedSeconds = floorf(total * self.playerSlider.value);
        
        //    NSLog(@"dragedSeconds:%ld",dragedSeconds);
        
        //转换成CMTime才能给player来控制播放进度
        
        CMTime dragedCMTime = CMTimeMake(dragedSeconds, 1);
        
        [_avPlayer pause];
        
        __weak typeof (self) wself=self;
        
        [_avPlayer seekToTime:dragedCMTime completionHandler:^(BOOL finish){
            
            if (wself.isPlaying){
               [wself.avPlayer play];
            }
            
        }];
    }
    
}

- (void)moviePlayDidEnd:(id)sender
{
    
    [self.avPlayer pause];

    UIImage *image=[UIImage imageNamed:BTN_SMALL_PLAY];
    [self.btnPlay setImage:image forState:UIControlStateNormal];
  
    CMTime dragedCMTime = CMTimeMake(0, 1);

    [_avPlayer seekToTime:dragedCMTime completionHandler:^(BOOL finish){
        
        
    }];
    
    
    if(self.currentStateZoomMax){
     self.controllerView.hidden=NO;
    }else{
        self.controllerView.hidden=YES;
    }
   
    self.thumbImageView.hidden=NO;
    [self.screenView bringSubviewToFront:self.thumbImageView];
    
    self.btnPlayBig.hidden=NO;
    [self.screenView bringSubviewToFront:self.btnPlayBig];
    
    [UIApplication sharedApplication].idleTimerDisabled=NO;//自动锁屏
}

-(void)stopPlayer{//这个方法是被外部调用的
    if (self.currentStateZoomMax==NO){
     if (_avPlayer.status == AVPlayerStatusReadyToPlay){
         self.btnPlayBig.hidden=NO;
         [self.screenView bringSubviewToFront:self.btnPlayBig];
        [self moviePlayDidEnd:nil];
         [UIApplication sharedApplication].idleTimerDisabled=NO;//自动锁屏
        
     }
    }
}

-(void)pausePlayer{//这个方法是被外部调用的
   
    if(self.isPlaying&&self.currentStateZoomMax==NO){
        
        self.btnPlayBig.hidden=NO;
        [self.screenView bringSubviewToFront:self.btnPlayBig];
        [self.avPlayer pause];
        self.isPlaying=NO;
        UIImage *image=[UIImage imageNamed:BTN_SMALL_PLAY];
        [self.btnPlay setImage:image forState:UIControlStateNormal];
        [UIApplication sharedApplication].idleTimerDisabled=NO;//自动锁屏
    }
    
}

-(void)applicationDidEnterBackgroundNotification:(NSNotification *)notification{
    
    if(self.isPlaying){
        self.btnPlayBig.hidden=NO;
        [self.avPlayer pause];
        self.isPlaying=NO;
        UIImage *image=[UIImage imageNamed:BTN_SMALL_PLAY];
        [self.btnPlay setImage:image forState:UIControlStateNormal];
        [UIApplication sharedApplication].idleTimerDisabled=NO;//自动锁屏
    }
}

-(void)showNetworkError:(NSInteger )errorType{
    
    self.networkErrorView.hidden=NO;
    
    self.networkErrorView.frame=self.frame;
    
    self.btnPlayBig.hidden=YES;
    
    if (errorType==NETWORK_ERROR_NONETWORK){//网络不给力
    
         self.errorLabel.frame=CGRectMake(self.frame.size.width/2-35, self.frame.size.height/2-30, 120, 16);
        [self.errorLabel setText:@"网络不给力"];
        [self.errorButton setTitle:@"  重试" forState:UIControlStateNormal];
      
        [self.errorButton setImage:[UIImage imageNamed:BTN_RETRY] forState:UIControlStateNormal];
        self.errorButton.tag=10012;
        self.errorLabel2.hidden=YES;
    
    }else if (errorType==NETWORK_ERROR_NOWIFI){//非wifi模式下播放
        
         self.errorLabel.frame=CGRectMake(self.frame.size.width/2-40, self.frame.size.height/2-30, 120, 16);
        [self.errorLabel setText:@"未检测到wifi"];
        
         self.errorLabel2.frame=CGRectMake(self.frame.size.width/2-90, self.frame.size.height/2, 180, 16);
         self.errorLabel2.hidden=NO;
        [self.errorLabel2 setText:@"是否使用资费流量观看视频"];

        
        [self.errorButton setTitle:@"用流量继续看" forState:UIControlStateNormal];
        [self.errorButton setImage:nil forState:UIControlStateNormal];
        self.errorButton.tag=20056;
        
    }
    
    self.errorButton.frame=CGRectMake(self.frame.size.width/2-50, self.frame.size.height/2+30, 100, 32);
    [self.screenView bringSubviewToFront:self.networkErrorView];
    
    
}


-(void)setNetworkErrorView{
    self.networkErrorView=[[UIView alloc]initWithFrame:self.frame];
    self.networkErrorView.backgroundColor=PCColor(0, 0, 0, 0.6);
    
    [self.screenView  addSubview:self.networkErrorView];
    self.networkErrorView.hidden=YES;
    
    
    self.errorLabel=[[UILabel alloc]init];
    [self.errorLabel setTextColor:[UIColor whiteColor]];
    [self.networkErrorView addSubview:self.errorLabel];

    
    self.errorButton = [[UIButton alloc]init];
    
    [self.errorButton .layer setMasksToBounds:YES];
    [self.errorButton .layer setCornerRadius:16.0];
    
    [self.errorButton setTitleColor:PCColor(48, 110, 164, 1) forState:UIControlStateNormal];
    [self.networkErrorView addSubview:self.errorButton];

    
    [self.errorButton.layer setBorderWidth:1.0];
    [self.errorButton.layer setBorderColor:PCColor(48, 110, 164, 1).CGColor];//边框颜色
    [self.errorButton addTarget:self action:@selector(errorBtnClick:) forControlEvents:UIControlEventTouchUpInside];
    
    
     self.errorLabel2=[[UILabel alloc]init];
    [self.errorLabel2 setTextColor:[UIColor whiteColor]];
    [self.networkErrorView addSubview:self.errorLabel2];
    
     self.errorButton.titleLabel.font=  [UIFont systemFontOfSize:13];
    
     self.errorLabel.font=[UIFont systemFontOfSize:15];
     self.errorLabel2.font=[UIFont systemFontOfSize:15];
}

-(void)errorBtnClick:(id)sender{
    
    if (self.errorButton.tag==10012){//网络不给力点击重试
     
        
        Reachability *r = [Reachability reachabilityWithHostName:@"www.apple.com"];
        if ([r currentReachabilityStatus]==NotReachable){
        [self showNetworkError:NETWORK_ERROR_NONETWORK];
            return;
            
        }else{
        
         NSString *urlTemp=self.currentUri;
         self.currentUri=nil;
         [self setVideoUrlStr:urlTemp];
         self.playerActivity.hidden=NO;
         [self.screenView sendSubviewToBack:self.thumbImageView];
            
        }
        
    }else if (self.errorButton.tag==20056){//非wifi点击使用流量观看
        
        [self loadVideo:self.currentUri];
        
        self.playerActivity.hidden=NO;
        self.btnPlayBig.hidden=YES;
        [self.screenView sendSubviewToBack:self.thumbImageView];

        
    }
    
    self.networkErrorView.hidden=YES;
}

@end
