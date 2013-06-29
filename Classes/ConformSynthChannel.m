//
//  ConformSynthChannel.m
//  conform
//
//  Created by Johan Halin on 14.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import "ConformSynthChannel.h"
#import "ConformHelperFunctions.h"
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

@interface ConformSynthChannel () <AEAudioPlayable>
@property (nonatomic, assign) NSUInteger position;
@property (nonatomic, assign) NSUInteger step;
@property (nonatomic, copy) SynthPlayedCallback callback;
@property (nonatomic, assign) NSInteger currentNote;
@property (nonatomic, assign) NSInteger previousNote;
@property (nonatomic, assign) NSInteger notePosition;
@property (nonatomic, assign) float sweepModifier;
@end

@implementation ConformSynthChannel

float noteFrequency(NSInteger note)
{
	return powf(2.0, ((note - 49.0) / 12.0)) * 440.0;
}

static OSStatus renderCallback(ConformSynthChannel *this, AEAudioController *audioController, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
{
	float tickLength = getTickLength(kBPM, this->sampleRate);
	
	for (NSInteger i = 0; i < frames; i++)
	{
		float l = 0;
		float r = 0;
		
		if (this->_position > tickLength)
		{
			this->_position = 0;
			this->_step++;
			
			if (this->_step >= this->patternLength)
			{
				this->_step = 0;
			}
			
			NSInteger currentNote = this->pattern[this->_step];
			if (currentNote > kStepOff && currentNote < kSpecialNotePlayCurrent)
			{
				this->_notePosition = 0;
				this->_previousNote = this->_currentNote;
				this->_currentNote = this->sweepMode ? currentNote + (arc4random() % 12) : currentNote;
				
				dispatch_async(dispatch_get_main_queue(), ^{
					this->_callback(this->_step, currentNote);
				});
			}
			else if (currentNote == kSpecialNotePlayCurrent)
			{
				if (this->_currentNote != kSpecialNotePlayCurrent)
				{
					this->_previousNote = this->_currentNote;
				}
				
				this->_currentNote = currentNote;
			}
			else
			{
				this->_currentNote = kStepOff;
				this->_notePosition = 0;
				this->_sweepModifier = 0;
			}
		}
		
		if (this->_currentNote > kStepOff)
		{
			NSInteger note = this->_currentNote == kSpecialNotePlayCurrent ? this->_previousNote : this->_currentNote;
			float value = 0;
			if (note > kStepOff && note < kSpecialNotePlayCurrent)
			{
				if (this->halfNote && this->_position >= tickLength / 2)
				{
					value = 0;
				}
				else
				{
					float frequency = noteFrequency(note);
					
					if (this->sweepMode)
					{
						frequency += this->_sweepModifier;
					}
					
					value = sinf((M_PI * 2.0) * ((this->_notePosition / this->sampleRate) * frequency)) * this->amplitude;
				}
				
				l = value;
				r = l;
				this->_notePosition++;
				this->_sweepModifier -= 0.0003;
			}
		}
		
		clampStereo(&l, &r, 1.0);
		
		((float *)audio->mBuffers[0].mData)[i] = l;
		((float *)audio->mBuffers[1].mData)[i] = r;
		
		this->_position++;
	}

	return noErr;
}

- (AEAudioControllerRenderCallback)renderCallback
{
	return &renderCallback;
}

- (instancetype)initWithCallback:(SynthPlayedCallback)callback;
{
	if ((self = [super init]))
	{
		_position = NSUIntegerMax;
		_step = NSUIntegerMax;
		_callback = callback;
		amplitude = 1.0;
		halfNote = NO;
	}
	
	return self;
}

@end
