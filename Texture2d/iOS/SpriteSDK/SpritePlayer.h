//
//  SpritePlayer.h
//  SpriteSDK
//
//  Created by Rinc Liu on 20/8/2018.
//  Copyright © 2018 RINC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MTSpriteView.h"
#import "GLSpriteView.h"

@protocol SpritePlayerDelegate<NSObject>

@optional
-(void)onSpritePlayerStarted;

@optional
-(void)onSpritePlayerPaused;

@optional
-(void)onSpritePlayerResumed;

@optional
-(void)onSpritePlayerStopped;

@end

@interface SpritePlayer : NSObject

@property(nonatomic,weak) id<SpritePlayerDelegate> delegate;

@property(nonatomic,assign) BOOL skipFrame;

-(instancetype)initWithMTSpriteView:(MTSpriteView*)spriteView NS_AVAILABLE_IOS(9_0);

-(instancetype)initWithGLSpriteView:(GLSpriteView*)spriteView NS_DEPRECATED_IOS(5_0, 12_0, "OpenGL ES API is deprecated, use Metal API 'initWithMTSpriteView:' instead.");

-(void)playResource:(NSString*)resource;

-(void)onPause;

-(void)onResume;

-(void)onDestroy;

@end
