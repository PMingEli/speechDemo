//
//  ControlButton.m
//  speechDemo
//
//  Created by 彭明均 on 2024/6/25.
//

#import "ControlButton.h"

@implementation ControlButton

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ControlButton-touchesBegan");
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    // 手指在ControlButton中，正在录音
    NSLog(@"ControlButton-touchesMoved");
    self.recorderView.status = RecorderViewStatusRecording;
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    // 手指结束触摸，在ControlButton内，发送录音
    NSLog(@"ControlButton-touchesEnded");
    self.recorderView.status = RecorderViewStatusRecordedSend;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"ControlButton-touchesCancelled");
    [super touchesCancelled:touches withEvent:event];
}

@end
