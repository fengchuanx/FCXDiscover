//
//  FCXDiscoverViewController.m
//  FCXUniversial
//
//  Created by 冯 传祥 on 16/3/29.
//  Copyright © 2016年 冯 传祥. All rights reserved.
//

#import "FCXDiscoverViewController.h"
#import "UIImageView+WebCache.h"
#import "FCXRating.h"
#import "FCXWebViewController.h"
#import "UIButton+Transform.h"
#import "FCXOnlineConfig.h"
#import "FCXDefine.h"
#import "UMMobClick/MobClick.h"
#import "UIViewController+Admob.h"
#import "GDTCustomView.h"
#import "UIView+Frame.h"
#import "UIButton+Block.h"

#define IMAGE_WIDTH 40

@interface FCXDiscoverButton : UIButton

@property (nonatomic, strong) UIImageView *iconImageView;
@property (nonatomic, strong) NSDictionary *data;
@property (nonatomic, weak) FCXDiscoverViewController *controller;

@end

@implementation FCXDiscoverButton

- (UIImageView *)iconImageView {
    if (!_iconImageView) {
        _iconImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - IMAGE_WIDTH)/2.0, (self.frame.size.width - IMAGE_WIDTH)/2.0 - 10, IMAGE_WIDTH,  IMAGE_WIDTH)];
        _iconImageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_iconImageView];
        
        [self addTarget:self action:@selector(buttonAction) forControlEvents:UIControlEventTouchUpInside];
    }
    return _iconImageView;
}

- (void)setData:(NSDictionary *)data {
    if (_data != data) {
        _data = data;
        [self setTitle:data[@"title"] forState:UIControlStateNormal];
        [self.iconImageView sd_setImageWithURL:[NSURL URLWithString:data[@"icon"]]];
    }
}

- (void)buttonAction {
    [MobClick event:@"发现" label:self.data[@"title"]];
    NSString *url = self.data[@"url"];
    if (url && url.length > 0) {//h5
        FCXWebViewController *webView = [[FCXWebViewController alloc] init];
        webView.hidesBottomBarWhenPushed = YES;
        webView.urlString = url;
        webView.admobID = [FCXOnlineConfig fcxGetConfigParams:@"AdmobID" defaultValue:self.controller.admobID];
        webView.title = self.data[@"title"];
        [self.controller.navigationController pushViewController:webView animated:YES];
    }else {
        [FCXRating goAppStore:self.data[@"appid"]];
    }
}

@end



@interface FCXDiscoverViewController ()
{
    CGFloat _offsetY;
    NSString *_adName;
    GDTCustomView *_adView;
}
@property (nonatomic, strong) UIButton *adBtn;

@end

@implementation FCXDiscoverViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = UICOLOR_FROMRGB(0xf5f5f5);
    self.title = @"发现";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self showAllGroups];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_adView startTimer];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_adView stopTimer];
}

- (void)showAllGroups {
       CGFloat tabBarHeight = 0;
    if (self.tabBarController) {
        tabBarHeight = 49;
    }
    
    CGFloat topHeight = 64;
    if ([UIApplication sharedApplication].statusBarHidden) {
        topHeight = 44;
    }
    
    CGFloat adHeight = 0;
    if ([[FCXOnlineConfig fcxGetConfigParams:@"showAdmobDiscover" defaultValue:@"0"] boolValue]) {
        adHeight = 50;
        [self showAdmobBanner:CGRectMake(0, SCREEN_HEIGHT - topHeight - 50 - tabBarHeight, SCREEN_WIDTH, 50) adUnitID:[FCXOnlineConfig fcxGetConfigParams:@"AdmobID" defaultValue:self.admobID]];
    }
    
    _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT - topHeight - adHeight - tabBarHeight)];
    _scrollView.userInteractionEnabled = YES;
    _scrollView.backgroundColor = self.view.backgroundColor;
    _scrollView.showsVerticalScrollIndicator = NO;
    [self.view addSubview:_scrollView];
    
    _scrollView.contentInset = UIEdgeInsetsMake(0, 0, adHeight * 2, 0);
    
    _offsetY = 10 + _topSpace;
    int groupCount = [[FCXOnlineConfig fcxGetConfigParams:@"discover_groupCount"] intValue];
    if (groupCount > 0) {
        for (int i = 1; i <= groupCount; i++) {
            NSString *str = [@"discover_g" stringByAppendingFormat:@"%d", i];
            NSDictionary *dict = [FCXOnlineConfig fcxGetJSONConfigParams:str];
            if ([dict isKindOfClass:[NSDictionary class]]) {
                [self addGroup:dict];
            }
        }
    }
    
    _scrollView.contentSize = CGSizeMake(_scrollView.width, MAX(_scrollView.height + .3, _offsetY));
    
    [self setupGroup3];
}

- (void)addGroup:(NSDictionary *)dict {
    NSInteger row;
    NSArray *array = dict[@"data"];
    NSString *title = dict[@"title"];
    NSString *subTitle = dict[@"subTitle"];
    
    if (array.count %4 == 0) {
        row = array.count/4;
    }else {
        row = array.count/4 + 1;
    }
    CGFloat width = SCREEN_WIDTH/4.0;
    
    UIView *bgView = [[UIView alloc] initWithFrame:CGRectMake(0, _offsetY, SCREEN_WIDTH, 35 + row * width)];
    bgView.backgroundColor = [UIColor whiteColor];
    bgView.layer.borderWidth = .5;
    bgView.layer.borderColor = UICOLOR_FROMRGB(0xd9d9d9).CGColor;
    [_scrollView addSubview:bgView];
    
    _offsetY += (bgView.height + 10);
    
    UILabel*titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, bgView.width, 35)];
    titleLabel.font = DEFAULTFONT(14);
    titleLabel.textColor = UICOLOR_FROMRGB(0x343233);
    [bgView addSubview:titleLabel];
    
    if (subTitle.length > 0) {
        NSString *str = [NSString stringWithFormat:@"%@  %@", title, subTitle];
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:str];
        NSRange range1 = NSMakeRange(0, title.length);
        NSRange range2 = NSMakeRange(title.length, str.length - title.length);
        
        [attributedString addAttribute:NSForegroundColorAttributeName value:UICOLOR_FROMRGB(0x343233) range:range1];
        [attributedString addAttribute:NSForegroundColorAttributeName value:UICOLOR_FROMRGB(0x7e7e7e) range:range2];
        [attributedString addAttribute:NSFontAttributeName value:DEFAULTFONT(14) range:range1];
        [attributedString addAttribute:NSFontAttributeName value:DEFAULTFONT(13) range:range2];
        titleLabel.attributedText = attributedString;
    } else {
        titleLabel.text = title;
    }
    
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(0, 34.5, bgView.width, .5)];
    line.backgroundColor = UICOLOR_FROMRGB(0xd9d9d9);
    [bgView addSubview:line];
    
    [array enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        FCXDiscoverButton *btn = [FCXDiscoverButton buttonWithType:UIButtonTypeCustom];
        btn.controller = self;
        btn.needTransform = YES;
        btn.frame = CGRectMake((idx%4) * width, titleLabel.bottom + (idx/4) * width, width, width);
        btn.backgroundColor = [UIColor clearColor];
        [btn setTitleColor:UICOLOR_FROMRGB(0x343233) forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.5];
        btn.titleEdgeInsets = UIEdgeInsetsMake((width - IMAGE_WIDTH)/2 + 20, 0, 0, 0);
        btn.data = obj;
        [bgView addSubview:btn];
    }];
}

- (void)setupGroup3 {
    
    NSDictionary *dict = [FCXOnlineConfig fcxGetJSONConfigParams:@"discover_ad"];
    //    dict = @{@"type" : @"1", @"adName" : @"aa", @"des" : @"deasdf", @"appID":@"12345", @"imgURL": @"http://t.cn/RcyXwEw", @"url" : @"http://jump.luna.58.com/i/290p", @"title": @"网页标题"};
    if (!dict || ![dict isKindOfClass:[NSDictionary class]]) {
        return;
    }
    if ([dict[@"type"] integerValue] == 0) {//不显示
        return;
    }
    
    _adName = dict[@"adName"];
    if ([dict[@"type"] integerValue] == 1) {//自定义广告
        [self setupADView:dict[@"des"] imgUrl:dict[@"imgURL"]];
        __weak typeof(self) weakSelf = self;
        
        [self.adBtn defaultControlEventsWithHandler:^(UIButton *button) {
            [MobClick event:@"发现" label:@"点击自定义广告"];
            NSString *url = dict[@"url"];
            if (url && url.length > 0) {
                FCXWebViewController *webView = [[FCXWebViewController alloc] init];
                webView.hidesBottomBarWhenPushed = YES;
                webView.urlString = url;
                webView.admobID = [FCXOnlineConfig fcxGetConfigParams:@"AdmobID" defaultValue:weakSelf.admobID];
                webView.title = dict[@"title"];
                [weakSelf.navigationController pushViewController:webView animated:YES];
            } else {
                [FCXRating goAppStore:dict[@"appID"]];
            }
        }];
        return;
    }
    
    //广点通
    NSDictionary *gdtDict = [FCXOnlineConfig fcxGetJSONConfigParams:@"GDT_Info"];
    if([gdtDict isKindOfClass:[NSDictionary class]]){
        NSString *appkey = gdtDict[@"appkey"];;
        NSString *placementId = gdtDict[@"placementId"];
        
        _adView = [[GDTCustomView alloc] initWithFrame:CGRectMake(0, _offsetY, SCREEN_WIDTH, 0) appkey:appkey placementId:placementId controller:self adName:_adName];
        _adView.backgroundColor = [UIColor whiteColor];
        _adView.layer.borderWidth = .5;
        _adView.layer.borderColor = UICOLOR_FROMRGB(0xd9d9d9).CGColor;
        [_scrollView addSubview:_adView];
        
        __weak UIScrollView *weakScrollView = _scrollView;
        _adView.loadFinishBlock = ^(CGFloat height) {
            weakScrollView.contentSize = CGSizeMake(weakScrollView.width, MAX(_offsetY + height, weakScrollView.height + .5));
        };
    }
}

- (void)setupADView:(NSString *)des imgUrl:(NSString *)imgUrl {
    CGFloat space = 15;
    //推广
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(space, space, 30, 16)];
    label.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:11];
    label.textColor = [UIColor blackColor];
    label.backgroundColor = [UIColor clearColor];
    label.layer.cornerRadius = 3;
    label.clipsToBounds = YES;
    label.layer.borderColor = UICOLOR_FROMRGB(0x888888).CGColor;
    label.layer.borderWidth = .5;
    label.text = _adName;
    label.textAlignment = NSTextAlignmentCenter;
    [self.adBtn addSubview:label];
    
    //标题
    UILabel *_titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(label.right + 5, label.top, SCREEN_WIDTH - label.right - space * 2 - 12, 16)];
    _titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];
    _titleLabel.text = des;
    [_adBtn addSubview:_titleLabel];
    
    UIImageView *arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(SCREEN_WIDTH - 12 - space, _titleLabel.top, 12, 16)];
    arrowImageView.image = [UIImage imageNamed:@"ad_arrow"];
    [_adBtn addSubview:arrowImageView];
    
    UIImageView *_imageView = [[UIImageView alloc] init];
    _imageView.layer.shouldRasterize = YES;
    _imageView.clipsToBounds = YES;
    _imageView.contentMode = UIViewContentModeScaleAspectFill;
    [_adBtn addSubview:_imageView];
    
    [_imageView sd_setImageWithURL:[NSURL URLWithString:imgUrl ? imgUrl : @""] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        
        CGFloat height = image.size.height * ((SCREEN_WIDTH - space * 2)/image.size.width);
        
        _imageView.frame = CGRectMake(space, _titleLabel.bottom + 5, SCREEN_WIDTH - space * 2, height);
        
        _adBtn.frame = CGRectMake(0, _offsetY, SCREEN_WIDTH, 16 + 5 + height + space * 2);
        _scrollView.contentSize = CGSizeMake(_scrollView.width, _offsetY + _adBtn.height);
    }];
}

- (UIButton *)adBtn {
    if (!_adBtn) {
        _adBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _adBtn.backgroundColor = [UIColor whiteColor];
        _adBtn.layer.borderWidth = .5;
        _adBtn.layer.borderColor = UICOLOR_FROMRGB(0xd9d9d9).CGColor;
    }
    [_scrollView addSubview:_adBtn];
    return _adBtn;
}

@end
