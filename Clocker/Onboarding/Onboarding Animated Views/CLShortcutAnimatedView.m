//
//  CLShortcutAnimatedView.m
//
//  Code generated using QuartzCode 1.39.17 on 5/16/16.
//  www.quartzcodeapp.com
//

#import "CLShortcutAnimatedView.h"
#import "QCMethod.h"

@interface CLShortcutAnimatedView ()

@property (nonatomic, strong) NSMutableDictionary * layers;
@property (nonatomic, strong) NSMapTable * completionBlocks;
@property (nonatomic, assign) BOOL  updateLayerValueForCompletedAnimation;


@end

@implementation CLShortcutAnimatedView

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
	self.completionBlocks = [NSMapTable mapTableWithKeyOptions:NSPointerFunctionsOpaqueMemory valueOptions:NSPointerFunctionsStrongMemory];;
	self.layers = [NSMutableDictionary dictionary];
	
}

- (void)setupLayers{
	[self setWantsLayer:YES];
	
	CALayer * MainScreen = [CALayer layer];
	MainScreen.frame    = CGRectMake(0, -45, 400, 358.62);
	MainScreen.contents = [NSImage imageNamed:@"MainScreen"];
	[self.layer addSublayer:MainScreen];
	self.layers[@"MainScreen"] = MainScreen;
	
	CAShapeLayer * rectangle = [CAShapeLayer layer];
	rectangle.frame       = CGRectMake(212.58, 15.4, 157, 44);
	rectangle.opacity     = 0.3;
	rectangle.fillColor   = [NSColor colorWithRed:0.922 green: 0.922 blue:0.922 alpha:1].CGColor;
	rectangle.strokeColor = [NSColor blueColor].CGColor;
	rectangle.lineWidth   = 3;
	rectangle.path        = [self rectanglePath].quartzPath;
	[self.layer addSublayer:rectangle];
	self.layers[@"rectangle"] = rectangle;
}



#pragma mark - Animation Setup

- (void)addScaleAnimationAnimation{
	NSString * fillMode = kCAFillModeForwards;
	
	////An infinity animation
	
	////Rectangle animation
	CAKeyframeAnimation * rectangleStrokeEndAnim = [CAKeyframeAnimation animationWithKeyPath:@"strokeEnd"];
	rectangleStrokeEndAnim.values         = @[@0, @1];
	rectangleStrokeEndAnim.keyTimes       = @[@0, @1];
	rectangleStrokeEndAnim.duration       = 1.59;
	rectangleStrokeEndAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseIn];
	
	CAKeyframeAnimation * rectangleTransformAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
	rectangleTransformAnim.values       = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.95, 0.95, 1)], 
		 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.1, 1.1, 1)]];
	rectangleTransformAnim.keyTimes     = @[@0, @1];
	rectangleTransformAnim.duration     = 1.4;
	rectangleTransformAnim.beginTime    = 1.59;
	rectangleTransformAnim.repeatCount  = INFINITY;
	rectangleTransformAnim.autoreverses = YES;
	
	CAAnimationGroup * rectangleScaleAnimationAnim = [QCMethod groupAnimations:@[rectangleStrokeEndAnim, rectangleTransformAnim] fillMode:fillMode];
	[self.layers[@"rectangle"] addAnimation:rectangleScaleAnimationAnim forKey:@"rectangleScaleAnimationAnim"];
}

#pragma mark - Animation Cleanup

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
	void (^completionBlock)(BOOL) = [self.completionBlocks objectForKey:anim];;
	if (completionBlock){
		[self.completionBlocks removeObjectForKey:anim];
		if ((flag && self.updateLayerValueForCompletedAnimation) || [[anim valueForKey:@"needEndAnim"] boolValue]){
			[self updateLayerValuesForAnimationId:[anim valueForKey:@"animId"]];
			[self removeAnimationsForAnimationId:[anim valueForKey:@"animId"]];
		}
		completionBlock(flag);
	}
}

- (void)updateLayerValuesForAnimationId:(NSString *)identifier{
	if([identifier isEqualToString:@"scaleAnimation"]){
		[QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"rectangle"] animationForKey:@"rectangleScaleAnimationAnim"] theLayer:self.layers[@"rectangle"]];
	}
}

- (void)removeAnimationsForAnimationId:(NSString *)identifier{
	if([identifier isEqualToString:@"scaleAnimation"]){
		[self.layers[@"rectangle"] removeAnimationForKey:@"rectangleScaleAnimationAnim"];
	}
}

- (void)removeAllAnimations{
	[self.layers enumerateKeysAndObjectsUsingBlock:^(id key, CALayer *layer, BOOL *stop) {
		[layer removeAllAnimations];
	}];
}

#pragma mark - Bezier Path

- (NSBezierPath*)rectanglePath{
	NSBezierPath *rectanglePath = [NSBezierPath bezierPath];
	[rectanglePath moveToPoint:CGPointMake(0, 0)];
	[rectanglePath lineToPoint:CGPointMake(157, 0)];
	[rectanglePath lineToPoint:CGPointMake(157, 44)];
	[rectanglePath lineToPoint:CGPointMake(0, 44)];
	[rectanglePath closePath];
	[rectanglePath moveToPoint:CGPointMake(0, 0)];
	
	return rectanglePath;
}


@end
