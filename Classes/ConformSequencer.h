//
//  ConformSequencer.h
//  conform
//
//  Created by Johan Halin on 6.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

enum
{
	kStepOff = 0,
	kStepOn,
	kStepMax,
};

static const NSInteger kPatternLength = 16;
static const NSInteger kPatternAmount = 8;
static const NSInteger kBanks = 6;
static const float kBPM = 140.0;

typedef struct
{
	AudioBufferList *bufferList;
	UInt32 lengthInFrames;
}
ConformAudioFile;

typedef void (^SoundPlayedCallback)(NSInteger channel, NSInteger step);
typedef void (^SynthPlayedCallback)(NSInteger step, NSInteger note);

@interface ConformSequencer : NSObject

- (BOOL)configureWithMainCallback:(SoundPlayedCallback)mainCallback kickCallback:(SoundPlayedCallback)kickCallback hihatCallback:(SoundPlayedCallback)hihatCallback clapCallback:(SoundPlayedCallback)clapCallback pulseCallback:(SynthPlayedCallback)pulseCallback bipCallback:(SynthPlayedCallback)bipCallback boopCallback:(SynthPlayedCallback)boopCallback;
- (void)setChannel:(NSInteger)channel step:(NSInteger)step active:(BOOL)active;
- (void)incrementBank;
- (void)decrementBank;
- (void)updateAudioWithSelectedCount:(NSInteger)count;
- (BOOL)start;
- (BOOL)togglePulse;

@end
