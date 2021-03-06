//
//  DJNavigationController.m
//  DJNavigationBarSample
//
//  Created by DJ on 2018/4/28.
//  Copyright © 2018年 DennisDeng. All rights reserved.
//

#import "DJNavigationController.h"
#import "DJNavigationBarDefine.h"
#import "DJNavigationBar.h"
#import "UIViewController+DJNavigationBar.h"
#import "UIViewController+DJNavigationItem.h"

UIColor* blendColor(UIColor *from, UIColor *to, float percent)
{
    CGFloat fromRed = 0;
    CGFloat fromGreen = 0;
    CGFloat fromBlue = 0;
    CGFloat fromAlpha = 0;
    [from getRed:&fromRed green:&fromGreen blue:&fromBlue alpha:&fromAlpha];
    
    CGFloat toRed = 0;
    CGFloat toGreen = 0;
    CGFloat toBlue = 0;
    CGFloat toAlpha = 0;
    [to getRed:&toRed green:&toGreen blue:&toBlue alpha:&toAlpha];
    
    CGFloat newRed = fromRed + (toRed - fromRed) * percent;
    CGFloat newGreen = fromGreen + (toGreen - fromGreen) * percent;
    CGFloat newBlue = fromBlue + (toBlue - fromBlue) * percent;
    CGFloat newAlpha = fromAlpha + (toAlpha - fromAlpha) * percent;
    return [UIColor colorWithRed:newRed green:newGreen blue:newBlue alpha:newAlpha];
}

@interface DJNavigationController ()
<
    UIGestureRecognizerDelegate,
    UINavigationControllerDelegate
>

@property (nonatomic, readonly) DJNavigationBar *navigationBar;

@property (nonatomic, strong) UIVisualEffectView *fromFakeBar;
@property (nonatomic, strong) UIVisualEffectView *toFakeBar;
@property (nonatomic, strong) UIImageView *fromFakeShadow;
@property (nonatomic, strong) UIImageView *toFakeShadow;
@property (nonatomic, strong) UIImageView *fromFakeImageView;
@property (nonatomic, strong) UIImageView *toFakeImageView;

@property (nonatomic, assign) BOOL inGesture;

/// A Boolean value indicating whether navigation controller is currently pushing or pop a new view controller on the stack.
@property (nonatomic, getter = isDuringPushAnimation) BOOL duringPushAnimation;
@property (nonatomic, getter = isDuringPopAnimation) BOOL duringPopAnimation;

/// A real delegate of the class. `delegate` property is used only for keeping an internal state during
/// animations – we need to know when the animation ended, and that info is available only
/// from `navigationController:didShowViewController:animated:`.
@property (weak, nonatomic) id<UINavigationControllerDelegate> realDelegate;

@end

@implementation DJNavigationController
@dynamic navigationBar;

- (void)dealloc
{
    self.delegate = nil;
    self.interactivePopGestureRecognizer.delegate = nil;
}

- (instancetype)init
{
    return [super initWithNavigationBarClass:[DJNavigationBar class] toolbarClass:nil];
}

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
    NSAssert([navigationBarClass isSubclassOfClass:[DJNavigationBar class]], @"navigationBarClass Must be a subclass of DJNavigationBar");
    return [super initWithNavigationBarClass:navigationBarClass toolbarClass:toolbarClass];
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    if (self = [super initWithNavigationBarClass:[DJNavigationBar class] toolbarClass:nil])
    {
        self.viewControllers = @[rootViewController];
    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!self.delegate)
    {
        self.delegate = self;
    }
    
    self.interactivePopGestureRecognizer.delegate = self;
    [self.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
    [self.navigationBar setShadowImage:[UINavigationBar appearance].shadowImage];
    [self.navigationBar setTranslucent:YES]; // make sure translucent
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setDelegate:(id<UINavigationControllerDelegate>)delegate
{
    self.realDelegate = delegate != self ? delegate : nil;
    [super setDelegate:delegate ? self : nil];
}


#pragma mark - UINavigationController

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (animated)
    {
        if ([self isDuringPushAnimation])
        {
            return;
        }
        self.duringPushAnimation = YES;
    }
    
    [super pushViewController:viewController animated:animated];
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
    if (animated)
    {
        if ([self isDuringPopAnimation])
        {
            return nil;
        }
        self.duringPopAnimation = YES;
    }
    
    UIViewController *vc = [super popViewControllerAnimated:animated];
    self.navigationBar.barStyle = self.topViewController.dj_NavigationBarStyle;
    return vc;
}

- (NSArray<__kindof UIViewController *> *)popToViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if (animated)
    {
        if ([self isDuringPopAnimation])
        {
            return nil;
        }
        self.duringPopAnimation = YES;
    }
    
    NSArray *array = [super popToViewController:viewController animated:animated];
    self.navigationBar.barStyle = self.topViewController.dj_NavigationBarStyle;
    return array;
}

- (NSArray<__kindof UIViewController *> *)popToRootViewControllerAnimated:(BOOL)animated
{
    if (animated)
    {
        if ([self isDuringPopAnimation])
        {
            return nil;
        }
        self.duringPopAnimation = YES;
    }
    
    NSArray *array = [super popToRootViewControllerAnimated:animated];
    self.navigationBar.barStyle = self.topViewController.dj_NavigationBarStyle;
    return array;
}

- (BOOL)isImage:(UIImage *)image1 equal:(UIImage *)image2
{
    if (image1 == image2)
    {
        return YES;
    }
    if (image1 && image2)
    {
        NSData *data1 = UIImagePNGRepresentation(image1);
        NSData *data2 = UIImagePNGRepresentation(image2);
        BOOL result = [data1 isEqual:data2];
        return result;
    }
    return NO;
}

- (BOOL)shouldShowFakeWithViewController:(UIViewController *)vc from:(UIViewController *)from  to:(UIViewController *)to
{
    if (vc != to )
    {
        return NO;
    }
    
    // 都有图片，并且是同一张图片
    if (from.dj_NavigationBarImage && to.dj_NavigationBarImage && [self isImage:from.dj_NavigationBarImage equal:to.dj_NavigationBarImage])
    {
        // 透明度相似
        if (ABS(from.dj_NavigationBarAlpha - to.dj_NavigationBarAlpha) > 0.1f)
        {
            return YES;
        }
        return NO;
    }
    // 都没图片，并且颜色相同
    else if (!from.dj_NavigationBarImage && !to.dj_NavigationBarImage && [from.dj_NavigationBarBgTintColor.description isEqual:to.dj_NavigationBarBgTintColor.description])
    {
        // 透明度相似
        if (ABS(from.dj_NavigationBarAlpha - to.dj_NavigationBarAlpha) > 0.1f)
        {
            return YES;
        }
        return NO;
    }
    
    return YES;
}

- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    id <UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
    if (coordinator && [coordinator initiallyInteractive])
    {
        [coordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext> context) {
            //NSog(@"%@", @([context isCancelled]));
            self.duringPopAnimation = NO;
        }];
    }
    else
    {
        self.duringPopAnimation = NO;
    }
    
    if (coordinator)
    {
        UIViewController *from = [coordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
        UIViewController *to = [coordinator viewControllerForKey:UITransitionContextToViewControllerKey];
        [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            BOOL shouldFake = [self shouldShowFakeWithViewController:viewController from:from to:to];
            if (shouldFake)
            {
                if (self.inGesture)
                {
                    self.navigationBar.barStyle = viewController.dj_NavigationBarStyle;
                    self.navigationBar.tintColor = viewController.dj_NavigationBarTintColor;
                }

                [UIView performWithoutAnimation:^{
                    self.navigationBar.effectView.alpha = 0.0f;
                    self.navigationBar.backgroundImageView.alpha = 0.0f;
                    self.navigationBar.shadowLineImageView.alpha = 0.0f;
                    
                    // fromVC
                    if (from.dj_NavigationBarImage)
                    {
                        self.fromFakeImageView.image = from.dj_NavigationBarImage;
                        self.fromFakeImageView.alpha = from.dj_NavigationBarAlpha;
                        self.fromFakeImageView.frame = [self fakeBarFrameForViewController:from];
                        [from.view addSubview:self.fromFakeImageView];
                    }
                    else
                    {
                        self.fromFakeBar.contentView.backgroundColor = from.dj_NavigationBarBgTintColor;
                        self.fromFakeBar.effect = from.dj_NavigationBarEffect;
                        self.fromFakeBar.alpha = from.dj_NavigationBarAlpha == 0 ? 0.01f : from.dj_NavigationBarAlpha;
                        if (from.dj_NavigationBarAlpha == 0)
                        {
                            self.fromFakeBar.contentView.alpha = 0.01f;
                        }
                        self.fromFakeBar.frame = [self fakeBarFrameForViewController:from];
                        [from.view addSubview:self.fromFakeBar];
                    }
                    
                    self.fromFakeShadow.alpha = from.dj_NavigationShadowAlpha;
                    self.fromFakeShadow.backgroundColor = from.dj_NavigationShadowColor;
                    self.fromFakeShadow.frame = [self fakeShadowFrameWithBarFrame:self.fromFakeBar.frame];
                    [from.view addSubview:self.fromFakeShadow];
                    
                    // toVC
                    if (to.dj_NavigationBarImage)
                    {
                        self.toFakeImageView.image = to.dj_NavigationBarImage;
                        self.toFakeImageView.alpha = to.dj_NavigationBarAlpha;
                        self.toFakeImageView.frame = [self fakeBarFrameForViewController:to];
                        [to.view addSubview:self.toFakeImageView];
                    }
                    else
                    {
                        self.toFakeBar.contentView.backgroundColor = to.dj_NavigationBarBgTintColor;
                        self.toFakeBar.effect = to.dj_NavigationBarEffect;
                        self.toFakeBar.alpha = to.dj_NavigationBarAlpha;
                        self.toFakeBar.frame = [self fakeBarFrameForViewController:to];
                        [to.view addSubview:self.toFakeBar];
                    }
                    
                    self.toFakeShadow.alpha = to.dj_NavigationShadowAlpha;
                    self.toFakeShadow.backgroundColor = to.dj_NavigationShadowColor;
                    self.toFakeShadow.frame = [self fakeShadowFrameWithBarFrame:self.toFakeBar.frame];
                    [to.view addSubview:self.toFakeShadow];
                }];
            }
            else
            {
                [self updateNavigationBarForController:viewController];
            }
        } completion:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
            if (context.isCancelled)
            {
                [self updateNavigationBarForController:from];
            }
            else
            {
                // 当 present 时 to 不等于 viewController
                [self updateNavigationBarForController:viewController];
            }
            
            if (to == viewController)
            {
                [self clearFake];
            }
        }];
        
        if (@available(iOS 10.0, *)) {
            [coordinator notifyWhenInteractionChangesUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                if (!context.isCancelled && self.inGesture) {
                    self.navigationBar.barStyle = viewController.dj_NavigationBarStyle;
                    self.navigationBar.tintColor = viewController.dj_NavigationBarTintColor;
                }
            }];
        } else {
            [coordinator notifyWhenInteractionEndsUsingBlock:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
                if (!context.isCancelled && self.inGesture) {
                    self.navigationBar.barStyle = viewController.dj_NavigationBarStyle;
                    self.navigationBar.tintColor = viewController.dj_NavigationBarTintColor;
                }
            }];
        }
    }
    else
    {
        [self updateNavigationBarForController:viewController];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated
{
    NSCAssert(self.interactivePopGestureRecognizer.delegate == self, @"DJNavigationController won't work correctly if you change interactivePopGestureRecognizer's delegate.");
    
    self.duringPushAnimation = NO;
    self.duringPopAnimation = NO;
    
    if ([self.realDelegate respondsToSelector:_cmd])
    {
        [self.realDelegate navigationController:navigationController didShowViewController:viewController animated:animated];
    }
}

- (UIVisualEffectView *)fromFakeBar
{
    if (!_fromFakeBar)
    {
        _fromFakeBar = [[UIVisualEffectView alloc] initWithEffect:DJNavigationBar_DefaultEffect];
    }
    return _fromFakeBar;
}

- (UIVisualEffectView *)toFakeBar
{
    if (!_toFakeBar)
    {
        _toFakeBar = [[UIVisualEffectView alloc] initWithEffect:DJNavigationBar_DefaultEffect];
    }
    return _toFakeBar;
}

- (UIImageView *)fromFakeImageView
{
    if (!_fromFakeImageView) {
        _fromFakeImageView = [[UIImageView alloc] init];
    }
    return _fromFakeImageView;
}

- (UIImageView *)toFakeImageView
{
    if (!_toFakeImageView) {
        _toFakeImageView = [[UIImageView alloc] init];
    }
    return _toFakeImageView;
}

- (UIImageView *)fromFakeShadow
{
    if (!_fromFakeShadow)
    {
        _fromFakeShadow = [[UIImageView alloc] initWithImage:self.navigationBar.shadowLineImageView.image];
        _fromFakeShadow.backgroundColor = self.navigationBar.shadowLineImageView.backgroundColor;
    }
    return _fromFakeShadow;
}

- (UIImageView *)toFakeShadow
{
    if (!_toFakeShadow)
    {
        _toFakeShadow = [[UIImageView alloc] initWithImage:self.navigationBar.shadowLineImageView.image];
        _toFakeShadow.backgroundColor = self.navigationBar.shadowLineImageView.backgroundColor;
    }
    return _toFakeShadow;
}

- (void)clearFake
{
    if (self.fromFakeBar.superview)
    {
        [self.fromFakeBar removeFromSuperview];
    }
    if (self.toFakeBar.superview)
    {
        [self.toFakeBar removeFromSuperview];
    }
    if (self.fromFakeShadow.superview)
    {
        [self.fromFakeShadow removeFromSuperview];
    }
    if (self.toFakeShadow.superview)
    {
        [self.toFakeShadow removeFromSuperview];
    }
    if (self.fromFakeImageView.superview)
    {
        [self.fromFakeImageView removeFromSuperview];
    }
    if (self.toFakeImageView.superview)
    {
        [self.toFakeImageView removeFromSuperview];
    }

    self.fromFakeBar = nil;
    self.toFakeBar = nil;
    self.fromFakeShadow = nil;
    self.toFakeShadow = nil;
    self.fromFakeImageView = nil;
    self.toFakeImageView = nil;
}

- (CGRect)fakeBarFrameForViewController:(UIViewController *)vc
{
    CGRect frame = [self.navigationBar.effectView convertRect:self.navigationBar.effectView.frame toView:vc.view];
    frame.origin.x = vc.view.frame.origin.x;
    
//    // 解决根视图为scrollView的时候，Push不正常
//    if ([vc.view isKindOfClass:[UIScrollView class]])
//    {
//        // 适配iPhoneX
//        frame.origin.y = -([UIScreen mainScreen].bounds.size.height == 812.0 ? 88 : 64);
//    }
    
    return frame;
}

- (CGRect)fakeShadowFrameWithBarFrame:(CGRect)frame
{
    return CGRectMake(frame.origin.x, frame.size.height + frame.origin.y - 1.0f/[UIScreen mainScreen].scale, frame.size.width, 1.0f/[UIScreen mainScreen].scale);
}

- (void)handlePopGesture:(UIScreenEdgePanGestureRecognizer *)recognizer
{
    id<UIViewControllerTransitionCoordinator> coordinator = self.transitionCoordinator;
    UIViewController *from = [coordinator viewControllerForKey:UITransitionContextFromViewControllerKey];
    UIViewController *to = [coordinator viewControllerForKey:UITransitionContextToViewControllerKey];
    if (recognizer.state == UIGestureRecognizerStateBegan || recognizer.state == UIGestureRecognizerStateChanged)
    {
        self.inGesture = YES;
        self.navigationBar.tintColor = blendColor(from.dj_NavigationBarTintColor, to.dj_NavigationBarTintColor, coordinator.percentComplete);
    } else {
        self.inGesture = NO;
    }
}


#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    if (self.viewControllers.count <= 1)
    {
        return NO;
    }
    // 私有变量标志transition动画是否正在进行
    // 后面可以不判断 !self.isDuringPushAnimation && !self.isDuringPopAnimation
    if ([[self valueForKey:@"_isTransitioning"] boolValue])
    {
        return NO;
    }
    
    if (gestureRecognizer == self.interactivePopGestureRecognizer)
    {
        // Disable pop gesture in two situations:
        // 1) when the pop animation is in progress
        // 2) when user swipes quickly a couple of times and animations don't have time to be performed
        // 3) 页面VC 支持返回手势
        BOOL canGesture = self.topViewController.dj_CanBackInteractive;
        if (canGesture && !self.isDuringPushAnimation && !self.isDuringPopAnimation)
        {
            return YES;
        }
        
        return NO;
    }
    else
    {
        // default value
        return YES;
    }
}

#pragma mark - Delegate Forwarder

// Thanks for the idea goes to: https://github.com/steipete/PSPDFTextView/blob/ee9ce04ad04217efe0bc84d67f3895a34252d37c/PSPDFTextView/PSPDFTextView.m#L148-164

- (BOOL)respondsToSelector:(SEL)sel
{
    return [super respondsToSelector:sel] || [self.realDelegate respondsToSelector:sel];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel
{
    return [super methodSignatureForSelector:sel] ?: [(id)self.realDelegate methodSignatureForSelector:sel];
}

- (void)forwardInvocation:(NSInvocation *)invocation
{
    id delegate = self.realDelegate;
    if ([delegate respondsToSelector:invocation.selector])
    {
        [invocation invokeWithTarget:delegate];
    }
}


#pragma mark -
#pragma mark actions

- (void)updateNavigationBarForController:(UIViewController *)vc
{
    [self updateNavigationBarStyleForViewController:vc];

    [self updateNavigationBarEffectForViewController:vc];

    [self updateNavigationBarImageForViewController:vc];

    //[self updateNavigationBarAlphaForViewController:vc];
    [self updateNavigationBarBgTintColorForViewController:vc];
    
    [self updateNavigationShadowAlphaForViewController:vc];
    [self updateNavigationShadowColorForViewController:vc];
    
    [self updateNavigationBarTintColorForViewController:vc];
}

- (void)updateNavigationBarStyleForViewController:(UIViewController *)vc
{
    self.navigationBar.barStyle = vc.dj_NavigationBarStyle;
    self.navigationBar.barTintColor = vc.dj_NavigationBarBgTintColor;
}

- (void)updateNavigationBarAlphaForViewController:(UIViewController *)vc
{
    if (vc.dj_NavigationBarImage)
    {
        self.navigationBar.effectView.alpha = 0.0f;
        self.navigationBar.backgroundImageView.alpha = vc.dj_NavigationBarAlpha;
    }
    else
    {
        self.navigationBar.effectView.alpha = vc.dj_NavigationBarAlpha;
        self.navigationBar.backgroundImageView.alpha = 0.0f;
    }

    self.navigationBar.shadowLineImageView.alpha = vc.dj_NavigationShadowAlpha;
    self.navigationBar.barTintColor = vc.dj_NavigationBarBgTintColor;
}

- (void)updateNavigationBarBgTintColorForViewController:(UIViewController *)vc
{
    self.navigationBar.barTintColor = vc.dj_NavigationBarBgTintColor;
}

- (void)updateNavigationBarEffectForViewController:(UIViewController *)vc
{
    self.navigationBar.effect = vc.dj_NavigationBarEffect;
}

- (void)updateNavigationBarImageForViewController:(UIViewController *)vc
{
    [self.navigationBar setBackgroundImage:vc.dj_NavigationBarImage];
    [self updateNavigationBarAlphaForViewController:vc];
}

- (void)updateNavigationShadowAlphaForViewController:(UIViewController *)vc
{
    self.navigationBar.shadowLineImageView.alpha = vc.dj_NavigationShadowAlpha;
    self.navigationBar.shadowLineImageView.backgroundColor = vc.dj_NavigationShadowColor;
}

- (void)updateNavigationShadowColorForViewController:(UIViewController *)vc
{
    self.navigationBar.shadowLineImageView.backgroundColor = vc.dj_NavigationShadowColor;
}

- (void)updateNavigationBarTintColorForViewController:(UIViewController *)vc
{
    self.navigationBar.tintColor = vc.dj_NavigationBarTintColor;
}

@end
