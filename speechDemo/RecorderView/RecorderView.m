//
//  RecorderView.m
//  speechDemo
//
//  Created by 彭明均 on 2024/6/25.
//

#import "RecorderView.h"
#import <Masonry/Masonry.h>
#import "SoundWavesView.h"
#import "Recorder.h"
#import "RecorderBackgroundView.h"
#import "ControlButton.h"
#import "UIAlertController+Blocks.h"

#define RecorderViewRGBA(r,g,b,a) [UIColor colorWithRed:(r)/255.0 green:(g)/255.0 blue:(b)/255.0 alpha:a]

@interface RecorderView()<RecorderViewDelegate>

@property (assign, nonatomic) BOOL isRecording; // 是否正在录音

@property (assign, nonatomic) CGFloat duration; // 录音时长

@property (strong, nonatomic) RecorderBackgroundView *bgView; // 手势整个背景

@property (strong, nonatomic) UIImageView *bubbleBgImageView;
@property (strong, nonatomic) SoundWavesView *waveView;

@property (strong, nonatomic) UIImageView *closeImageView;
@property (strong, nonatomic) UILabel *tipLabel;

@property (strong, nonatomic) ControlButton *controlButton; // 手势按钮背景
@property (strong, nonatomic) UIImageView *controlBgImageView;
@property (strong, nonatomic) UILabel *timerLabel;

@property (weak, nonatomic) id<RecorderViewDelegate> delegate;
@property (weak, nonatomic) UIViewController *parentVC;

@end

@implementation RecorderView

+ (RecorderView *)recorderInView:(UIView *)view delegate:(id<RecorderViewDelegate>)delegate vc:(UIViewController *)vc {
    RecorderView *recorderView = [[RecorderView alloc] initWithFrame:view.bounds];
    [view addSubview:recorderView];
    recorderView.delegate = delegate;
    recorderView.parentVC = vc;
    recorderView.hidden = YES;
    return recorderView;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    return self;
}

- (void)show {
    [Recorder sharedInstance].delegate = self;
    self.isRecording = NO;
    self.waveView.level = SoundWavesLevelNormal;
    self.timerLabel.text = @"00:00";
    self.status = RecorderViewStatusRecording;
    
    self.hidden = NO;
    self.alpha = 0;
    [UIView animateWithDuration:0.2f animations:^{
        self.alpha = 1;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.2f animations:^{
        self.alpha = 0;
    } completion:^(BOOL finished) {
        self.hidden = YES;
    }];
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    
    _bgView = [RecorderBackgroundView new];
    _bgView.recorderView = self;
    _bgView.backgroundColor = RecorderViewRGBA(0,0,0,0.5);
    [self addSubview:_bgView];
    
    _bubbleBgImageView = [UIImageView new];
    [self addSubview:_bubbleBgImageView];
    
    _waveView = [[SoundWavesView alloc] init];
    [_bubbleBgImageView addSubview:_waveView];
    
    _closeImageView = [UIImageView new];
    [self addSubview:_closeImageView];

    _tipLabel = [UILabel new];
    _tipLabel.font = [UIFont systemFontOfSize:14];
    _tipLabel.textColor = [UIColor whiteColor];
    [self addSubview:_tipLabel];
    
    _controlButton = [ControlButton new];
    _controlButton.recorderView = self;
    [self addSubview:_controlButton];
    
    _controlBgImageView = [UIImageView new];
    _controlBgImageView.image = [UIImage imageNamed:@"recorder_timer_bg"];
    [_controlButton addSubview:_controlBgImageView];
    
    _timerLabel = [UILabel new];
    _timerLabel.font = [UIFont systemFontOfSize:14];
    _timerLabel.textColor = RecorderViewRGBA(91,91,91,1);
    [_controlButton addSubview:_timerLabel];
    
    [_bgView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [_bubbleBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self);
        make.width.mas_equalTo(153.f);
        make.height.mas_equalTo(80.f);
    }];
    
    [_waveView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.bubbleBgImageView);
        make.top.mas_equalTo(15.f);
        make.height.mas_equalTo(40.f);
    }];
    
    [_closeImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.tipLabel.mas_top).offset(-28);
    }];
    
    [_tipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.equalTo(self.controlBgImageView.mas_top).offset(-20);
    }];
    
    [_controlButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.left.right.equalTo(self);
        make.height.mas_equalTo(112.5);
    }];
    
    [_controlBgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.controlButton);
    }];
    
    [_timerLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.controlButton);
    }];
}

// 设置状态变化
- (void)setStatus:(RecorderViewStatus)status {
    _status = status;
    switch (status) {
        case RecorderViewStatusRecording:
            _bubbleBgImageView.image = [UIImage imageNamed:@"recorder_bubble_b"];
            _closeImageView.image = [UIImage imageNamed:@"recorder_close_send"];
            _tipLabel.text = @"松开 发送";
            [self startRecording];
            break;
        case RecorderViewStatusCancelNotice:
            _bubbleBgImageView.image = [UIImage imageNamed:@"recorder_bubble_r"];
            _closeImageView.image = [UIImage imageNamed:@"recorder_close_cancel"];
            _tipLabel.text = @"松开 取消";
            break;
        case RecorderViewStatusRecordedSend:
            // 结束录音，发送, 最后会调用方法 - (void)recordDidEnd:(NSString *)url duration:(CGFloat)duration
            [[Recorder sharedInstance] recordEnd];
            break;
        case RecorderViewStatusRecordedCancel:
            // 结束录音，取消
            [[Recorder sharedInstance] cancelRecord];
            [self dismiss];
            break;
        default:
            break;
    }
}

#pragma mark - 各种事件
- (void)startRecording {
    if (self.isRecording) {
        return;
    }
    if ([[Recorder sharedInstance] canRecord]) {
        [[Recorder sharedInstance] startRecord];
        self.isRecording = YES;
    } else {
        [UIAlertController showAlertInViewController:self.parentVC
                                           withTitle:@"警告"
                                             message:@"无法录音,请到设置-隐私-麦克风,允许程序访问"
                                   cancelButtonTitle:nil
                              destructiveButtonTitle:@"确定"
                                   otherButtonTitles:nil
                                            tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
        }];
    }
}

#pragma - RecorderDelegate
- (void)recordingDuration:(NSString *)duration {
    _timerLabel.text = duration;
}

- (void)recordingMeters:(CGFloat)voiceMeter {
    if (voiceMeter <= 0.1) {
        _waveView.level = SoundWavesLevelNormal;
    } else if (voiceMeter <= 0.2) {
        _waveView.level = SoundWavesLevelWeak;
    } else if (voiceMeter <= 0.3) {
        _waveView.level = SoundWavesLevelMedium;
    } else {
        _waveView.level = SoundWavesLevelStrong;
    }
}

- (void)recordTooShort {
    [UIAlertController showAlertInViewController:self.parentVC
                                       withTitle:@"警告"
                                         message:@"录制时间太短了"
                               cancelButtonTitle:nil
                          destructiveButtonTitle:@"确定"
                               otherButtonTitles:nil
                                        tapBlock:^(UIAlertController * _Nonnull controller, UIAlertAction * _Nonnull action, NSInteger buttonIndex) {
    }];
    [self dismiss];
}

- (void)recordDidEnd:(NSString *)text duration:(CGFloat)duration {
    [self.delegate recordDidEnd:text duration:duration];
    [self dismiss];
}

- (void)recordDidRecognized:(NSString *)text {
    [self.delegate recordDidRecognized:text];
}

@end
