//
//  CLAnimatedImages.m
//
//  Code generated using QuartzCode 1.39.16 on 5/10/16.
//  www.quartzcodeapp.com
//

#import "CLAnimatedImages.h"
#import "QCMethod.h"

@interface CLAnimatedImages ()

@property (nonatomic, strong) NSMutableDictionary * layers;
@property (nonatomic, strong) NSMapTable * completionBlocks;
@property (nonatomic, assign) BOOL  updateLayerValueForCompletedAnimation;


@end

@implementation CLAnimatedImages

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
    
    CALayer * effect = [CALayer layer];
    effect.frame = CGRectMake(25.09, 4.93, 230.89, 203.84);
    [self.layer addSublayer:effect];
    self.layers[@"effect"] = effect;
    //effect effect layer setup
    {
        CALayer * TopPlaces = [CALayer layer];
        TopPlaces.frame = CGRectMake(0, -0, 66, 57.02);
        [effect addSublayer:TopPlaces];
        self.layers[@"TopPlaces"] = TopPlaces;
        CALayer * TopPlaces2 = [CALayer layer];
        TopPlaces2.frame = CGRectMake(82.46, -0, 65.97, 56.99);
        [effect addSublayer:TopPlaces2];
        self.layers[@"TopPlaces2"] = TopPlaces2;
        CALayer * TopPlaces3 = [CALayer layer];
        TopPlaces3.frame = CGRectMake(164.92, -0, 65.97, 56.99);
        [effect addSublayer:TopPlaces3];
        self.layers[@"TopPlaces3"] = TopPlaces3;
        CALayer * TopPlaces4 = [CALayer layer];
        TopPlaces4.frame = CGRectMake(0, 73.43, 65.97, 56.99);
        [effect addSublayer:TopPlaces4];
        self.layers[@"TopPlaces4"] = TopPlaces4;
        CALayer * TopPlaces5 = [CALayer layer];
        TopPlaces5.frame = CGRectMake(82.46, 73.43, 65.97, 56.99);
        [effect addSublayer:TopPlaces5];
        self.layers[@"TopPlaces5"] = TopPlaces5;
        CALayer * TopPlaces6 = [CALayer layer];
        TopPlaces6.frame = CGRectMake(164.92, 73.43, 65.97, 56.99);
        [effect addSublayer:TopPlaces6];
        self.layers[@"TopPlaces6"] = TopPlaces6;
        CALayer * TopPlaces7 = [CALayer layer];
        TopPlaces7.frame = CGRectMake(0, 146.86, 65.97, 56.99);
        [effect addSublayer:TopPlaces7];
        self.layers[@"TopPlaces7"] = TopPlaces7;
        CALayer * TopPlaces8 = [CALayer layer];
        TopPlaces8.frame = CGRectMake(82.46, 146.86, 65.97, 56.99);
        [effect addSublayer:TopPlaces8];
        self.layers[@"TopPlaces8"] = TopPlaces8;
        CALayer * TopPlaces9 = [CALayer layer];
        TopPlaces9.frame = CGRectMake(164.92, 146.86, 65.97, 56.99);
        [effect addSublayer:TopPlaces9];
        self.layers[@"TopPlaces9"] = TopPlaces9;
    }
    
    
    [self resetLayerPropertiesForLayerIdentifiers:nil];
}

- (void)resetLayerPropertiesForLayerIdentifiers:(NSArray *)layerIds{
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    if(!layerIds || [layerIds containsObject:@"TopPlaces"]){
        CALayer * TopPlaces = self.layers[@"TopPlaces"];
        TopPlaces.masksToBounds   = YES;
        TopPlaces.contents        = [NSImage imageNamed:@"Tokyo"];
        TopPlaces.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces2"]){
        CALayer * TopPlaces2 = self.layers[@"TopPlaces2"];
        TopPlaces2.masksToBounds   = YES;
        TopPlaces2.contents        = [NSImage imageNamed:@"london"];
        TopPlaces2.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces3"]){
        CALayer * TopPlaces3 = self.layers[@"TopPlaces3"];
        TopPlaces3.masksToBounds   = YES;
        TopPlaces3.contents        = [NSImage imageNamed:@"SF"];
        TopPlaces3.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces4"]){
        CALayer * TopPlaces4 = self.layers[@"TopPlaces4"];
        TopPlaces4.masksToBounds   = YES;
        TopPlaces4.contents        = [NSImage imageNamed:@"LA"];
        TopPlaces4.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces5"]){
        CALayer * TopPlaces5 = self.layers[@"TopPlaces5"];
        TopPlaces5.masksToBounds   = YES;
        TopPlaces5.contents        = [NSImage imageNamed:@"sydney"];
        TopPlaces5.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces6"]){
        CALayer * TopPlaces6 = self.layers[@"TopPlaces6"];
        TopPlaces6.masksToBounds   = YES;
        TopPlaces6.contents        = [NSImage imageNamed:@"Singapore"];
        TopPlaces6.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces7"]){
        CALayer * TopPlaces7 = self.layers[@"TopPlaces7"];
        TopPlaces7.masksToBounds   = YES;
        TopPlaces7.contents        = [NSImage imageNamed:@"NYC"];
        TopPlaces7.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces8"]){
        CALayer * TopPlaces8 = self.layers[@"TopPlaces8"];
        TopPlaces8.masksToBounds   = YES;
        TopPlaces8.contents        = [NSImage imageNamed:@"HongKong"];
        TopPlaces8.contentsGravity = kCAGravityResizeAspectFill;
    }
    if(!layerIds || [layerIds containsObject:@"TopPlaces9"]){
        CALayer * TopPlaces9 = self.layers[@"TopPlaces9"];
        TopPlaces9.masksToBounds   = YES;
        TopPlaces9.contents        = [NSImage imageNamed:@"Paris"];
        TopPlaces9.contentsGravity = kCAGravityResizeAspectFill;
    }
    
    [CATransaction commit];
}

#pragma mark - Animation Setup

- (void)addUntitled1Animation{
    [self addUntitled1AnimationCompletionBlock:nil];
}

- (void)addUntitled1AnimationCompletionBlock:(void (^)(BOOL finished))completionBlock{
    if (completionBlock){
        CABasicAnimation * completionAnim = [CABasicAnimation animationWithKeyPath:@"completionAnim"];;
        completionAnim.duration = 4.2;
        completionAnim.delegate = self;
        [completionAnim setValue:@"Untitled1" forKey:@"animId"];
        [completionAnim setValue:@(NO) forKey:@"needEndAnim"];
        [self.layer addAnimation:completionAnim forKey:@"Untitled1"];
        [self.completionBlocks setObject:completionBlock forKey:[self.layer animationForKey:@"Untitled1"]];
    }
    
    NSString * fillMode = kCAFillModeForwards;
    
    ////Effect animation
    CAKeyframeAnimation * effectTransformAnim = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    effectTransformAnim.values         = @[[NSValue valueWithCATransform3D:CATransform3DIdentity],
                                           [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeScale(1.5, 1.5, 1), CATransform3DMakeRotation(-3 * M_PI/180, -0, -0, 1))],
                                           [NSValue valueWithCATransform3D:CATransform3DConcat(CATransform3DMakeScale(1.5, 1.5, 1), CATransform3DMakeRotation(3 * M_PI/180, 0, 0, 1))]];
    effectTransformAnim.keyTimes       = @[@0, @0.44, @1];
    effectTransformAnim.duration       = 0.5;
    effectTransformAnim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    effectTransformAnim.autoreverses   = YES;
    [effectTransformAnim setValue:@0.4 forKeyPath:@"instanceDelay"];
    [effectTransformAnim setValue:@0 forKeyPath:@"instanceOrder"];
    
    CABasicAnimation * effectZPositionAnim = [CABasicAnimation animationWithKeyPath:@"zPosition"];
    effectZPositionAnim.fromValue          = @0;
    effectZPositionAnim.toValue            = @100;
    effectZPositionAnim.duration           = 0.5;
    effectZPositionAnim.timingFunction     = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    effectZPositionAnim.autoreverses       = YES;
    [effectZPositionAnim setValue:@0.4 forKeyPath:@"instanceDelay"];
    [effectZPositionAnim setValue:@0 forKeyPath:@"instanceOrder"];
    
    CAAnimationGroup * effectUntitled1Anim = [QCMethod groupAnimations:@[effectTransformAnim, effectZPositionAnim] fillMode:kCAFillModeBoth forEffectLayer:YES sublayersCount:9];
    [QCMethod addSublayersAnimation:effectUntitled1Anim forKey:@"effectUntitled1Anim" forLayer:(CALayer *)self.layers[@"effect"]];
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
        [QCMethod updateValueFromPresentationLayerForAnimation:[self.layers[@"effect"] animationForKey:@"effectUntitled1Anim"] theLayer:self.layers[@"effect"]];
    }
}

- (void)removeAnimationsForAnimationId:(NSString *)identifier{
    if([identifier isEqualToString:@"Untitled1"]){
        [self.layers[@"effect"] removeAnimationForKey:@"effectUntitled1Anim"];
    }
}

- (void)removeAllAnimations{
    [self.layers enumerateKeysAndObjectsUsingBlock:^(id key, CALayer *layer, BOOL *stop) {
        [layer removeAllAnimations];
    }];
}

@end
