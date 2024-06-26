//
//  TouchButton.h
//  speechDemo
//
//  Created by cseMing on 2024/6/25.
//

#import <UIKit/UIKit.h>
#import "RecorderView.h"

NS_ASSUME_NONNULL_BEGIN

@interface TouchButton : UIButton

@property (weak, nonatomic) RecorderView *recorderView; // 在录音视图寻找下级视图

@end

NS_ASSUME_NONNULL_END
