//
//  HelloWorldLayer.m
//  test2d3d
//
//  Created by Pasi Kettunen on 16.12.2012.
//  Copyright Pasi Kettunen 2012. All rights reserved.
//


// Import the interfaces
#import "HelloWorldLayer.h"

// Needed to obtain the Navigation Controller
/*#if (COCOS2D_VERSION < 0x020000)
#  import "AppDelegate1.x.h"
#else
#  import "AppDelegate.h"
#endif
*/
#include "Interfaces.hpp"
#include "ObjSurface.hpp"

#include "ObjNode.h"

#define _MAIN_FONT @"Marker Felt"

#pragma mark - HelloWorldLayer

// HelloWorldLayer implementation
@implementation HelloWorldLayer

// Helper class method that creates a Scene with the HelloWorldLayer as the only child.
+(CCScene *) scene
{
	// 'scene' is an autorelease object.
	CCScene *scene = [CCScene node];
	
	// 'layer' is an autorelease object.
	HelloWorldLayer *layer = [HelloWorldLayer node];
	
	// add layer as a child to scene
	[scene addChild: layer];
	
	// return the scene
	return scene;
}

// on "init" you need to initialize your instance
-(id) init
{
	// always call "super" init
	// Apple recommends to re-assign "self" with the "super's" return value
	if( (self=[super init]) ) {
        
        [[CCDirector sharedDirector] setDepthTest:YES];
		glClearColor(0.2f, 0.2f, 0.4f, 1.0f);
        
        [[CCDirector sharedDirector] setProjection:kCCDirectorProjection3D];

		// Ask director for the window size
		CGSize size = [[CCDirector sharedDirector] winSize];
	
        // "scoreLabel" is for info here
		if( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone ) {
            scoreLabel = [CCLabelTTF labelWithString:@"-"
                                            fontName:_MAIN_FONT fontSize:12];
            scoreLabel.anchorPoint = ccp(0,0);
            scoreLabel.position = ccp( 5, size.height-20);
        }
        else { // iPad
            scoreLabel = [CCLabelTTF labelWithString:@"-" 
                                            fontName:_MAIN_FONT fontSize:20];
            scoreLabel.anchorPoint = ccp(0,0);
            scoreLabel.position = ccp( 5, size.height-30);
        }

        // Create the ObjNode layer
        objn = [ObjNode node];
        objPos = ccp(size.width / 2, size.height / 2);
        
        // Path to resources
        string path = [[[NSBundle mainBundle] resourcePath] UTF8String];
        
        // Select which model to show
#define MODEL 3
        switch (MODEL) {
            case 1:
                ((ObjNode*)objn).model = new ObjSurface(path + "/micronapalmv2.obj");
                objScale = 2.0; // scale up a little
                objZ = -12.0;   // move back
                break;
            case 2:
                ((ObjNode*)objn).model = new ObjSurface(path + "/cube.obj");
                ((ObjNode*)objn).TextureName = @"car00.png";
                objScale = 4.0;    // scale up
                objZ = -10.0;        // move back
                break;
            case 3:
                ((ObjNode*)objn).model = new ObjSurface(path + "/Scania4.obj");
                ((ObjNode*)objn).TextureName = @"car00.png";
                objScale = 16.0;    // scale up a lot
                objZ = -16.0;       // move back
                objPos = ccp(objPos.x, objPos.y * .5); // move the truck down a little
                break;
            default:
                break;
        }
        
        // Scale and position the model
        objn.scale = objScale;
        objn.vertexZ = objZ;
        objn.position = objPos;
        
        // Add the ObjNode to this scene
        [self addChild:objn z:-2];
        
        // A kind of UI
        leftBarPos = 40;
        rightBarPos = size.width - leftBarPos;
        leftBar = [CCSprite spriteWithFile:@"gline.png"];
        rightBar = [CCSprite spriteWithFile:@"gline.png"];
        float barScale = size.height / leftBar.contentSize.height;
        leftBar.position = ccp(leftBarPos, size.height / 2);
        rightBar.position = ccp(rightBarPos, size.height / 2);
        leftBar.scaleY = barScale;
        rightBar.scaleY = barScale;
        [self addChild:leftBar];
        [self addChild:rightBar];
        
        // Crosshair cursor and the "score" label
        crosshair = [CCSprite spriteWithFile:@"crosshair.png"];
        [self addChild:crosshair];
        crosshair.visible = NO;
        [self positionCrosshair];
        
        [self addChild:scoreLabel z:50];
        [self updateLabel];
        
        // Schedule update
        [self schedule:@selector(nextFrame:)];
	}
	return self;
}

-(void)positionCrosshair {
    crosshair.position = objPos;
    //crosshair.vertexZ = objZ;
}

- (void) nextFrame:(ccTime)dt {

    // Here the model rotation takes place
    
    float yr,xr,zr;
    static ccTime ddt = 0;
    ddt += dt * .25;

    yr = [(ObjNode*)objn yRot];
    yr += dt * 23;
    xr = [(ObjNode*)objn xRot];
    xr += dt * 23;
    ((ObjNode*)objn).yRot = yr;
    //((ObjNode*)objn).xRot = xr;
    zr = [(ObjNode*)objn zRot];
    zr += sinf(ddt) * .05;
    ((ObjNode*)objn).zRot = zr;
    
    ((ObjNode*)objn).xRot = zr / 2;
}

-(void)updateLabelX:(float)x Y:(float)y Z:(float)z Scale:(float)s {
    [scoreLabel setString:[NSString stringWithFormat:@"x: %3.1f y: %3.1f z:%3.2f scale:%3.2f", x, y ,z, s]];
}

-(void)updateLabel {
    [self updateLabelX:objPos.x Y:objPos.y Z:objZ Scale:objScale];
}

- (void)onEnter
{
#if (COCOS2D_VERSION < 0x020000)
	[[CCTouchDispatcher sharedDispatcher] addTargetedDelegate:self priority:0 swallowsTouches:NO];
#else
	[[CCDirector sharedDirector].touchDispatcher addTargetedDelegate:self priority:0 swallowsTouches:NO];
#endif
    state = kPaddleStateUngrabbed;
	[super onEnter];
}

- (void)onExit
{
#if (COCOS2D_VERSION < 0x020000)
    [[CCTouchDispatcher sharedDispatcher] removeDelegate:self];
#else
    [[CCDirector sharedDirector].touchDispatcher removeDelegate:self];
#endif
	[super onExit];
}

- (BOOL)ccTouchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
	if (state != kPaddleStateUngrabbed) return NO;
	
    /*
     Touch interface:
     
     Left bar: scale object
     Right bar: move object along the Z-axis (close - far)
     Everywhere else: move object x,y
     
     */
	CGPoint d = [touch locationInView:[touch view]];
    touchpos = [[CCDirector sharedDirector] convertToGL:d];
    //NSLog(@"d.x %f d.y %f", touchpos.x, touchpos.y);
    if (touchpos.x <= leftBarPos)
        state = kLeftGrabbed;
    else if (touchpos.x >= rightBarPos) {
        state = kRightGrabbed;
        [self positionCrosshair];
        crosshair.visible = YES;
    }
    else {
        state = kPaddleStateGrabbed;
        [self positionCrosshair];
        crosshair.visible = YES;
    }
    
    return YES;
}

- (void)ccTouchMoved:(UITouch *)touch withEvent:(UIEvent *)event {
    if (state != kPaddleStateUngrabbed) {
        CGPoint d = [touch locationInView:[touch view]];
        d = [[CCDirector sharedDirector] convertToGL:d];
        CGPoint tdelta = ccp(d.x - touchpos.x, d.y - touchpos.y);
        //NSLog(@"tdelta.x %f tdelta.y %f", tdelta.x, tdelta.y);
        touchpos = d;
        CGSize ws = [[CCDirector sharedDirector] winSize];
        switch (state) {
            case kPaddleStateGrabbed:   // Move object x,y
                objPos = ccp(objPos.x + tdelta.x, objPos.y + tdelta.y);
                if (objPos.x < 0.0) objPos.x = 0.0;
                else if (objPos.x > ws.width) objPos.x = ws.width;
                if (objPos.y < 0.0) objPos.y = 0.0;
                else if (objPos.y > ws.height) objPos.y = ws.height;
                //crosshair.position = objPos;
                objn.position = objPos;
                [self positionCrosshair];
                break;
                
            case kLeftGrabbed:  // Scale object
                objScale = objScale + tdelta.y * .05;
                objn.scale = objScale;
                break;
            case kRightGrabbed: // move object along the Z-axis (close - far)
                objZ = objZ + tdelta.y * .05;
                objn.vertexZ = objZ;
                [self positionCrosshair];
                break;
                
            default:
                break;
        }
        [self updateLabel];
    }
}

- (void)ccTouchEnded:(UITouch *)touch withEvent:(UIEvent *)event {
    crosshair.visible = NO;
    state = kPaddleStateUngrabbed;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	// in case you have something to dealloc, do it in this method
	// in this particular example nothing needs to be released.
	// cocos2d will automatically release all the children (Label)
	
	// don't forget to call "super dealloc"
	[super dealloc];
}

#pragma mark GameKit delegate

@end
