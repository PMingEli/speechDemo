//
//  RecorderView.h
//  speechDemo
//
//  Created by cseMing on 2024/6/25.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, RecorderViewStatus) {
    RecorderViewStatusRecording,      // 录音中
    RecorderViewStatusCancelNotice,   // 提示取消
    RecorderViewStatusRecordedSend,   // 录音结束->发送
    RecorderViewStatusRecordedCancel  // 录音结束->取消
};

NS_ASSUME_NONNULL_BEGIN

@protocol RecorderViewDelegate<NSObject>

/// 录制完成
/// - Parameters:
///   - text: 识别文字
///   - duration: 音频时长
- (void)recordDidEnd:(NSString *)text duration:(CGFloat)duration;

- (void)recordDidRecognized:(NSString *)text;

@end

@interface RecorderView : UIView

+ (RecorderView *)recorderInView:(UIView *)view delegate:(id<RecorderViewDelegate>)delegate vc:(UIViewController *)vc;

/// 显示录音视图
- (void)show;

/// 交给其他控件改变状态
@property (assign, nonatomic) RecorderViewStatus status;

@end

NS_ASSUME_NONNULL_END
