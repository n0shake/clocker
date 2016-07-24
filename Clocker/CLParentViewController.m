//
//  CLParentViewController.m
//  Clocker
//
//  Created by Abhishek Banthia on 7/18/16.
//
//

#import "CLParentViewController.h"

@interface CLParentViewController ()

@end

@implementation CLParentViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    
    CALayer *viewLayer = [CALayer layer];
    viewLayer.backgroundColor = CGColorCreateGenericRGB(255.0, 255.0, 255.0, 0.8); //RGB plus Alpha Channel
    [self.view setWantsLayer:YES];
    (self.view).layer = viewLayer;
}

@end
