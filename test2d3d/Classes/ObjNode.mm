//
//  SkyboxNode.m
//  testar1
//
//  Created by Pasi Kettunen on 12.12.2012.
//
//

#import "ObjNode.h"
#import "ObjSurface.hpp"
#import <GLKit/GLKit.h>

@implementation ObjNode

@synthesize blendFunc = blendFunc_;

@synthesize xRot;
@synthesize yRot;
@synthesize zRot;

@synthesize model = _model;

#define USE_VBO

#define STRINGIFY(A)  #A
//#include "../Shaders/TexturedLighting.es2.vert.h"
#include "../Shaders/TexturedLighting1.es2.vert.h"
#include "../Shaders/TexturedLighting.es2.frag.h"
#include "../Shaders/ColorLighting1.es2.frag.h"

struct UniformHandles {
    GLuint Modelview;
    GLuint Projection;
    GLuint NormalMatrix;
    GLuint LightPosition;
    GLint AmbientMaterial;
    GLint SpecularMaterial;
    GLint DiffuseMaterial;
    GLint Shininess;
    GLint Sampler;
};

struct AttributeHandles {
    GLint Position;
    GLint Normal;
    GLint TextureCoord;
};
UniformHandles m_uniforms;
AttributeHandles m_attributes;

-(void)initializeModel {
    if (_model) {

        unsigned char vertexFlags = VertexFlagsNormals | VertexFlagsTexCoords;
        _model->GenerateVertices(vertices, vertexFlags);
        
        int indexCount = _model->GetTriangleIndexCount();
        indices.resize(indexCount);
        _model->GenerateTriangleIndices(indices);
        _drawable.IndexCount = indexCount;

        delete _model;
        _model = NULL;
#ifdef USE_VBO
        [self buildBuffers];
        
#endif
        [self updateBlendFunc];
        program = [self BuildProgram:[texture_ name] != 0];

    }
}

-(void)setModel:(ISurface *)model {
    _model = model;
    [self initializeModel];
}

-(GLuint)BuildProgram:(BOOL)textured {
    GLuint _program;
    // Create the GLSL program.
    if (textured) {
        _program = ObjSurface::BuildProgram(SimpleVertexShader1, SimpleFragmentShader);
    }
    else
        _program = ObjSurface::BuildProgram(SimpleVertexShader1, ColorLighting1);
    //glUseProgram(_program);
    
    // Extract the handles to attributes and uniforms.
    m_attributes.Position = glGetAttribLocation(_program, "Position");
    m_attributes.Normal = glGetAttribLocation(_program, "Normal");
    
    m_uniforms.DiffuseMaterial = glGetUniformLocation(_program, "DiffuseMaterial");
    if (textured) {
        m_attributes.TextureCoord = glGetAttribLocation(_program, "TextureCoord");
        m_uniforms.Sampler = glGetUniformLocation(_program, "Sampler");
    }
    else {
        m_attributes.TextureCoord = 0;
        m_uniforms.Sampler = 0;
    }
    m_uniforms.Projection = glGetUniformLocation(_program, "Projection");
    m_uniforms.Modelview = glGetUniformLocation(_program, "Modelview");
    m_uniforms.NormalMatrix = glGetUniformLocation(_program, "NormalMatrix");
    m_uniforms.LightPosition = glGetUniformLocation(_program, "LightPosition");
    m_uniforms.AmbientMaterial = glGetUniformLocation(_program, "AmbientMaterial");
    m_uniforms.SpecularMaterial = glGetUniformLocation(_program, "SpecularMaterial");
    m_uniforms.Shininess = glGetUniformLocation(_program, "Shininess");
    return _program;
}

#ifdef USE_VBO
-(void)buildBuffers {
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER,
                 vertices.size() * sizeof(vertices[0]),
                 &vertices[0],
                 GL_STATIC_DRAW);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    
    // Create a new VBO for the indices
    int indexCount = indices.size();// model->GetTriangleIndexCount();
    GLuint indexBuffer;

    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER,
                 indexCount * sizeof(GLushort),
                 &indices[0],
                 GL_STATIC_DRAW);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);
    
    _drawable.VertexBuffer = vertexBuffer;
    _drawable.IndexBuffer = indexBuffer;
    _drawable.IndexCount = indexCount;
}
#endif
-(void)draw
{
    [super draw];

    float _contentScale = scaleX_;

    //CC_NODE_DRAW_SETUP();

    ccGLEnable( glServerState_ );
    ccGLUseProgram(program);
    //glUseProgram(program);

	ccGLBlendFunc( blendFunc_.src, blendFunc_.dst );
    kmGLLoadIdentity();
    
	if ([texture_ name]) {
        ccGLBindTexture2D( [texture_ name] );
        glUniform1i(m_uniforms.Sampler, 0);
        ccGLEnableVertexAttribs( kCCVertexAttribFlag_PosColorTex );
    }
    else {
        ccGLEnableVertexAttribs(kCCVertexAttribFlag_Position);
    }
    
    // Set up some default material parameters.
    glUniform3f(m_uniforms.AmbientMaterial, 0.1f, 0.1f, 0.1f);
    glUniform3f(m_uniforms.SpecularMaterial, 0.5, 0.5, 0.5);
    glUniform1f(m_uniforms.Shininess, 10);
    //glUniform1f(m_uniforms.Shininess, 0);
    
    // Set the diffuse color.
    vec3 color = vec3(1,1, 1.1) * .50;
    glUniform3f(m_uniforms.DiffuseMaterial, color.x, color.y, color.z);
    //glVertexAttrib3f(m_attributes.DiffuseMaterial, color.x, color.y, color.z);
    
    // Initialize various state.
    glEnableVertexAttribArray(m_attributes.Position);
    glEnableVertexAttribArray(m_attributes.Normal);
    if ([texture_ name])
        glEnableVertexAttribArray(m_attributes.TextureCoord);
    glEnable(GL_DEPTH_TEST);

    // Set the light position.
    vec3 lightPosition = vec3(-2.25, 0.25, 1);
    lightPosition.Normalize();
    vec4 lp = vec4(lightPosition.x, lightPosition.y, lightPosition.z, 0);
    glUniform3fv(m_uniforms.LightPosition, 1, lp.Pointer());

    // Set up transforms.
    CGSize size = [CCDirector sharedDirector].winSize;
    CGPoint pos = ccp(position_.x - size.width / 2, position_.y - size.height / 2);
    mat4 m_translation = mat4::Translate(pos.x * 8.0 / size.width, pos.y * 8.0 / size.width, vertexZ_);
    //mat4 m_scale = mat4::Scale(.5 + zRot * .07);
    mat4 m_scale = mat4::Scale(_contentScale);

    // Set the model-view transform.
    Quaternion rot = Quaternion::CreateFromAxisAngle(vec3(0, 1, 0), yRot * Pi / 180);
    Quaternion rot2 = Quaternion::CreateFromAxisAngle(vec3(0, 0, 1), zRot * Pi / 180);
    Quaternion rot3 = Quaternion::CreateFromAxisAngle(vec3(1, 0, 0), xRot * Pi / 180);
    //rot = rot.Rotated(rot);
    mat4 rotation = rot2.ToMatrix();
    rotation *= rot.ToMatrix();
    rotation *= rot3.ToMatrix();
    mat4 modelview = m_scale * rotation * m_translation;

    glUniformMatrix4fv(m_uniforms.Modelview, 1, 0, modelview.Pointer());
    
    // Set the normal matrix.
    // It's orthogonal, so its Inverse-Transpose is itself!
    mat3 normalMatrix = modelview.ToMat3();
    glUniformMatrix3fv(m_uniforms.NormalMatrix, 1, 0, normalMatrix.Pointer());
    
    // Set the projection transform.
    
    float h = 4.0f * size.height / size.width;
    float k = 1.0;
    h *= k;
    mat4 projectionMatrix = mat4::Frustum(-2 * k, 2 * k, -h / 2, h / 2, 4, 40);

    //projectionMatrix *= mat4::Scale(1.0);
    glUniformMatrix4fv(m_uniforms.Projection, 1, 0, projectionMatrix.Pointer());

#ifdef USE_VBO
    // Draw the surface using VBOs
    int stride = sizeof(vec3) + sizeof(vec3) + sizeof(vec2);
    const GLvoid* normalOffset = (const GLvoid*) sizeof(vec3);
    const GLvoid* texCoordOffset = (const GLvoid*) (2 * sizeof(vec3));
    GLint position = m_attributes.Position;
    GLint normal = m_attributes.Normal;
    GLint texCoord = m_attributes.TextureCoord;

    glBindBuffer(GL_ARRAY_BUFFER, _drawable.VertexBuffer);
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, stride, 0);
    glVertexAttribPointer(normal, 3, GL_FLOAT, GL_FALSE, stride, normalOffset);
    if ([texture_ name])
        glVertexAttribPointer(texCoord, 2, GL_FLOAT, GL_FALSE, stride, texCoordOffset);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _drawable.IndexBuffer);
    glDrawElements(GL_TRIANGLES, _drawable.IndexCount, GL_UNSIGNED_SHORT, 0);
    
    //glBindVertexArray(0);
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

#else
    // Draw the surface without VBOs
    int stride = sizeof(vec3) + sizeof(vec3) + sizeof(vec2);
    const GLvoid* normals = (const GLvoid*) ((char*)&vertices[0] + sizeof(vec3));
    const GLvoid* texCoords = (const GLvoid*) ((char*)&vertices[0] + (2 * sizeof(vec3)));
    const GLvoid* Vertices = (const GLvoid*)&vertices[0];
    GLint position = m_attributes.Position;
    GLint normal = m_attributes.Normal;
    GLint texCoord = m_attributes.TextureCoord;
    
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, stride, Vertices);
    glVertexAttribPointer(normal, 3, GL_FLOAT, GL_FALSE, stride, normals);
    if ([texture_ name])
        glVertexAttribPointer(texCoord, 2, GL_FLOAT, GL_FALSE, stride, texCoords);
    
    glDrawElements(GL_TRIANGLES, indices.size(), GL_UNSIGNED_SHORT, &indices[0]);
#endif
    
    /*glDisableVertexAttribArray(m_attributes.Position);
    glDisableVertexAttribArray(m_attributes.Normal);
    if ([texture_ name])
        glDisableVertexAttribArray(m_attributes.TextureCoord);*/

    glDisable(GL_DEPTH_TEST);
    CC_INCREMENT_GL_DRAWS(1);
    
}

-(void)dealloc
{
    [super dealloc];
}

-(void)setTextureName:(NSString *)textureName {
    CCTexture2D *tex = [[CCTextureCache sharedTextureCache] addImage: textureName];
	if( tex ) {
        [self setTexture:tex];
    }
}

-(void)removeTexture {
	if( texture_ ) {
		[texture_ release];
        
		[self updateBlendFunc];
        program = [self BuildProgram:[texture_ name] != 0];
	}
}

#pragma mark ObjNode - CocosNodeTexture protocol

-(void) updateBlendFunc
{
	// it is possible to have an untextured sprite
	if( !texture_ || ! [texture_ hasPremultipliedAlpha] ) {
		blendFunc_.src = GL_SRC_ALPHA;
		blendFunc_.dst = GL_ONE_MINUS_SRC_ALPHA;
	} else {
		blendFunc_.src = CC_BLEND_SRC;
		blendFunc_.dst = CC_BLEND_DST;
	}
}

-(void) setTexture:(CCTexture2D*)texture
{
	// accept texture==nil as argument
	NSAssert( !texture || [texture isKindOfClass:[CCTexture2D class]], @"setTexture expects a CCTexture2D. Invalid argument");
    
	if( texture_ != texture ) {
		[texture_ release];
		texture_ = [texture retain];
        
		[self updateBlendFunc];
        program = [self BuildProgram:[texture_ name] != 0];
	}
}

-(CCTexture2D*) texture
{
	return texture_;
}

@end
