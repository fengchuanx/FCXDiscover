//
//  FCXDiscoverViewController.h
//  FCXUniversial
//
//  Created by 冯 传祥 on 16/3/29.
//  Copyright © 2016年 冯 传祥. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCXDiscoverViewController : UIViewController

@property (nonatomic, copy) NSString *admobID;
@property (nonatomic, strong) UIColor *navBackColor;//!<导航条返回按钮颜色（没有默认取导航条的tinColor，再取不到为blackColor）
@property (nonatomic, strong, readonly) UIScrollView *scrollView;
@property (nonatomic, unsafe_unretained) CGFloat topSpace;

@end
