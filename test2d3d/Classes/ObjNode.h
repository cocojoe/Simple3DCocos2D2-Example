//
//  SkyboxNode.h
//  testar1
//
//  Created by Pasi Kettunen on 12.12.2012.
//
//


/*
 *
 * SkyboxNode is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * SkyboxNode is distributed WITHOUT ANY WARRANTY; See the
 * GNU General Public License for more details.
 *
 * Note: The 'cocos2d for iPhone' license also applies if used in conjunction
 * with the Cocos2D framework.
 */

#import "cocos2d.h"
#import "Interfaces.hpp"

struct Drawable {
    GLuint VertexBuffer;
    GLuint IndexBuffer;
    int IndexCount;
};

@interface ObjNode : CCScene<CCTextureProtocol> {
    
    // the texture names to draw in the skybox
    //GLuint textureName_gl;
    
    // the current rotation offset
    float xRot, yRot, zRot;
    ISurface *_model;
    
    Drawable _drawable;
    
    vector<float> vertices;
    vector<GLushort> indices;
    GLuint program;
    //
	// Data used when the sprite is self-rendered
	//
	ccBlendFunc				blendFunc_;				// Needed for the texture protocol
	CCTexture2D				*texture_;				// Texture used to render the sprite

}

@property float xRot;
@property float yRot;
@property float zRot;

@property (nonatomic,retain) NSString* TextureName;

@property (nonatomic,readwrite) ccBlendFunc blendFunc;

@property (nonatomic)ISurface *model;

//-(void)initializeModel;

@end