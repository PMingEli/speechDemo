//
//  RecorderBackgroundView.h
//  speechDemo
//
//  Created by 彭明均 on 2024/6/25.
//

#import <UIKit/UIKit.h>
#import "RecorderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface RecorderBackgroundView : UIView

@property (weak, nonatomic) RecorderView *recorderView; // 用于修改状态

@end

NS_ASSUME_NONNULL_END
