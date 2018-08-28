//
//  MTSprite.m
//  MTSprite
//
//  Created by Rinc Liu on 25/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import "MTSprite.h"
#import <Simd/Simd.h>
#import <Metal/Metal.h>
#import "MTUtil.h"

typedef struct {
    packed_float4 position;
    packed_float2 texCoords;
} VertexFormat;

const float VERTICES_DATA[] = {
    -1.0f, +1.0f, 0.0f, 1.0f,   0.0f, 0.0f, //TL
    +1.0f, +1.0f, 0.0f, 1.0f,   1.0f, 0.0f, //TR
    +1.0f, -1.0f, 0.0f, 1.0f,   1.0f, 1.0f, //BR
    -1.0f, -1.0f, 0.0f, 1.0f,   0.0f, 1.0f  //BL
};

typedef struct {
    matrix_float4x4 modelMatrix;
} Uniforms;

const uint16_t INDICES_DATA[] = {
    0, 1, 2,
    0, 3, 2
};

@interface MTSprite()
@property(nonatomic,strong) id<MTLDevice> device;
@property(nonatomic,strong) id<MTLCommandQueue> commandQueue;
@property(nonatomic,strong) id<MTLRenderPipelineState> renderPipelineState;
@property(nonatomic,strong) id<MTLSamplerState> samplerState;
@property(nonatomic,strong) id<MTLBuffer> vertexBuffer, indexBuffer, uniformBuffer;
@property(nonatomic,assign) Uniforms uniforms;
@end

@implementation MTSprite

-(instancetype)initWithDevice:(id<MTLDevice>)device {
    if (self = [super init]) {
        _device = device;
        
        // Commands are submitted to a Metal device through its associated command queue.
        _commandQueue = [device newCommandQueue];
        
        [self prepareBuffersWithDevice:device];
        
        _renderPipelineState = [MTUtil renderPipelineWithDevice:device
                                                         vertexFuncName:@"vertex_func" fragmentFuncName:@"fragment_func"
                                                  vertexDescriptor:[self prepareVertexDescriptor]];
        
        _samplerState = [MTUtil samplerWithDevice:device];
    }
    return self;
}

-(void)renderDrawable:(id<CAMetalDrawable>)drawable inRect:(CGRect)rect {
    if (!_renderPipelineState || !drawable || !_texture) return;
    
    [self updateModelMatrixWithRect:rect];
    [self syncUniforms];
    [self renderDrawable:drawable];
}

-(void)onDestroy {
    //TODO
}

-(MTLVertexDescriptor*)prepareVertexDescriptor {
    MTLVertexDescriptor* vertexDescriptor = [MTLVertexDescriptor new];
    vertexDescriptor.attributes[0].format = MTLVertexFormatFloat4;
    vertexDescriptor.attributes[0].offset = 0;
    vertexDescriptor.attributes[0].bufferIndex = 0;
    vertexDescriptor.attributes[1].format = MTLVertexFormatFloat2;
    vertexDescriptor.attributes[1].offset = sizeof(vector_float4);
    vertexDescriptor.attributes[1].bufferIndex = 0;
    vertexDescriptor.layouts[0].stepFunction = MTLVertexStepFunctionPerVertex;
    vertexDescriptor.layouts[0].stride = sizeof(VertexFormat);
    return vertexDescriptor;
}

-(void)prepareBuffersWithDevice:(id<MTLDevice>)device {
    _vertexBuffer = [device newBufferWithBytes:VERTICES_DATA length:sizeof(VERTICES_DATA) options:MTLResourceOptionCPUCacheModeDefault];
    _indexBuffer = [device newBufferWithBytes:INDICES_DATA length:sizeof(INDICES_DATA) options:MTLResourceOptionCPUCacheModeDefault];
    _uniformBuffer = [device newBufferWithLength:sizeof(Uniforms) options:MTLResourceOptionCPUCacheModeDefault];
}

-(void)updateModelMatrixWithRect:(CGRect)rect {
    GLKMatrix4 translateMatrix = GLKMatrix4MakeTranslation(self.transX, self.transY, 0.0);
    GLKMatrix4 rotateMatrix = GLKMatrix4MakeRotation(GLKMathDegreesToRadians(self.angle) , 0.0, 0.0, -1.0);
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(self.scale, self.scale, 1.0);
    GLKMatrix4 modelMatrix = GLKMatrix4Multiply(translateMatrix, rotateMatrix);
    modelMatrix = GLKMatrix4Multiply(modelMatrix, scaleMatrix);
    _uniforms.modelMatrix = [MTUtil matrixf44WithGLKMatrix4:modelMatrix];
}

-(void)syncUniforms {
    void *bufferPointer = [_uniformBuffer contents];
    memcpy(bufferPointer, &_uniforms, sizeof(Uniforms));
}

-(void)renderDrawable:(id<CAMetalDrawable>)drawable {
    // CommandBuffer is a set of commands that will be executed and encoded in a compact way that the GPU understands.
    id<MTLCommandBuffer> commandBuffer = [_commandQueue commandBuffer];
    
    // RenderPassDescriptor describes the actions Metal should take before and after rendering.(Like glClear & glClearColor)
    MTLRenderPassDescriptor *renderPassDescriptor = [MTUtil renderPassDescriptorWithTexture:drawable.texture];
    
    // RenderCommandEncoder is used to convert from draw calls into the language of the GPU.
    id<MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
    [renderEncoder setCullMode:MTLCullModeFront];
    [renderEncoder setRenderPipelineState:_renderPipelineState];
    
    [renderEncoder setVertexBuffer:_vertexBuffer offset:0 atIndex:0];
    [renderEncoder setVertexBuffer:_uniformBuffer offset:0 atIndex:1];
    [renderEncoder setFragmentTexture:_texture atIndex:0];
    [renderEncoder setFragmentSamplerState:_samplerState atIndex:0];
    
    [renderEncoder drawIndexedPrimitives:MTLPrimitiveTypeTriangleStrip indexCount:_indexBuffer.length/sizeof(uint16_t) indexType:MTLIndexTypeUInt16 indexBuffer:_indexBuffer indexBufferOffset:0];
    
    [renderEncoder endEncoding];
    [commandBuffer presentDrawable:drawable];
    [commandBuffer commit];
}

@end