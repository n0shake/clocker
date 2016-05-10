//
//  QCMethod.m
//
//  www.quartzcodeapp.com
//

#import "QCMethod.h"

@implementation QCMethod

+ (CAAnimation*)reverseAnimation:(CAAnimation*)anim totalDuration:(CGFloat)totalDuration{
	CGFloat duration = anim.duration + (anim.autoreverses ? anim.duration : 0);
	duration = anim.repeatCount > 1 ? duration * anim.repeatCount : duration;
	
	CGFloat endTime = anim.beginTime + duration;
	CGFloat reverseStartTime = totalDuration - endTime;
	
	CAAnimation *newAnim;
	//Reverse timing function
	void (^reverseTimingFunction)(CAAnimation*) = ^(CAAnimation *theAnim){
		CAMediaTimingFunction *timingFunction = theAnim.timingFunction;
		if (timingFunction) {
			float first[2];
			float second[2];
			[timingFunction getControlPointAtIndex:1 values:first];
			[timingFunction getControlPointAtIndex:2 values:second];
			theAnim.timingFunction = [CAMediaTimingFunction functionWithControlPoints:1-second[0] :1-second[1] :1-first[0] :1-first[1]];
		}
	};
	
	//Reverse animation values appropriately
	if ([anim isKindOfClass:[CABasicAnimation class]]) {
		CABasicAnimation *basicAnim = (CABasicAnimation*)anim;
		
		if (!anim.autoreverses) {
			id fromValue = basicAnim.toValue;
			basicAnim.toValue = basicAnim.fromValue;
			basicAnim.fromValue = fromValue;
			reverseTimingFunction(basicAnim);
		}
		basicAnim.beginTime = reverseStartTime;
		
		if (reverseStartTime > 0) {
			CAAnimationGroup *groupAnim = [CAAnimationGroup animation];
			groupAnim.animations = @[basicAnim];
			groupAnim.duration = [self maxDurationFromAnimations:groupAnim.animations];
			[groupAnim.animations setValue:kCAFillModeBoth forKeyPath:@"fillMode"];
			newAnim = groupAnim;
		}else newAnim = basicAnim;
	}
	else if ([anim isKindOfClass:[CAKeyframeAnimation class]]) {
		CAKeyframeAnimation *keyAnim = (CAKeyframeAnimation*)anim;
		
		if (!anim.autoreverses) {
			NSArray *values = [[keyAnim.values reverseObjectEnumerator] allObjects];
			keyAnim.values = values;
			reverseTimingFunction(keyAnim);
		}
		keyAnim.beginTime = reverseStartTime;
		
		if (reverseStartTime > 0) {
			CAAnimationGroup *groupAnim = [CAAnimationGroup animation];
			groupAnim.animations = @[keyAnim];
			groupAnim.duration = [self maxDurationFromAnimations:groupAnim.animations];
			[groupAnim.animations setValue:kCAFillModeBoth forKeyPath:@"fillMode"];
			newAnim = groupAnim;
		}else newAnim = keyAnim;
		
	}
	else if ([anim isKindOfClass:[CAAnimationGroup class]]) {
		CAAnimationGroup *groupAnim = (CAAnimationGroup*)anim;
		NSMutableArray *newSubAnims = [NSMutableArray arrayWithCapacity:groupAnim.animations.count];
		for (CAAnimation *subAnim in groupAnim.animations) {
			CAAnimation *newSubAnim = [self reverseAnimation:subAnim totalDuration:totalDuration];
			[newSubAnims addObject:newSubAnim];
		}
		groupAnim.animations = newSubAnims;
		[groupAnim.animations setValue:kCAFillModeBoth forKeyPath:@"fillMode"];
		groupAnim.duration = [self maxDurationFromAnimations:newSubAnims];
		newAnim = groupAnim;
	}else newAnim = anim;
	
	return newAnim;
}

+ (CAAnimationGroup*)groupAnimations:(NSArray*)animations fillMode:(NSString*)fillMode forEffectLayer:(BOOL)forEffectLayer sublayersCount:(NSInteger)count{
	CAAnimationGroup *groupAnimation = [CAAnimationGroup animation];
	groupAnimation.animations        = animations;
	if (fillMode) {
		[groupAnimation.animations setValue:fillMode forKeyPath:@"fillMode"];
		groupAnimation.fillMode = fillMode;
		groupAnimation.removedOnCompletion = NO;
	}
	
	if (forEffectLayer) {
		groupAnimation.duration = [QCMethod maxDurationOfEffectAnimation:groupAnimation sublayersCount:count];
		}else{
		groupAnimation.duration = [QCMethod maxDurationFromAnimations:animations];
	}
	return groupAnimation;
}

+ (CAAnimationGroup*)groupAnimations:(NSArray*)animations fillMode:(NSString*)fillMode{
	return [self groupAnimations:animations fillMode:fillMode forEffectLayer:NO sublayersCount:0];
}
+ (CGFloat)maxDurationFromAnimations:(NSArray*)anims{
	CGFloat maxDuration = 0;
	for (CAAnimation *anim in anims) {
		maxDuration = MAX(anim.beginTime + anim.duration * (CGFloat)(anim.repeatCount == 0 ? 1.0f : anim.repeatCount) * (anim.autoreverses ? 2.0f : 1.0f), maxDuration);
	}
	if (maxDuration == INFINITY) {
		maxDuration = 1000.0f;
	}
	
	return maxDuration;
}

+ (CGFloat)maxDurationOfEffectAnimation:(CAAnimationGroup*)anim sublayersCount:(NSInteger)count{
	CGFloat maxDuration = 0;
	if ([anim isKindOfClass:[CAAnimationGroup class]]) {
		for (CABasicAnimation *subAnim in anim.animations) {
			CGFloat instanceDelay  = [[subAnim valueForKey:@"instanceDelay"] floatValue];
			CGFloat delay = instanceDelay * (CGFloat)(count - 1);
			CGFloat repeatCountDuration = 0;
			if (subAnim.repeatCount >1) {
				repeatCountDuration = (subAnim.duration * (subAnim.repeatCount-1));
			}
			
			CGFloat duration = subAnim.beginTime + (subAnim.autoreverses ? subAnim.duration : 0) + (delay + subAnim.duration + repeatCountDuration);
			maxDuration = MAX(duration, maxDuration);
		}
	}
	if (maxDuration == INFINITY) {
		maxDuration = 1000.0f;
	}
	return maxDuration;
}

+ (void)updateValueFromAnimationsForLayers:(NSArray*)layers{
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	for (CALayer *layer in layers) {
		for (NSString *animKey in layer.animationKeys) {
			CAAnimation *anim = [layer animationForKey:animKey];
			[self updateValueForAnimation:anim theLayer:layer];
		}
	}
	
	[CATransaction commit];
}

+ (void)updateValueForAnimation:(CAAnimation*)anim theLayer:(CALayer *)layer{
	if ([anim isKindOfClass:[CABasicAnimation class]]) {
		CABasicAnimation *basicAnim = (CABasicAnimation*)anim;
		if (!basicAnim.autoreverses) {
			[layer setValue:basicAnim.toValue forKeyPath:basicAnim.keyPath];
		}
	}
	else if ([anim isKindOfClass:[CAKeyframeAnimation class]]) {
		CAKeyframeAnimation *keyAnim = (CAKeyframeAnimation*)anim;
		if (!anim.autoreverses) {
			[layer setValue:keyAnim.values.lastObject forKeyPath:keyAnim.keyPath];
		}
	}
	else if ([anim isKindOfClass:[CAAnimationGroup class]]) {
		CAAnimationGroup *groupAnim = (CAAnimationGroup*)anim;
		for (CAAnimation *subAnim in groupAnim.animations) {
			[self updateValueForAnimation:subAnim theLayer:layer];
		}
	}
}

+ (void)updateValueFromPresentationLayerForAnimation:(CAAnimation*)anim theLayer:(CALayer *)layer{
	if ([anim isKindOfClass:[CABasicAnimation class]] || [anim isKindOfClass:[CAKeyframeAnimation class]]) {
		CABasicAnimation *basicAnim = (CABasicAnimation*)anim;
		[layer setValue:[layer.presentationLayer valueForKeyPath:basicAnim.keyPath] forKeyPath:basicAnim.keyPath];
	}
	else if ([anim isKindOfClass:[CAAnimationGroup class]]) {
		CAAnimationGroup *groupAnim = (CAAnimationGroup*)anim;
		for (CAAnimation *subAnim in groupAnim.animations) {
			[self updateValueFromPresentationLayerForAnimation:subAnim theLayer:layer];
		}
	}
}

+ (void)addSublayersAnimation:(CAAnimation*)anim forKey:(NSString*)key forLayer:(CALayer*)layer{
	[self addSublayersAnimationNeedReverse:anim forKey:key forLayer:layer reverseAnimation:NO totalDuration:0];
}

//!Add animation to each sublayer in effect layer
+ (void)addSublayersAnimationNeedReverse:(CAAnimation*)anim forKey:(NSString*)key forLayer:(CALayer*)layer reverseAnimation:(BOOL)reverse totalDuration:(CGFloat)totalDuration{
	NSArray *sublayers =  layer.sublayers;
	NSInteger sublayersCount = sublayers.count;
	
	void (^setBeginTime)(CAAnimation*, NSInteger) = ^(CAAnimation *subAnim, NSInteger sublayerIdx){
		CGFloat instanceDelay = [[subAnim valueForKey:@"instanceDelay"] floatValue];
		NSInteger orderType = [[subAnim valueForKey:@"instanceOrder"] integerValue];
		switch (orderType) {
			case 0: subAnim.beginTime += sublayerIdx * instanceDelay; break;
			case 1: subAnim.beginTime += (sublayersCount - sublayerIdx - 1) * instanceDelay; break;
			case 2: {
				CGFloat middleIdx     = sublayersCount/2.0f;
				CGFloat begin         = fabs((middleIdx - sublayerIdx)) * instanceDelay ;
				subAnim.beginTime     += begin; break;
			}
			case 3: {
				CGFloat middleIdx     = sublayersCount/2.0f;
				CGFloat begin         = (middleIdx - fabs((middleIdx - sublayerIdx))) * instanceDelay ;
				subAnim.beginTime     += begin; break;
			}
			case 4: {
				//Add yours here
			}
			default:
			break;
		}
	};
	
	[sublayers enumerateObjectsWithOptions:0 usingBlock:^(CALayer *sublayer, NSUInteger idx, BOOL *stop) {
		if ([anim isKindOfClass:[CAAnimationGroup class]]) {
			CAAnimationGroup *groupAnim      = (CAAnimationGroup*)anim.copy;
			NSMutableArray *newSubAnimations = [NSMutableArray arrayWithCapacity:groupAnim.animations.count];
			for (CABasicAnimation *subAnim in groupAnim.animations) {
				[newSubAnimations addObject:subAnim.copy];
			}
			
			groupAnim.animations = newSubAnimations;
			NSArray *animations  = [(CAAnimationGroup*)groupAnim animations];
			for (CABasicAnimation *sub in animations) {
				setBeginTime(sub, idx);
				
				//Reverse animation if needed
				if (reverse) [self reverseAnimation:sub totalDuration:totalDuration];
			}
			[sublayer addAnimation:groupAnim forKey:key];
		}
		else{
			CABasicAnimation *copiedAnim = anim.copy;
			setBeginTime(copiedAnim, idx);
			[sublayer addAnimation:copiedAnim forKey:key];
		}
	}];
}


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
+ (UIBezierPath*)alignToBottomPath:(UIBezierPath*)path layer:(CALayer*)layer{
	CGFloat diff = CGRectGetMaxY(layer.bounds) - CGRectGetMaxY(path.bounds);
	CGAffineTransform affineTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, 0, diff);
	[path applyTransform:affineTransform];
	return path;
}

+ (UIBezierPath*)offsetPath:(UIBezierPath*)path by:(CGPoint)offset{
	CGAffineTransform affineTransform = CGAffineTransformTranslate(CGAffineTransformIdentity, offset.x, offset.y);
	[path applyTransform:affineTransform];
	return path;
}


#else
+ (NSBezierPath*)offsetPath:(NSBezierPath*)path by:(CGPoint)offset{
	NSAffineTransform*	xfm = [NSAffineTransform transform];
	[xfm translateXBy:offset.x yBy:offset.y];
	[path transformUsingAffineTransform:xfm];
	return path;
}


#endif

@end


#if (TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE)
#else
@implementation NSBezierPath (Path)

- (CGPathRef)quartzPath{
	NSInteger i, numElements;
	CGPathRef           immutablePath = NULL;
	numElements = [self elementCount];
	
	if (numElements > 0)
	{
		CGMutablePathRef    path = CGPathCreateMutable();
		NSPoint             points[3];
		BOOL                didClosePath = YES;
		
		for (i = 0; i < numElements; i++)
		{
			switch ([self elementAtIndex:i associatedPoints:points])
			{
				case NSMoveToBezierPathElement:
				CGPathMoveToPoint(path, NULL, points[0].x, points[0].y);
				break;
				
				case NSLineToBezierPathElement:
				CGPathAddLineToPoint(path, NULL, points[0].x, points[0].y);
				didClosePath = NO;
				break;
				
				case NSCurveToBezierPathElement:
				CGPathAddCurveToPoint(path, NULL, points[0].x, points[0].y,
				points[1].x, points[1].y,
				points[2].x, points[2].y);
				didClosePath = NO;
				break;
				
				case NSClosePathBezierPathElement:
				CGPathCloseSubpath(path);
				didClosePath = YES;
				break;
			}
		}
		if (!didClosePath){
			//CGPathCloseSubpath(path);
		}
		
		immutablePath = CGPathCreateCopy(path);
		CGPathRelease(path);
	}
	return immutablePath;
}

@end

@implementation NSImage (cgImage)

-(CGImageRef)cgImage{
		NSData* data = [self TIFFRepresentation];
	    CGImageRef        imageRef = NULL;
	    CGImageSourceRef  sourceRef;
	    
	    sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
	    if(sourceRef) {
		        imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, NULL);
		        CFRelease(sourceRef);
	    }
	    return imageRef;
}

@end

#endif
