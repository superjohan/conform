//
//  ConformSequencerChannel.h
//  conform
//
//  Created by Johan Halin on 6.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConformSequencer.h"

@interface ConformSequencerChannel : NSObject
{
	@public
	NSInteger **patterns;
	ConformAudioFile *audioFiles;
	NSInteger bank;
	float sampleRate;
}

- (instancetype)initWithSoundPlayedCallback:(SoundPlayedCallback)soundPlayedCallback channelAmount:(NSInteger)channelAmount patternLength:(NSInteger)patternLength;

@end
