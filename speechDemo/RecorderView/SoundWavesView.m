//
//  SoundWavesView.m
//  speechDemo
//
//  Created by 彭明均 on 2024/6/25.
//

#import "SoundWavesView.h"
#import "SoundWavesLine.h"
#import <Masonry/Masonry.h>

#define SoundWavesViewLineWidth   2.f    /// 线宽
#define SoundWavesViewLineHeight  5.f    /// 线高
#define SoundWavesViewLineSpace   2.f    /// 线间距
#define SoundWavesViewLineNumber  25.f   /// 线数量

@interface SoundWavesView()

@property (strong, nonatomic) NSMutableArray<SoundWavesLine *> *lineGroup;

@end

@implementation SoundWavesView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self initializeAttribute];
        [self addCustomControl];
    }
    return self;
}

- (void)initializeAttribute {
    self.lineGroup = [NSMutableArray arrayWithCapacity:SoundWavesViewLineNumber];
}

- (void)addCustomControl {
    for (int i = 0; i < SoundWavesViewLineNumber; i++) {
        SoundWavesLine *line = [[SoundWavesLine alloc] initWithLineColor:[UIColor whiteColor]];
        line.lineHeight = SoundWavesViewLineHeight;
        [self addSubview:line];
        [self.lineGroup addObject:line];
    }
    [self layoutLine];
    [self beginAnimation];
    
}

- (void)beginAnimation {
    NSArray *randomArray = [self sortedRandomArrayByArray:[self randomArray]];
    if (!randomArray.count) {
        [self.lineGroup enumerateObjectsUsingBlock:^(SoundWavesLine * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj stopAnimation];
        }];
        return;
    }
    [self.lineGroup enumerateObjectsUsingBlock:^(SoundWavesLine * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        int index = arc4random_uniform(SoundWavesViewLineNumber);
        CGFloat random = [randomArray[index] floatValue];
        obj.toValue = random;
        obj.beginTime = index / 100.0;
        [obj beginAnimation];
    }];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self beginAnimation];
    });
}

- (void)setLevel:(SoundWavesLevel)level {
    _level = level;
    [self beginAnimation];
}

- (NSArray *)randomArray {
    NSArray *level;
    switch (self.level) {
        case SoundWavesLevelNormal: // 普通状态
            level = @[@(SoundWavesViewLineHeight+1), @(SoundWavesViewLineHeight+2), @(SoundWavesViewLineHeight+3), @(SoundWavesViewLineHeight+4)];
            break;
        case SoundWavesLevelWeak: // 弱
            level = @[@(SoundWavesViewLineHeight+5), @(SoundWavesViewLineHeight+6), @(SoundWavesViewLineHeight+7), @(SoundWavesViewLineHeight+8)];
            break;
        case SoundWavesLevelMedium: // 中
            level = @[@(SoundWavesViewLineHeight+9), @(SoundWavesViewLineHeight+10), @(SoundWavesViewLineHeight+10), @(SoundWavesViewLineHeight+12)];
            break;
        case SoundWavesLevelStrong: // 强
            level = @[@(SoundWavesViewLineHeight+13), @(SoundWavesViewLineHeight+14), @(SoundWavesViewLineHeight+15), @(SoundWavesViewLineHeight+16)];
            break;
        default:
            return @[];
            break;
    }
    NSMutableArray *randomArray = [NSMutableArray arrayWithCapacity:SoundWavesViewLineNumber];
    int index = -1;
    for (int i = 0; i < SoundWavesViewLineNumber; i++) {
        index++;
        if (index >= level.count) {
            index = 0;
        }
        CGFloat levelNumber = [level[index] floatValue];
        [randomArray addObject:@(levelNumber)];
    }
    return randomArray;
}

//对数组随机排序
- (NSArray *)sortedRandomArrayByArray:(NSArray *)array{
    NSArray *randomArray = [[NSArray alloc] init];
    randomArray = [array sortedArrayUsingComparator:^NSComparisonResult(id one, id two) {
        int seed = arc4random_uniform(2);
        if (seed) {
            return  [one compare:two];
        } else {
            return [two compare:one];
        }
    }];
    
    return randomArray;
}

- (void)layoutLine {
    UIView *prev;
    for (NSInteger i = 0, len = self.lineGroup.count; i < len; i++) {
        UIView *v = self.lineGroup[i];
        [v mas_makeConstraints:^(MASConstraintMaker *make) {
            if (prev) {
                make.width.equalTo(prev);
                make.left.equalTo(prev.mas_right).offset(SoundWavesViewLineSpace);
                if (i == len - 1) {//last one
                    make.right.equalTo(self);
                }
            }
            else {//first one
                make.width.equalTo(@(SoundWavesViewLineWidth));
                make.left.equalTo(self);
            }
            make.height.equalTo(@(SoundWavesViewLineHeight));
            make.centerY.equalTo(self);
        }];
        prev = v;
    }
}


@end
