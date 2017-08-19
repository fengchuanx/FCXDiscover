//
//  FCXWebViewController.m
//  Bells
//
//  Created by 冯 传祥 on 16/1/17.
//  Copyright (c) 2016年 冯 传祥. All rights reserved.
//

#import "FCXWebViewController.h"
#import "FCXOnlineConfig.h"
#import "FCXDefine.h"
#import "UIViewController+Admob.h"
#import "FCXShareManager.h"
#import "UMMobClick/MobClick.h"

static const float FCXInitialProgressValue = 0.1f;
static const float FCXInteractiveProgressValue = 0.5f;
static const float FCXFinalProgressValue = 0.9f;

NSString *completeRPCURLPath = @"webviewprogressproxy:///complete";

@interface FCXWebViewController () <UIWebViewDelegate>
{
    NSUInteger _loadingCount;//Number of requests concurrently being handled
    NSUInteger _maxLoadCount;//Maximum number of load requests that was reached
    BOOL _interactive;//Load progress has reached the point where users may interact with the content
    UIProgressView *_progressView;
    
}
@property (nonatomic, strong) NSURL *currentURL;
@property (nonatomic, unsafe_unretained) float loadingProgress; //Between 0.0 and 1.0, the load progress of the current page

@property (nonatomic,strong) UIWebView *webView;
@property (nonatomic, copy) NSString *shareTitle;

@property (nonatomic, strong) UIBarButtonItem *backItem;
@property (nonatomic, strong) UIBarButtonItem *closeItem;



@end

@implementation FCXWebViewController

#pragma mark - 分享

-(void)shareAction:(UIButton *)button {
    FCXShareManager *shareManager = [FCXShareManager sharedManager];
    shareManager.presentedController = self;
    shareManager.shareTitle = self.shareTitle;
    shareManager.shareContent = self.urlString;
    shareManager.shareURL = self.urlString;
    NSDictionary *infoPlist = [[NSBundle mainBundle] infoDictionary];
    NSString *icon = [[infoPlist valueForKeyPath:@"CFBundleIcons.CFBundlePrimaryIcon.CFBundleIconFiles"] lastObject];
    shareManager.shareImage = [UIImage imageNamed:icon];
    
    [shareManager showInviteFriendsShareView];
    [MobClick event:@"发现分享" label:self.shareTitle];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.leftBarButtonItem = self.backItem;
    
    UIButton *rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightBtn setImage:[UIImage imageNamed:@"nav_more"] forState:UIControlStateNormal];
    //    [rightBtn setImage:[UIImage imageNamed:@"nav_more_h"] forState:UIControlStateHighlighted];
    rightBtn.frame = CGRectMake(0, 0, 60, 44);
    rightBtn.tag = 666;
    rightBtn.imageEdgeInsets = UIEdgeInsetsMake(0, 25, 0, 0);
    [rightBtn addTarget:self action:@selector(shareAction:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:rightBtn];
    self.navigationItem.rightBarButtonItem = rightItem;
    
    
    CGFloat adHeight = 0;
    if ([[FCXOnlineConfig fcxGetConfigParams:@"showAdmob" defaultValue:@"1"] boolValue]) {
        adHeight = 50;
        [self showAdmobBanner:CGRectMake(0, SCREEN_HEIGHT - 64 - 50, SCREEN_WIDTH, 50) adUnitID:[FCXOnlineConfig fcxGetConfigParams:@"AdmobID" defaultValue:self.admobID]];
    }
    
    self.webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - 64 - adHeight)];
    self.webView.delegate = self;
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
    [self.view addSubview:self.webView];
    
    _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, 3)];
    [self.view addSubview:_progressView];
    _progressView.progressTintColor = UICOLOR_FROMRGB(0x00bf12);
    _progressView.trackTintColor = [UIColor clearColor];
    //更改进度条高度
    _progressView.transform = CGAffineTransformMakeScale(1.0f, 1.5f);
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([request.URL.path isEqualToString:completeRPCURLPath]) {
        [self completeLoadingProgress];
        return NO;
    }
    
    BOOL isFragmentJump = NO;
    
    if (request.URL.fragment) {
        NSString *nonFragmentURL = [request.URL.absoluteString stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:request.URL.fragment] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:webView.request.URL.absoluteString];
    }
    
    BOOL isTopLevelNavigation = [request.mainDocumentURL isEqual:request.URL];
    BOOL isHTTP = [request.URL.scheme isEqualToString:@"http"] || [request.URL.scheme isEqualToString:@"https"];
    if (!isFragmentJump && isHTTP && isTopLevelNavigation && navigationType != UIWebViewNavigationTypeBackForward) {
        //Save the URL in the accessor property
        _currentURL = [request URL];
        [self resetLoadingProgress];
    }
    
    return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    _loadingCount++;
    _maxLoadCount = fmax(_maxLoadCount, _loadingCount);
    [self startProgress];
}

- (void)startProgress
{
    if (_loadingProgress < FCXInitialProgressValue) {
        self.loadingProgress = FCXInitialProgressValue;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    _shareTitle = [_webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    
    [self handleLoadRequestCompletion];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(nonnull NSError *)error {
    [self handleLoadRequestCompletion];
}

- (void)resetLoadingProgress
{
    _progressView.hidden = NO;
    _maxLoadCount = _loadingCount = 0;
    _interactive = NO;
    self.loadingProgress = 0.0;
}

- (void)incrementLoadingProgress
{
    float progress = self.loadingProgress;
    float maxProgress = _interactive ? FCXFinalProgressValue : FCXInteractiveProgressValue;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    
    progress += increment;
    progress = fmin(progress, maxProgress);
    self.loadingProgress = progress;
}

- (void)completeLoadingProgress
{
    self.loadingProgress = 1.0;
}

- (void)handleLoadRequestCompletion {
    _loadingCount--;
    [self incrementLoadingProgress];
    
    NSString *readyState = [self.webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    BOOL interactive = [readyState isEqualToString:@"interactive"];
    if (interactive) {
        _interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@://%@%@'; document.body.appendChild(iframe);  }, false);", self.webView.request.mainDocumentURL.scheme, self.webView.request.mainDocumentURL.host, completeRPCURLPath];
        NSLog(@"complete %@", waitForCompleteJS);
        
        waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", completeRPCURLPath];
        
        [self.webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = _currentURL && [_currentURL isEqual:self.webView.request.mainDocumentURL];
    BOOL complete = [readyState isEqualToString:@"complete"];
    
    if (complete && isNotRedirect) {
        [self completeLoadingProgress];
    }
}

- (void)setLoadingProgress:(float)loadingProgress {
    // progress should be incremental only
    if (loadingProgress > _loadingProgress || loadingProgress == 0) {
        _loadingProgress = loadingProgress;
    }
    if (_loadingProgress == 1) {
        [UIView animateWithDuration:.2 animations:^{
            [_progressView setProgress:_loadingProgress animated:NO];
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.55 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                _progressView.hidden = YES;
            });
        }];
        
    }else {
        [_progressView setProgress:_loadingProgress animated:YES];
        
        _progressView.hidden = NO;
    }
}

- (NSString *)shareTitle {
    if (_shareTitle) {
        return _shareTitle;
    }
    
    if (self.title) {
        return self.title;
    }
    return @"";
}

- (UIColor *)navBackColor {

    if (!_navBackColor) {
        if (self.navigationController.navigationBar.tintColor) {
            _navBackColor = self.navigationController.navigationBar.tintColor;
        } else {
            _navBackColor = [UIColor blackColor];
        }
    }
    return _navBackColor;
}

#pragma mark - 返回、关闭
- (UIImage *)backImage:(UIColor *)color {
    CGFloat lineWidth = 3;
    CGFloat width = 11 + lineWidth;
    CGFloat height = 18 + lineWidth;
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(context, color.CGColor);
    CGContextSetLineWidth(context, lineWidth);
    
    CGContextSetLineCap(context,
                        kCGLineCapSquare);
    
    
    CGContextBeginPath(context);//标记
    CGContextMoveToPoint(context,
                         width - lineWidth, lineWidth);//设置起点
    CGContextAddLineToPoint(context,
                            lineWidth, height/2.0);
    CGContextAddLineToPoint(context,
                            width - lineWidth, height - lineWidth);
    
    CGContextDrawPath(context,
                      kCGPathStroke);
    //    CGContextStrokePath(context);//绘画路径
    
    UIImage *theImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return theImage;
}

- (UIBarButtonItem *)backItem {
    if (!_backItem) {
        UIColor *normalColor = self.navBackColor;
        UIColor *highlightedColor = [normalColor colorWithAlphaComponent:.5];
        UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [backBtn setImage:[self backImage:normalColor] forState:UIControlStateNormal];
        [backBtn setImage:[self backImage:highlightedColor] forState:UIControlStateHighlighted];
        [backBtn setTitle:@"返回" forState:UIControlStateNormal];
        [backBtn setTitleColor:normalColor forState:UIControlStateNormal];
        [backBtn setTitleColor:highlightedColor forState:UIControlStateHighlighted];
        backBtn.frame = CGRectMake(0, 0, 50, 44);
        backBtn.imageEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0);
        backBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -5, 0, 0);
        [backBtn addTarget:self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
        backBtn.titleLabel.font = [UIFont systemFontOfSize:17];
        _backItem = [[UIBarButtonItem alloc] initWithCustomView:backBtn];
    }
    return _backItem;
}

- (UIBarButtonItem *)closeItem {
    if (!_closeItem) {
        UIColor *normalColor = self.navBackColor;
        UIColor *highlightedColor = [normalColor colorWithAlphaComponent:.5];

        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        closeBtn.frame = CGRectMake(0, 0, 50, 44);
        [closeBtn setTitleColor:normalColor forState:UIControlStateNormal];
        [closeBtn setTitleColor:highlightedColor forState:UIControlStateHighlighted];
        [closeBtn setTitle:@"关闭" forState:UIControlStateNormal];
        closeBtn.titleEdgeInsets = UIEdgeInsetsMake(0, -12, 0, 0);
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:16.5];
        [closeBtn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        _closeItem = [[UIBarButtonItem alloc] initWithCustomView:closeBtn];
    }
    return _closeItem;
}

- (void)backAction {
    if (_webView.canGoBack) {
        if (self.navigationItem.leftBarButtonItems.count < 2) {
            self.navigationItem.leftBarButtonItems = @[self.backItem, self.closeItem];
        }
        [_webView goBack];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)closeAction {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
