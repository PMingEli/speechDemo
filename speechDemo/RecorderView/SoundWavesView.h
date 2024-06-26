//
//  SoundWavesView.h
//  speechDemo
//
//  Created by 彭明均 on 2024/6/25.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SoundWavesLevel) {
    SoundWavesLevelMute = 0,  // 静音
    SoundWavesLevelNormal,    // 默认状态
    SoundWavesLevelWeak,      // 弱
    SoundWavesLevelMedium,    // 中
    SoundWavesLevelStrong,    // 强
};

NS_ASSUME_NONNULL_BEGIN

@interface SoundWavesView : UIView

/// 声波浮动等级
@property(assign, nonatomic) SoundWavesLevel level;

@end

NS_ASSUME_NONNULL_END
