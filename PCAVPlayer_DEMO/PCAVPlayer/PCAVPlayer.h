//
//  PCHomeAdPlayer.h
//  PCMClient4
//
//  Created by PCOnline2015 on 16/5/26.
//  Copyright © 2016年 太平洋网络. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PCAVPlayer : UIView
@property (nonatomic , strong) void (^zoomInlock)();//点击最大化按钮响应block

@property (weak, nonatomic) IBOutlet UIButton *btnPlayBig;//屏幕中间的大播放按钮

@property (nonatomic,strong)NSString *currentUri;

@property (weak, nonatomic) IBOutlet UIImageView *thumbImageView;

-(void)stopPlayer;
-(void)pausePlayer;
-(void)setVideoUrlStr:(NSString *)urlStr;
  
+ (PCAVPlayer *)instance;

@end
