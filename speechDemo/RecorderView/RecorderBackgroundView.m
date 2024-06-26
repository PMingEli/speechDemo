//
//  RecorderBackgroundView.m
//  speechDemo
//
//  Created by 彭明均 on 2024/6/25.
//

#import "RecorderBackgroundView.h"

@implementation RecorderBackgroundView

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"RecorderBackgroundView-touchesBegan");
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    // 手指移出 ControlButton, 提示取消
    NSLog(@"RecorderBackgroundView-touchesMoved");
    self.recorderView.status = RecorderViewStatusCancelNotice;
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    // 手指结束触摸，不在 ControlButton 内，取消录音
    NSLog(@"RecorderBackgroundView-touchesEnded");
    self.recorderView.status = RecorderViewStatusRecordedCancel;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"RecorderBackgroundView-touchesCancelled");
    [super touchesCancelled:touches withEvent:event];
}

@end
