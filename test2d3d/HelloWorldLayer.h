//
//  HelloWorldLayer.h
//  test2d3d
//
//  Created by Pasi Kettunen on 16.12.2012.
//  Copyright Pasi Kettunen 2012. All rights reserved.
//


#import <GameKit/GameKit.h>

// When you import this file, you import all the cocos2d classes
#import "cocos2d.h"

typedef enum tagPaddleState {
    kPaddleStateGrabbed,
    kPaddleStateUngrabbed,
    kLeftGrabbed,
    kRightGrabbed
} PaddleState;

// HelloWorldLayer
@interface HelloWorldLayer : CCLayer  <CCTargetedTouchDelegate>
{
    PaddleState state;
    CGPoint touchpos;
    CCNode *objn;
    CGPoint objPos;
    float objScale;
    float objZ;
    CCSprite *crosshair;
    //GradientLayer *glayer;
    CCSprite *leftBar;
    CCSprite *rightBar;
    int leftBarPos;
    int rightBarPos;
    CCLabelTTF *scoreLabel;
}

// returns a CCScene that contains the HelloWorldLayer as the only child
+(CCScene *) scene;
-(void)updateLabel;

@end
