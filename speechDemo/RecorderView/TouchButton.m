//
//  TouchButton.m
//  speechDemo
//
//  Created by cseMing on 2024/6/25.
//

#import "TouchButton.h"

@implementation TouchButton

/// 向下传递
- (UIView *)transfer:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self.recorderView];
    UIView *receivingView = [self.recorderView hitTest:touchPoint withEvent:event];
    return receivingView;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"TouchButton-touchesBegan");
    [[self transfer:touches withEvent:event] touchesBegan:touches withEvent:event];
    [super touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    NSLog(@"TouchButton-touchesMoved");
    [[self transfer:touches withEvent:event] touchesMoved:touches withEvent:event];
    [super touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(nullable UIEvent *)event {
    NSLog(@"TouchButton-touchesEnded");
    [[self transfer:touches withEvent:event] touchesEnded:touches withEvent:event];
    self.recorderView.status = RecorderViewStatusRecordedCancel;
    [super touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    NSLog(@"TouchButton-touchesCancelled");
    [[self transfer:touches withEvent:event] touchesCancelled:touches withEvent:event];
    [super touchesCancelled:touches withEvent:event];
}

@end
