//
//  Recorder.m
//  speechDemo
//
//  Created by cseMing on 2024/6/25.
//

#import "Recorder.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#define kRecorderMaxSeconds 60.f
#define kRecorderMinSeconds 1.f
#define kRecorderAuthStatus @"kRecorderAuthStatus"

@interface Recorder ()<AVAudioRecorderDelegate, SFSpeechRecognizerDelegate>

@property(nonatomic) NSTimer *recordingTimer; // 录音定时器
@property(nonatomic) NSTimer *updateMeterTimer; // 音量定时器
@property(nonatomic, assign) NSInteger seconds; // 录音描述
@property(nonatomic) BOOL recordCanceled; // 录音取消

@property (nonatomic,strong) AVAudioRecorder *audioRecorder;
@property (nonatomic,strong) AVAudioEngine *audioEngine;
@property (nonatomic,strong) SFSpeechRecognizer *speechRecognizer;
@property (nonatomic,strong) SFSpeechRecognitionTask *recognitionTask;
@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest;

@end

@implementation Recorder

+ (instancetype)sharedInstance {
    static Recorder *instance = NULL;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [Recorder new];
    });
    return instance;
}

- (void)startRecord {
    
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);
    
    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {
            NSLog(@"识别结果：%@", result.bestTranscription.formattedString);
            if (result.isFinal) {
                [strongSelf.delegate recordDidEnd:result.bestTranscription.formattedString duration:strongSelf.seconds];
            } else {
                [strongSelf.delegate recordDidRecognized:result.bestTranscription.formattedString];
            }
            isFinal = result.isFinal;
        }
        if (error || isFinal) {
            [strongSelf.audioEngine stop];
            [inputNode removeTapOnBus:0];
            strongSelf.recognitionTask = nil;
            strongSelf.recognitionRequest = nil;
            [strongSelf stopRecord];
        }
        
    }];
    
    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 
                    bufferSize:1024
                        format:recordingFormat
                         block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];
    
    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
    
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setCategory:AVAudioSessionCategoryRecord error:nil];
    BOOL r = [session setActive:YES error:nil];
    if (!r) {
        NSLog(@"activate audio session fail");
        return;
    }
    
    if (![self.audioRecorder prepareToRecord]) {
        NSLog(@"prepare record fail");
        [self stopRecord];
        return;
    }
    if (![self.audioRecorder record]) {
        NSLog(@"start record fail");
        [self stopRecord];
        return;
    }
    self.recordCanceled = NO;
    self.seconds = 0;
    self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                           target:self
                                                         selector:@selector(timerFired:)
                                                         userInfo:nil
                                                          repeats:YES];
    
    self.updateMeterTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                             target:self
                                                           selector:@selector(updateMeter:)
                                                           userInfo:nil
                                                            repeats:YES];
}

- (void)stopRecord {
    [self.audioEngine stop];
    if (_recognitionRequest) {
        [_recognitionRequest endAudio];
    }
    
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }
    
    [self.audioRecorder stop];
    [self.recordingTimer invalidate];
    self.recordingTimer = nil;
    [self.updateMeterTimer invalidate];
    self.updateMeterTimer = nil;
    [self.delegate recordingDuration:@"00:00"];
    [self.delegate recordingMeters:0];
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL r = [audioSession setActive:NO error:nil];
    if (!r) {
        NSLog(@"deactivate audio session fail");
    }
}

- (void)timerFired:(NSTimer*)timer {
    self.seconds = self.seconds + 1;
    NSInteger minute = self.seconds/60;
    NSInteger s = self.seconds%60;
    NSString *str = [NSString stringWithFormat:@"%02ld:%02ld", minute, s];
    [self.delegate recordingDuration:str];
    // 最大时间结束结束录音
    NSInteger countdown = kRecorderMaxSeconds - self.seconds;
    if (countdown <= 0) {
        [self recordEnd];
    }
}

- (void)updateMeter:(NSTimer*)timer {
    double voiceMeter = 0;
    if ([self.audioRecorder isRecording]) {
        [self.audioRecorder updateMeters];
        //获取音量的平均值  [recorder averagePowerForChannel:0];
        //音量的最大值  [recorder peakPowerForChannel:0];
        double lowPassResults = pow(10, (0.05 * [self.audioRecorder peakPowerForChannel:0]));
        voiceMeter = lowPassResults;
    }
    [self.delegate recordingMeters:voiceMeter];
//    NSLog(@"音量：%f", voiceMeter);
}

-(void)recordEnd {
    if (self.audioEngine.isRunning) {
        NSLog(@"停止录音...");
        self.recordCanceled = NO;
        [self stopRecord];
    }
}

- (void)cancelRecord {
    if (self.audioEngine.isRunning) {
        NSLog(@"取消录音...");
        self.recordCanceled = YES;
        [self stopRecord];
    }
}

- (BOOL)canRecord {
    __block BOOL bCanRecord = [[NSUserDefaults standardUserDefaults] boolForKey:kRecorderAuthStatus];
    if (!bCanRecord) {
        [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (status == SFSpeechRecognizerAuthorizationStatusAuthorized) {
                    [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:kRecorderAuthStatus];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            });
        }];
    }
    return bCanRecord;
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"record finish:%d", flag);
    if (!flag) {
        return;
    }
    if (self.recordCanceled) {
        return;
    }
    if (self.seconds < kRecorderMinSeconds) {
        NSLog(@"录制时间太短");
        [self.delegate recordTooShort];
        return;
    }
    
    [[NSFileManager defaultManager] removeItemAtURL:recorder.url error:nil];
}

#pragma mark - property

- (AVAudioRecorder *)audioRecorder {
    if (!_audioRecorder) {
        NSArray *pathComponents = [NSArray arrayWithObjects:
                                   [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                   @"voice.wav",
                                   nil];
        NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
        NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
        [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
        [recordSetting setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
        [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
        _audioRecorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
        _audioRecorder.delegate = self;
        _audioRecorder.meteringEnabled = self;
    }
    return _audioRecorder;
}

- (AVAudioEngine *)audioEngine{
    if (!_audioEngine) {
        _audioEngine = [[AVAudioEngine alloc] init];
    }
    return _audioEngine;
}
- (SFSpeechRecognizer *)speechRecognizer{
    if (!_speechRecognizer) {
        //腰围语音识别对象设置语言，这里设置的是中文
        NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"zh_CN"];
        
        _speechRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
        _speechRecognizer.delegate = self;
    }
    return _speechRecognizer;
}

#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available {
    if (available) {
        NSLog(@"可以录音");
    }
    else{
        NSLog(@"语音识别不可用");
    }
}

@end
