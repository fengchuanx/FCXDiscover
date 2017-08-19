//
//  FCXWebViewController.h
//  Bells
//
//  Created by 冯 传祥 on 16/1/17.
//  Copyright (c) 2016年 冯 传祥. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FCXWebViewController : UIViewController

@property (nonatomic, copy) NSString *urlString;
@property (nonatomic, copy) NSString *admobID;
@property (nonatomic, strong) UIColor *navBackColor;//!<导航条返回按钮颜色（没有默认取导航条的tinColor，再取不到为blackColor）

@end
