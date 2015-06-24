//
//  HYStatusBarWindow.m
//  HYRefreshDemo
//
//  Created by jimubox on 15/4/29.
//  Copyright (c) 2015年 jimubox. All rights reserved.
//

#import "HYStatusBarWindow.h"
#import "CWStatusBarNotification.h"
#import "HYRefreshConstant.h"

/**
 *  屏幕的尺寸
 */
#define kWinSize [UIScreen mainScreen].bounds.size

/**
 *  状态栏高度
 */
static CGFloat const kStatusBarHeight = 20;
/**
 *  动画持续时间
 */
static CGFloat const kDurationTime = 0.5;
/**
 *  动画延迟执行时间
 */
static CGFloat const kDelayTime = 1.5;

@interface HYStatusBarWindow()

//最前面那个label
@property(nonatomic,strong) UILabel *frontLabel;
//底部那个label
@property(nonatomic,strong) UILabel *bottomLabel;
//是否正在处于刷新中
@property(nonatomic,assign) BOOL isRefreshing;

@end


@implementation HYStatusBarWindow

#pragma mark - 工厂方法
#pragma mark 只是简单展示一个消息的方法
+(void)showMessage:(NSString *)msg
{
    [[HYStatusBarWindow sharedStatusBarWindow] instance_showMessage:msg];
}

#pragma mark 展示loading状态的方法
+(void)showLoadingWithMessage:(NSString *)msg
{
    [[HYStatusBarWindow sharedStatusBarWindow] instance_showLoadingWithMessage:msg];
}

#pragma mark 隐藏带有Loading效果的hud的方法
+(void)hideWithMessage:(NSString *)msg
{
    [[HYStatusBarWindow sharedStatusBarWindow] instance_hideWithMessage:msg];
}

+(void)hide
{
    [[HYStatusBarWindow sharedStatusBarWindow] instance_hide];
}


#pragma mark 单例方法
+(instancetype)sharedStatusBarWindow
{
    static HYStatusBarWindow *_statusBarWindow = nil;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        _statusBarWindow = [HYStatusBarWindow new];
        _statusBarWindow.isRefreshing = NO;
    });
    return _statusBarWindow;
}

#pragma mark - 生命周期方法
-(instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor blackColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
        self.windowLevel = UIWindowLevelAlert;
        self.frame = CGRectMake(0, 0, kWinSize.width, kStatusBarHeight);
        self.clipsToBounds = YES;
        self.hidden = NO;
    }
    return self;
}

#pragma mark - 实例方法
#pragma mark 展示消息的方法
-(void)instance_showMessage:(NSString *)msg
{
    if (self.isRefreshing) return;
    self.isRefreshing = YES;
    self.frontLabel.text = msg;
    self.hidden = NO;
    [self private_resetFrame:self.frontLabel];
    [UIView animateWithDuration:kDurationTime animations:^{
        self.frontLabel.frame = (CGRect){CGPointZero,self.frontLabel.frame.size};
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:kDurationTime delay:kDelayTime options:UIViewAnimationOptionTransitionNone animations:^{
            self.frontLabel.frame = (CGRect){CGPointMake(0, -kStatusBarHeight),self.frontLabel.frame.size};
        } completion:^(BOOL finished) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.hidden = YES;
                [self private_resetAllViews];
            });
        }];
    }];
}

#pragma mark 展示loading状态的实例方法
-(void)instance_showLoadingWithMessage:(NSString *)msg
{
    if (self.isRefreshing) return;
    self.isRefreshing = YES;
    self.frontLabel.text = msg;
    self.hidden = NO;
    [self private_resetFrame:self.frontLabel];
    [UIView animateWithDuration:kDurationTime animations:^{
        self.frontLabel.frame = (CGRect){CGPointZero,self.frontLabel.frame.size};
    } completion:nil];
}

#pragma mark 带有文字的隐藏实例方法
-(void)instance_hideWithMessage:(NSString *)msg
{
    if (!self.isRefreshing) return;
    self.bottomLabel.text = msg.length > 0 ? msg : HYRefreshEndRefreshMessage;
    [self private_resetFrame:self.bottomLabel];
    [UIView animateWithDuration:kDurationTime animations:^{
        self.frontLabel.frame = (CGRect){CGPointMake(0, -kStatusBarHeight),self.frontLabel.frame.size};
        self.bottomLabel.frame = (CGRect){CGPointZero,self.bottomLabel.frame.size};
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kDelayTime * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.hidden = YES;
            self.bottomLabel.frame = (CGRect){CGPointMake(0, -kStatusBarHeight),self.bottomLabel.frame.size};
            dispatch_async(dispatch_get_main_queue(), ^{
                [self private_resetAllViews];
            });
        });
    }];
}

#pragma mark 直接隐藏的方法
-(void)instance_hide{
    if (!self.isRefreshing) return;
    dispatch_async(dispatch_get_main_queue(), ^{
        self.hidden = YES;
        [self private_resetAllViews];
    });
}

#pragma mark - 重写方法
- (void)setHidden:(BOOL)hidden{
    [super setHidden:hidden];
    static BOOL ing = NO;
    if(ing && hidden) return;
    ing = YES;
    self.alpha = hidden;
    [UIView animateWithDuration:kFadeDuration animations:^{
        self.alpha = !hidden;
    } completion:^(BOOL finished) {
        [super setHidden:!self.alpha];
        ing = NO;
    }];
}

-(UILabel *)frontLabel
{
    if (!_frontLabel) {
        _frontLabel = [self private_createLabelWithMessage:nil];
        [self addSubview:_frontLabel];
    }
    return _frontLabel;
}

-(UILabel *)bottomLabel
{
    if (!_bottomLabel) {
        _bottomLabel = [self private_createLabelWithMessage:nil];
        [self addSubview:_bottomLabel];
    }
    return _bottomLabel;
}

#pragma mark - 私有方法
-(UILabel *)private_createLabelWithMessage:(NSString *)msg
{
    UILabel *msgLabel = [[UILabel alloc] init];
    msgLabel.text = msg;
    msgLabel.font = [UIFont systemFontOfSize:12];
    msgLabel.backgroundColor = [UIColor clearColor];
    msgLabel.textAlignment = NSTextAlignmentCenter;
    msgLabel.textColor = [UIColor whiteColor];
    msgLabel.frame = CGRectMake(0, kStatusBarHeight, kWinSize.width, kStatusBarHeight);
    return msgLabel;
}

-(void)private_resetAllViews
{
    self.isRefreshing = NO;
    self.hidden = YES;
}

-(void)private_resetFrame:(UILabel *)label{
    label.frame = CGRectMake(0, kStatusBarHeight, kWinSize.width, kStatusBarHeight);
}


@end
