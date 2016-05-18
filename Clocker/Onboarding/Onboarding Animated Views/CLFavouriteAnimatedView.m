//
//  CLFavouriteAnimatedView.m
//
//  Code generated using QuartzCode 1.39.17 on 5/16/16.
//  www.quartzcodeapp.com
//

#import "CLFavouriteAnimatedView.h"
#import "QCMethod.h"

@interface CLFavouriteAnimatedView ()

@property (nonatomic, strong) NSMutableDictionary * layers;


@end

@implementation CLFavouriteAnimatedView

#pragma mark - Life Cycle

- (instancetype)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self) {
		[self setupProperties];
		[self setupLayers];
	}
	return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self) {
		[self setupProperties];
		[self setupLayers];
	}
	return self;
}



- (void)setupProperties{
	self.layers = [NSMutableDictionary dictionary];
	
}

- (void)setupLayers{
	[self setWantsLayer:YES];
	
	CALayer * ScreenShot20160515at113112PM = [CALayer layer];
	ScreenShot20160515at113112PM.frame    = CGRectMake(0, -115, 400, 358.62);
	ScreenShot20160515at113112PM.contents = [NSImage imageNamed:@"Screen Shot 2016-05-15 at 11.31.12 PM"];
	[self.layer addSublayer:ScreenShot20160515at113112PM];
	self.layers[@"ScreenShot20160515at113112PM"] = ScreenShot20160515at113112PM;
	
	CAShapeLayer * rectangle = [CAShapeLayer layer];
	rectangle.frame       = CGRectMake(63, 140, 10, 11);
	rectangle.fillColor   = [NSColor blueColor].CGColor;
	rectangle.strokeColor = [NSColor colorWithRed:0.329 green: 0.329 blue:0.329 alpha:1].CGColor;
	rectangle.path        = [self rectanglePath].quartzPath;
	[self.layer addSublayer:rectangle];
	self.layers[@"rectangle"] = rectangle;
	
	CALayer * MenuBar = [CALayer layer];
	MenuBar.frame           = CGRectMake(85, 261, 296, 23);
	MenuBar.masksToBounds   = YES;
	MenuBar.contents        = [NSImage imageNamed:@"MenuBar"];
	MenuBar.contentsGravity = kCAGravityResizeAspect;
	[self.layer addSublayer:MenuBar];
	self.layers[@"MenuBar"] = MenuBar;
}



#pragma mark - Animation Setup

- (void)addUntitled1Animation{
	NSString * fillMode = kCAFillModeForwards;
	
	////Rectangle animation
	CAKeyframeAnimation * rectangleFillColorAnim = [CAKeyframeAnimation animationWithKeyPath:@"fillColor"];
	rectangleFillColorAnim.values         = @[(id)[NSColor whiteColor].CGColor, 
		 (id)[NSColor colorWithRed:0.263 green: 0.541 blue:0.98 alpha:1].CGColor];
	rectangleFillColorAnim.keyTimes       = @[@0, @1];
	rectangleFillColorAnim.duration       = 1;
	rectangleFillColorAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	
	CAAnimationGroup * rectangleUntitled1Anim = [QCMethod groupAnimations:@[rectangleFillColorAnim] fillMode:fillMode];
	[self.layers[@"rectangle"] addAnimation:rectangleUntitled1Anim forKey:@"rectangleUntitled1Anim"];
	
	////MenuBar animation
	CAKeyframeAnimation * MenuBarHiddenAnim = [CAKeyframeAnimation animationWithKeyPath:@"hidden"];
	MenuBarHiddenAnim.values         = @[@YES, @NO];
	MenuBarHiddenAnim.keyTimes       = @[@0, @1];
	MenuBarHiddenAnim.duration       = 2.82;
	MenuBarHiddenAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	
	CAAnimationGroup * MenuBarUntitled1Anim = [QCMethod groupAnimations:@[MenuBarHiddenAnim] fillMode:fillMode];
	[self.layers[@"MenuBar"] addAnimation:MenuBarUntitled1Anim forKey:@"MenuBarUntitled1Anim"];
}

#pragma mark - Animation Cleanup

- (void)updateLayerValuesForAnimationId:(NSString *)identifier{
	if([identifier isEqualToString:@"Untitled1"]){
		[QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"rectangle"] animationForKey:@"rectangleUntitled1Anim"] theLayer:self.layers[@"rectangle"]];
		[QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"MenuBar"] animationForKey:@"MenuBarUntitled1Anim"] theLayer:self.layers[@"MenuBar"]];
	}
}

- (void)removeAnimationsForAnimationId:(NSString *)identifier{
	if([identifier isEqualToString:@"Untitled1"]){
		[self.layers[@"rectangle"] removeAnimationForKey:@"rectangleUntitled1Anim"];
		[self.layers[@"MenuBar"] removeAnimationForKey:@"MenuBarUntitled1Anim"];
	}
}

- (void)removeAllAnimations{
	[self.layers enumerateKeysAndObjectsUsingBlock:^(id key, CALayer *layer, BOOL *stop) {
		[layer removeAllAnimations];
	}];
}

#pragma mark - Bezier Path

- (NSBezierPath*)rectanglePath{
	NSBezierPath * rectanglePath = [NSBezierPath bezierPathWithRect:CGRectMake(0, 0, 10, 11)];
	return rectanglePath;
}


@end
