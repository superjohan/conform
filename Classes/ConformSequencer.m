//
//  ConformSequencer.m
//  conform
//
//  Created by Johan Halin on 6.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import "ConformSequencer.h"
#import "ConformSequencerChannel.h"
#import "ConformSynthChannel.h"

@interface ConformSequencer ()
@property (nonatomic) AEAudioController *audioController;
@property (nonatomic) NSArray *channels;
@property (nonatomic) AEAudioUnitFilter *pulseReverb;
@property (nonatomic) AEAudioUnitFilter *boopReverb;
@property (nonatomic) BOOL *channelActivity;
@end

enum
{
	kChannelMain = 0,
	kChannelKick,
	kChannelHihat,
	kChannelClap,
	kChannelPulse,
	kChannelBip,
	kChannelBoop,
	kChannelMax,
};

enum
{
	kActiveChannelKick = 0,
	kActiveChannelHihat,
	kActiveChannelClap,
	kActiveChannelBip,
	kActiveChannelBoop,
	kActiveChannelMax,
};

@implementation ConformSequencer

#pragma mark - Private

- (void)_clearPattern:(NSInteger *)pattern
{
	memset(pattern, kStepOff, sizeof(NSInteger) * kPatternLength);
}

- (ConformSequencerChannel *)_channelWithCallback:(SoundPlayedCallback)callback filename:(NSString *)filename
{
	ConformSequencerChannel *channel = [[ConformSequencerChannel alloc] initWithSoundPlayedCallback:callback channelAmount:1 patternLength:kPatternLength];
	ConformAudioFile *file = malloc(sizeof(ConformAudioFile));
	NSURL *url = [[NSBundle mainBundle] URLForResource:filename withExtension:@"caf"];
	AEAudioFileLoaderOperation *operation = [[AEAudioFileLoaderOperation alloc] initWithFileURL:url targetAudioDescription:_audioController.audioDescription];
	[operation start];
	
	if (operation.error != nil)
	{
		NSLog(@"Loading the file '%@' failed: %@", filename, operation.error);
		free(file);
		return nil;
	}
	
	AudioBufferList *bufferList = operation.bufferList;
	UInt32 length = operation.lengthInFrames;
	ConformAudioFile audioFile = { .bufferList = bufferList, .lengthInFrames = length };
	file[0] = audioFile;
	
	NSInteger **patterns = malloc(sizeof(NSInteger *));
	size_t size = sizeof(NSInteger);
	patterns[0] = malloc(size * kPatternLength);
	memset(patterns[0], kStepOff, size * kPatternLength);
	
	channel->audioFiles = file;
	channel->patterns = patterns;
	channel->sampleRate = self.audioController.audioDescription.mSampleRate;
	
	return channel;
}

- (ConformSynthChannel *)_pulseChannelWithCallback:(SynthPlayedCallback)callback
{
	ConformSynthChannel *pulseChannel = [[ConformSynthChannel alloc] initWithCallback:callback];
	size_t patternSize = sizeof(NSInteger) * kPatternLength;
	NSInteger *pattern = malloc(patternSize);
	memset(pattern, kStepOff, patternSize);
	pattern[0] = 85;
	
	pulseChannel->pattern = pattern;
	pulseChannel->sampleRate = self.audioController.audioDescription.mSampleRate;
	pulseChannel->patternLength = kPatternLength;
	pulseChannel->amplitude = 0.5;
	
	AudioComponentDescription reverbComponent = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Effect, kAudioUnitSubType_Reverb2);
	NSError *reverbError = nil;
	self.pulseReverb = [[AEAudioUnitFilter alloc] initWithComponentDescription:reverbComponent audioController:self.audioController error:&reverbError];
	if (self.pulseReverb == nil)
	{
		NSLog(@"Error creating reverb: %@", reverbError);
		return nil;
	}
	
	AudioUnitSetParameter(self.pulseReverb.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, 60.0, 0);
	AudioUnitSetParameter(self.pulseReverb.audioUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, 3.0, 0);
	AudioUnitSetParameter(self.pulseReverb.audioUnit, kReverb2Param_DecayTimeAtNyquist, kAudioUnitScope_Global, 0, 3.0, 0);

	return pulseChannel;
}

- (ConformSynthChannel *)_bipChannelWithCallback:(SynthPlayedCallback)callback
{
	ConformSynthChannel *bipChannel = [[ConformSynthChannel alloc] initWithCallback:callback];
	size_t patternSize = sizeof(NSInteger) * kPatternLength;
	NSInteger *pattern = malloc(patternSize);
	memset(pattern, kStepOff, patternSize);

	bipChannel->pattern = pattern;
	bipChannel->sampleRate = self.audioController.audioDescription.mSampleRate;
	bipChannel->patternLength = kPatternLength;
	bipChannel->amplitude = 0.1;
	bipChannel->halfNote = YES;
	
	return bipChannel;
}

- (ConformSynthChannel *)_boopChannelWithCallback:(SynthPlayedCallback)callback
{
	ConformSynthChannel *boopChannel = [[ConformSynthChannel alloc] initWithCallback:callback];
	size_t patternSize = sizeof(NSInteger) * (kPatternLength * 2);
	NSInteger *pattern = malloc(patternSize);
	memset(pattern, kStepOff, patternSize);

	boopChannel->pattern = pattern;
	boopChannel->sampleRate = self.audioController.audioDescription.mSampleRate;
	boopChannel->patternLength = kPatternLength * 2;
	boopChannel->amplitude = 0.3;
	boopChannel->sweepMode = YES;
	
	AudioComponentDescription reverbComponent = AEAudioComponentDescriptionMake(kAudioUnitManufacturer_Apple, kAudioUnitType_Effect, kAudioUnitSubType_Reverb2);
	NSError *reverbError = nil;
	self.boopReverb = [[AEAudioUnitFilter alloc] initWithComponentDescription:reverbComponent audioController:self.audioController error:&reverbError];
	if (self.boopReverb == nil)
	{
		NSLog(@"Error creating reverb: %@", reverbError);
		return nil;
	}
	
	AudioUnitSetParameter(self.boopReverb.audioUnit, kReverb2Param_DryWetMix, kAudioUnitScope_Global, 0, 60.0, 0);
	AudioUnitSetParameter(self.boopReverb.audioUnit, kReverb2Param_DecayTimeAt0Hz, kAudioUnitScope_Global, 0, 3.0, 0);
	AudioUnitSetParameter(self.boopReverb.audioUnit, kReverb2Param_DecayTimeAtNyquist, kAudioUnitScope_Global, 0, 3.0, 0);

	return boopChannel;
}

- (ConformSequencerChannel *)_mainChannelWithCallback:(SoundPlayedCallback)mainCallback
{
	ConformSequencerChannel *mainChannel = [[ConformSequencerChannel alloc] initWithSoundPlayedCallback:mainCallback channelAmount:kPatternAmount patternLength:kPatternLength];
	{
		ConformAudioFile *files = malloc(sizeof(ConformAudioFile) * (kPatternAmount * kBanks));
		for (NSInteger i = 0; i < kPatternAmount * kBanks; i++)
		{
			NSURL *url = [[NSBundle mainBundle] URLForResource:[NSString stringWithFormat:@"dry%d", i + 1] withExtension:@"caf"];
			AEAudioFileLoaderOperation *operation = [[AEAudioFileLoaderOperation alloc] initWithFileURL:url targetAudioDescription:_audioController.audioDescription];
			[operation start];
			
			if (operation.error != nil)
			{
				NSLog(@"Loading a sound failed: %@", operation.error);
				[self.audioController stop];
				free(files);
				return nil;
			}
			
			AudioBufferList *bufferList = operation.bufferList;
			UInt32 length = operation.lengthInFrames;
			ConformAudioFile audioFile = { .bufferList = bufferList, .lengthInFrames = length };
			files[i] = audioFile;
		}
		
		NSInteger **patterns = malloc(sizeof(NSInteger *) * kPatternAmount);
		for (NSInteger i = 0; i < kPatternAmount; i++)
		{
			size_t size = sizeof(NSInteger) * kPatternLength;
			patterns[i] = malloc(size);
			memset(patterns[i], kStepOff, size);
		}
		
		mainChannel->audioFiles = files;
		mainChannel->patterns = patterns;
		mainChannel->sampleRate = self.audioController.audioDescription.mSampleRate;
	}
	
	return mainChannel;
}

- (void)_setChannel:(NSInteger)channel active:(BOOL)active
{
	if (channel == kActiveChannelKick)
	{
		[self _generateKickPattern:!active];
	}
	else if (channel == kActiveChannelHihat)
	{
		[self _generateHihatPattern:!active];
	}
	else if (channel == kActiveChannelClap)
	{
		[self _generateClapPattern:!active];
	}
	else if (channel == kActiveChannelBip)
	{
		[self _generateBipPattern:!active];
	}
	else if (channel == kActiveChannelBoop)
	{
		[self _activateBoopChannel:!active];
	}
}

- (void)_generateKickPattern:(BOOL)clear
{
	if ( ! clear && self.channelActivity[kActiveChannelKick])
	{
		return;
	}
	
	ConformSequencerChannel *channel = self.channels[kChannelKick];
	
	[self _clearPattern:channel->patterns[0]];
	
	if ( ! clear)
	{
		channel->patterns[0][0] = kStepOn;
		
		for (NSInteger i = 0; i < 3; i++)
		{
			NSInteger step = 0;
			do
			{
				step = (arc4random() % (kPatternLength - 1)) + 1;
			}
			while (channel->patterns[0][step] == kStepOn);
			
			channel->patterns[0][step] = kStepOn;
		}
	}
	
	self.channelActivity[kActiveChannelKick] = !clear;
}

- (void)_generateHihatPattern:(BOOL)clear
{
	if ( ! clear && self.channelActivity[kActiveChannelHihat])
	{
		return;
	}
	
	ConformSequencerChannel *channel = self.channels[kChannelHihat];
	
	[self _clearPattern:channel->patterns[0]];
	
	if ( ! clear)
	{
		for (NSInteger i = 0; i < 10; i++)
		{
			NSInteger step = 0;
			do
			{
				step = arc4random() % kPatternLength;
			}
			while (channel->patterns[0][step] == kStepOn);
			
			channel->patterns[0][step] = kStepOn;
		}
	}
	
	self.channelActivity[kActiveChannelHihat] = !clear;
}

- (void)_generateClapPattern:(BOOL)clear
{
	if ( ! clear && self.channelActivity[kActiveChannelClap])
	{
		return;
	}
	
	ConformSequencerChannel *channel = self.channels[kChannelClap];
	
	[self _clearPattern:channel->patterns[0]];
	
	if ( ! clear)
	{
		for (NSInteger i = 0; i < 2; i++)
		{
			NSInteger step = 0;
			do
			{
				step = (arc4random() % (kPatternLength - 1)) + 1;
			}
			while (channel->patterns[0][step] == kStepOn || step < 3);
			
			channel->patterns[0][step] = kStepOn;
		}
	}
	
	self.channelActivity[kActiveChannelClap] = !clear;
}

- (void)_generateBipPattern:(BOOL)clear
{
	if ( ! clear && self.channelActivity[kActiveChannelBip])
	{
		return;
	}
	
	ConformSynthChannel *channel = self.channels[kChannelBip];
	
	[self _clearPattern:channel->pattern];
	
	if ( ! clear)
	{
		for (NSInteger i = 0; i < 10; i++)
		{
			NSInteger note = 93;
			NSInteger step = 0;
			do
			{
				step = arc4random() % kPatternLength;
			}
			while (channel->pattern[step] == note);
			
			channel->pattern[step] = note;
		}
	}
	
	self.channelActivity[kActiveChannelBip] = !clear;
}

- (void)_activateBoopChannel:(BOOL)clear
{
	ConformSynthChannel *channel = self.channels[kChannelBoop];
	
	if (clear)
	{
		[self _clearPattern:channel->pattern];
	}
	else
	{
		channel->pattern[0] = 50;
		channel->pattern[1] = kSpecialNotePlayCurrent;
		channel->pattern[2] = kSpecialNotePlayCurrent;
		channel->pattern[3] = kSpecialNotePlayCurrent;
		channel->pattern[4] = kSpecialNotePlayCurrent;
		channel->pattern[5] = kSpecialNotePlayCurrent;
		channel->pattern[6] = kSpecialNotePlayCurrent;
		channel->pattern[7] = kSpecialNotePlayCurrent;
	}
	
	self.channelActivity[kActiveChannelBoop] = !clear;
}

#pragma mark - Public

- (BOOL)configureWithMainCallback:(SoundPlayedCallback)mainCallback kickCallback:(SoundPlayedCallback)kickCallback hihatCallback:(SoundPlayedCallback)hihatCallback clapCallback:(SoundPlayedCallback)clapCallback pulseCallback:(SynthPlayedCallback)pulseCallback bipCallback:(SynthPlayedCallback)bipCallback boopCallback:(SynthPlayedCallback)boopCallback
{
	self.audioController = [[AEAudioController alloc] initWithAudioDescription:[AEAudioController nonInterleavedFloatStereoAudioDescription]];
	
	ConformSequencerChannel *mainChannel = [self _mainChannelWithCallback:mainCallback];
	if (mainChannel == nil)
	{
		return NO;
	}
	
	ConformSequencerChannel *kickChannel = [self _channelWithCallback:kickCallback filename:@"bd1"];
	if (kickChannel == nil)
	{
		return NO;
	}

	ConformSequencerChannel *hihatChannel = [self _channelWithCallback:hihatCallback filename:@"ch1"];
	if (hihatChannel == nil)
	{
		return NO;
	}

	ConformSequencerChannel *clapChannel = [self _channelWithCallback:clapCallback filename:@"cp1"];
	if (clapChannel == nil)
	{
		return NO;
	}
	
	ConformSynthChannel *pulseChannel = [self _pulseChannelWithCallback:pulseCallback];
	if (pulseChannel == nil)
	{
		return NO;
	}
	
	ConformSynthChannel *bipChannel = [self _bipChannelWithCallback:bipCallback];
	if (bipChannel == nil)
	{
		return NO;
	}
	
	ConformSynthChannel *boopChannel = [self _boopChannelWithCallback:boopCallback];
	if (boopChannel == nil)
	{
		return NO;
	}
	
	NSArray *channels = [NSArray arrayWithObjects:mainChannel, kickChannel, hihatChannel, clapChannel, pulseChannel, bipChannel, boopChannel, nil];
	[self.audioController addChannels:channels];
	self.channels = channels;

	[self.audioController addFilter:self.pulseReverb toChannel:(id)pulseChannel];
	[self.audioController addFilter:self.boopReverb toChannel:(id)boopChannel];
	
	size_t activeChannelSize = kActiveChannelMax * sizeof(BOOL);
	self.channelActivity = malloc(activeChannelSize);
	memset(self.channelActivity, NO, activeChannelSize);
	
	return YES;
}

- (void)setChannel:(NSInteger)channel step:(NSInteger)step active:(BOOL)active
{
//	NSLog(@"chan %d, step %d, active %@", channel, step, active ? @"YES" : @"NO");
	
	NSInteger state = active ? kStepOn : kStepOff;	
	ConformSequencerChannel *chan = self.channels[kChannelMain];
	chan->patterns[channel][step] = state;
}

- (void)incrementBank
{
	ConformSequencerChannel *channel = self.channels[kChannelMain];
	channel->bank++;
	if (channel->bank >= kBanks)
	{
		channel->bank = 0;
	}
}

- (void)decrementBank
{
	ConformSequencerChannel *channel = self.channels[kChannelMain];
	channel->bank--;
	if (channel->bank < 0)
	{
		channel->bank = kBanks - 1;
	}
}

- (void)updateAudioWithSelectedCount:(NSInteger)count
{
	NSInteger elements = (NSInteger)floor(count / kPatternLength);
	if (elements > kActiveChannelMax)
	{
		return;
	}
	
	NSInteger active = 0;

	for (NSInteger i = 0; i < kActiveChannelMax; i++)
	{
		if (self.channelActivity[i] == YES)
		{
			active++;
		}
	}
	
	
	if (elements == active) // alles ok
	{
		return;
	}
	else if (elements < active) // deactivate some channels
	{
		for (NSInteger i = 0; i < active - elements; i++)
		{
			NSInteger channel = 0;
			do
			{
				channel = arc4random() % kActiveChannelMax;
			}
			while (self.channelActivity[channel] == NO);
			
			[self _setChannel:channel active:NO];
		}
	}
	else if (elements > active) // activate some channels
	{
		for (NSInteger i = 0; i < elements - active; i++)
		{
			NSInteger channel = 0;
			do
			{
				channel = arc4random() % kActiveChannelMax;
			}
			while (self.channelActivity[channel] == YES);
			
			[self _setChannel:channel active:YES];
		}
	}
}

- (BOOL)start
{
	NSError *error = nil;
	if ( ! [self.audioController start:&error])
	{
		NSLog(@"%@", error);
		return NO;
	}
	
	return YES;
}

- (void)dealloc
{
	free(_channelActivity);
}

@end
