//
//  FloatingView.m
//
//  Code generated using QuartzCode 1.39.17 on 5/16/16.
//  www.quartzcodeapp.com
//

#import "FloatingView.h"
#import "QCMethod.h"

@interface FloatingView ()

@property (nonatomic, strong) NSMutableDictionary * layers;
@property (nonatomic, strong) NSMapTable * completionBlocks;
@property (nonatomic, assign) BOOL  updateLayerValueForCompletedAnimation;


@end

@implementation FloatingView

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
	
	CALayer * ActualScreen = [CALayer layer];
	ActualScreen.frame    = CGRectMake(-1.5, 80, 403, 122);
	ActualScreen.contents = [NSImage imageNamed:@"ActualScreen"];
	[self.layer addSublayer:ActualScreen];
	self.layers[@"ActualScreen"] = ActualScreen;
	
	CAShapeLayer * oval = [CAShapeLayer layer];
	oval.frame                      = CGRectMake(220.5, 69.89, 128.04, 130);
	oval.opacity                    = 0.42;
	oval.fillColor                  = nil;
	oval.strokeColor                = [NSColor blueColor].CGColor;
	oval.lineWidth                  = 5;
	oval.path                       = [self ovalPath].quartzPath;
	
	CAGradientLayer * ovalGradient = [CAGradientLayer layer];
	CAShapeLayer * ovalMask         = [CAShapeLayer layer];
	ovalMask.path                   = oval.path;
	ovalGradient.mask               = ovalMask;
	ovalGradient.frame              = oval.bounds;
	ovalGradient.colors             = @[(id)[NSColor colorWithRed:0.922 green: 0.922 blue:0.922 alpha:1].CGColor, (id)[NSColor whiteColor].CGColor];
	ovalGradient.startPoint         = CGPointMake(0.5, 1);
	ovalGradient.endPoint           = CGPointMake(0.5, 0);
	[oval addSublayer:ovalGradient];
	[self.layer addSublayer:oval];
	self.layers[@"oval"] = oval;
	self.layers[@"ovalGradient"] = ovalGradient;
}



#pragma mark - Animation Setup

- (void)addUntitled1Animation
{
	NSString * fillMode = kCAFillModeForwards;
	
	////An infinity animation
	
	////Oval animation
	CAKeyframeAnimation * ovalStrokeStartAnim = [CAKeyframeAnimation animationWithKeyPath:@"strokeStart"];
	ovalStrokeStartAnim.values   = @[@1, @0];
	ovalStrokeStartAnim.keyTimes = @[@0, @1];
	ovalStrokeStartAnim.duration = 1;
	
	CAKeyframeAnimation * ovalTransformAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
	ovalTransformAnim.values         = @[[NSValue valueWithCATransform3D:CATransform3DMakeScale(0.7, 0.7, 1)], 
		 [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 1.2)]];
	ovalTransformAnim.keyTimes       = @[@0, @1];
	ovalTransformAnim.duration       = 1;
	ovalTransformAnim.beginTime      = 1.01;
	ovalTransformAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
	ovalTransformAnim.repeatCount    = INFINITY;
	ovalTransformAnim.autoreverses   = YES;
	
	CAAnimationGroup * ovalUntitled1Anim = [QCMethod groupAnimations:@[ovalStrokeStartAnim, ovalTransformAnim] fillMode:fillMode];
	[self.layers[@"oval"] addAnimation:ovalUntitled1Anim forKey:@"ovalUntitled1Anim"];
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
	if([identifier isEqualToString:@"Untitled1"]){
		[QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"oval"] animationForKey:@"ovalUntitled1Anim"] theLayer:self.layers[@"oval"]];
	}
}

- (void)removeAnimationsForAnimationId:(NSString *)identifier{
	if([identifier isEqualToString:@"Untitled1"]){
		[self.layers[@"oval"] removeAnimationForKey:@"ovalUntitled1Anim"];
	}
}

- (void)removeAllAnimations{
	[self.layers enumerateKeysAndObjectsUsingBlock:^(id key, CALayer *layer, BOOL *stop) {
		[layer removeAllAnimations];
	}];
}

#pragma mark - Bezier Path

- (NSBezierPath*)ovalPath{
	NSBezierPath *ovalPath = [NSBezierPath bezierPath];
	[ovalPath moveToPoint:CGPointMake(64.018, 130)];
	[ovalPath curveToPoint:CGPointMake(0, 65) controlPoint1:CGPointMake(28.662, 130) controlPoint2:CGPointMake(0, 100.899)];
	[ovalPath curveToPoint:CGPointMake(64.018, 0) controlPoint1:CGPointMake(0, 29.101) controlPoint2:CGPointMake(28.662, 0)];
	[ovalPath curveToPoint:CGPointMake(128.035, 65) controlPoint1:CGPointMake(99.374, 0) controlPoint2:CGPointMake(128.035, 29.101)];
	[ovalPath curveToPoint:CGPointMake(64.018, 130) controlPoint1:CGPointMake(128.035, 100.899) controlPoint2:CGPointMake(99.374, 130)];
	
	return ovalPath;
}


@end
