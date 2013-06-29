//
//  ConformSequencerChannel.m
//  conform
//
//  Created by Johan Halin on 6.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import "ConformSequencerChannel.h"
#import "ConformHelperFunctions.h"
#import <TheAmazingAudioEngine/TheAmazingAudioEngine.h>

@interface ConformSequencerChannel () <AEAudioPlayable>
@property (nonatomic, assign) NSUInteger position;
@property (nonatomic, assign) NSUInteger step;
@property (nonatomic, assign) NSInteger *filePositions;
@property (nonatomic, assign) NSInteger channels;
@property (nonatomic, assign) NSInteger patternLength;
@property (nonatomic, copy) SoundPlayedCallback soundPlayedCallback;
@end

@implementation ConformSequencerChannel

static OSStatus renderCallback(ConformSequencerChannel *this, AEAudioController *audioController, const AudioTimeStamp *time, UInt32 frames, AudioBufferList *audio)
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
			
			if (this->_step >= this->_patternLength)
			{
				this->_step = 0;
			}

			for (NSInteger channel = 0; channel < this->_channels; channel++)
			{
				if (this->patterns[channel][this->_step] == kStepOn)
				{
					dispatch_async(dispatch_get_main_queue(), ^{
						this->_soundPlayedCallback(channel, this->_step);
					});
					
					this->_filePositions[channel] = 0;
				}
			}
		}
		
		for (NSInteger channel = 0; channel < this->_channels; channel++)
		{
			NSInteger bankOffset = this->bank * this->_channels;
			ConformAudioFile file = this->audioFiles[bankOffset + channel];
			AudioBufferList *list = file.bufferList;
			UInt32 length = file.lengthInFrames;
			NSInteger filePosition = this->_filePositions[channel];
			
			if (filePosition >= 0 && filePosition < length)
			{
				l += ((float *)list->mBuffers[0].mData)[filePosition];
				r += ((float *)list->mBuffers[1].mData)[filePosition];
				this->_filePositions[channel]++;
			}
			
			if (filePosition >= length)
			{
				this->_filePositions[channel] = -1;
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

- (instancetype)initWithSoundPlayedCallback:(SoundPlayedCallback)soundPlayedCallback channelAmount:(NSInteger)channelAmount patternLength:(NSInteger)patternLength
{
	if ((self = [super init]))
	{
		_soundPlayedCallback = soundPlayedCallback;
		_position = NSUIntegerMax;
		_step = NSUIntegerMax;
		_channels = channelAmount;
		_patternLength = patternLength;
		
		_filePositions = malloc(sizeof(NSInteger) * patternLength);
		memset(_filePositions, -1, sizeof(NSInteger) * patternLength);
	}
	
	return self;
}

- (void)dealloc
{
	free(patterns);
	free(audioFiles);
	free(_filePositions);
}

@end
