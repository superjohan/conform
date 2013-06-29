//
//  ConformSynthChannel.h
//  conform
//
//  Created by Johan Halin on 14.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ConformSequencer.h"

enum
{
	kSpecialNotePlayCurrent = 400,
	kSpecialNoteMax,
};

@interface ConformSynthChannel : NSObject
{
	@public
	float sampleRate;
	NSInteger *pattern;
	NSInteger patternLength;
	float amplitude;
	BOOL halfNote;
	BOOL sweepMode;
}

- (instancetype)initWithCallback:(SynthPlayedCallback)callback;

@end
