//
//  UIButton+Transform.m
//  Camera
//
//  Created by 冯 传祥 on 16/1/26.
//  Copyright © 2016年 冯 传祥. All rights reserved.
//

#import "UIButton+Transform.h"
#import <objc/runtime.h>

@implementation UIButton (Transform)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [self swizzleInstanceMethodWithClass:[self class] originalSelector:@selector(sendAction:to:forEvent:) swizzledMethod:@selector(fcxSendAction:to:forEvent:)];
    });
}

- (void)fcx_AddTarget:(nullable id)target action:(SEL)action forControlEvents:(UIControlEvents)controlEvents {
    if (controlEvents == UIControlEventTouchUpInside) {
        
    }
}

- (void)fcxSendAction:(SEL)action to:(id)target forEvent:(UIEvent *)event {
//    NSLog(@"event %@", event);
//    NSLog(@"type %d subtype %d", event.type, event.subtype);
    UITouch *touch = [event.allTouches anyObject];

    if (touch.phase == UITouchPhaseBegan) {
        self.transform = CGAffineTransformMakeScale(1.2, 1.2);
//        NSLog(@"begain=====");
    }else if (touch.phase == UITouchPhaseMoved) {
//        NSLog(@"moved");
    }else if (touch.phase == UITouchPhaseEnded) {
        self.transform = CGAffineTransformIdentity;

//        NSLog(@"end");
    }else if (touch.phase == UITouchPhaseCancelled) {
//        NSLog(@"cancel");
    }else if(touch.phase == UITouchPhaseStationary) {
//        NSLog(@"station");
        
    }
//    
//    NSLog(@"==============all%@", event.allTouches);
//    NSLog(@"==============all%@", [event touchesForWindow:[UIApplication sharedApplication].keyWindow]);
//    NSLog(@"==============all%@", [event touchesForView:self.superview]);

    [self fcxSendAction:action to:target forEvent:event];
}

+ (void)swizzleInstanceMethodWithClass:(Class)class
                      originalSelector:(SEL)originalSelector
                        swizzledMethod:(SEL)swizzledSelector {
    
    Method originalMethod = class_getInstanceMethod(class, originalSelector);
    Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
    
    if (class_addMethod(class, originalSelector, method_getImplementation(swizzledMethod), method_getTypeEncoding(swizzledMethod))) {
        
        class_replaceMethod(class, swizzledSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
    }else {
        
        method_exchangeImplementations(originalMethod, swizzledMethod);
    }
}

- (BOOL)needTransform {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setNeedTransform:(BOOL)needTransform {
    if (needTransform == YES) {
        [self addTarget:self action:@selector(fcx_touchEvent) forControlEvents:UIControlEventTouchDown];
        [self addTarget:self action:@selector(fcx_touchEvent) forControlEvents:UIControlEventTouchUpOutside];
    }
    objc_setAssociatedObject(self, @selector(needTransform), [NSNumber numberWithBool:needTransform], OBJC_ASSOCIATION_ASSIGN);
}

- (void)fcx_touchEvent {

}

@end
