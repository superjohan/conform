//
//  ConformViewController.m
//  conform
//
//  Created by Johan Halin on 13.11.2010.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import "ConformViewController.h"
#import "ConformSequencer.h"
#import <QuartzCore/QuartzCore.h>

@interface ConformViewController ()
@property (nonatomic) UIView *buttonContainer;
@property (nonatomic) ConformSequencer *sequencer;
@property (nonatomic) UIButton *pulseButton;
@property (nonatomic) NSArray *hihatViews;
@property (nonatomic) UIView *hihatContainer;
@property (nonatomic) NSArray *bipButtons;
@property (nonatomic) UIView *boopView;
@property (nonatomic) UIImageView *defaultImageView;
@end

@implementation ConformViewController

const NSInteger kProtectedSubviewTag = 130;
const NSInteger kRandomizeButtonTag = 500;
const NSInteger kClearButtonTag = 501;
const NSInteger kResetButtonTag = 502;
const NSInteger kDefaultTag = 503;
const NSInteger kInfoButtonTag = 504;
const NSInteger kGenericTag = 505;
const CGFloat kLeftStart = 77.0;
const CGFloat kTopStart = 36.0;
const CGFloat kButtonWidth = 100.0;
const CGFloat kButtonHeight = 35.0;
const CGFloat kButtonXPadding = 10.0;
const CGFloat kButtonYPadding = 2.0;
const CGFloat kFunctionButtonTop = 665.0;

NSString * const kHihatLayerAnimationKey = @"hihatAnimation";

#pragma mark - Private

- (void)_clearIBOutlets
{
	self.buttonContainer = nil;
}

- (void)_setButtonSelected:(BOOL)selected tag:(NSInteger)tag
{
	if ([[self.buttonContainer viewWithTag:tag] isKindOfClass:[UIButton class]])
	{
		UIButton *button = (UIButton *)[self.buttonContainer viewWithTag:tag];
		button.selected = selected;
		
		tag--;
		NSInteger step = (tag % kPatternLength);
		NSInteger channel = (tag - step) / kPatternLength;
		
		[self.sequencer setChannel:channel step:step active:selected];
	}
}

- (void)_setSelectionForButtonWithTag:(NSInteger)tag
{
	if ([[self.buttonContainer viewWithTag:tag] isKindOfClass:[UIButton class]])
	{	
		UIButton *button = (UIButton *)[self.buttonContainer viewWithTag:tag];
		button.selected = !button.selected;
		
		[self _setButtonSelected:button.selected tag:tag];
	}
}

- (void)_forceSelectionForButtonWithTag:(NSInteger)tag
{
	[self _setButtonSelected:YES tag:tag];
}

- (BOOL)_buttonSelectedWithTag:(NSInteger)tag
{
	if ([[self.buttonContainer viewWithTag:tag] isKindOfClass:[UIButton class]])
	{
		UIButton *button = (UIButton *)[self.buttonContainer viewWithTag:tag];
		return button.selected;
	}
	
	return NO;
}

- (void)_setHighlightForButtonWithTag:(NSInteger)tag
{
	if ([[self.buttonContainer viewWithTag:tag] isKindOfClass:[UIButton class]])
	{
		[[self.buttonContainer viewWithTag:tag] setAlpha:.5];
	}
}

- (void)_removeHighlightForButtonWithTag:(NSInteger)tag
{
	if ([[self.buttonContainer viewWithTag:tag] isKindOfClass:[UIButton class]])
	{
		[[self.buttonContainer viewWithTag:tag] setAlpha:1];
	}
}

- (void)_buttonTouched:(id)sender
{
	NSInteger tag = [sender tag];
	
	[self _setSelectionForButtonWithTag:tag];
	[self _updateAudioStatus];
}

- (void)_randomizeButtonTouched
{
	for (id subview in [self.buttonContainer subviews])
	{
		if ([subview tag] < kProtectedSubviewTag)
		{
			BOOL selected = arc4random() % 2;
			
			[self _setButtonSelected:selected tag:[subview tag]];
		}
	}
	
	[self _updateAudioStatus];
}

- (void)_clearButtonTouched
{
	for (id subview in [self.buttonContainer subviews])
	{
		if ([subview tag] < kProtectedSubviewTag)
		{
			[self _setButtonSelected:NO tag:[subview tag]];
		}
	}
	
	[self _updateAudioStatus];
}

- (void)_moveButtonWithTag:(NSInteger)tag
{	
	UIButton *button = (UIButton *)[self.buttonContainer viewWithTag:tag];
	[self.buttonContainer bringSubviewToFront:button];

	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
		button.frame = [self _frameForButtonOnColumn:(arc4random() % 8) row:((arc4random() % 16) + 1)];
	}];
}

- (CGRect)_frameForButtonOnColumn:(NSInteger)column row:(NSInteger)row
{
	return CGRectMake(kLeftStart + ((kButtonWidth + kButtonXPadding) * column),
					  kTopStart + ((kButtonHeight + kButtonYPadding) * row),
					  kButtonWidth,
					  kButtonHeight);
}

- (void)_layoutButtons
{
	for (id subview in [self.buttonContainer subviews])
	{
		if ([subview tag] < kProtectedSubviewTag)
		{
			[subview removeFromSuperview];
		}
	}
	
	NSInteger tagCounter = 0;
	
	for (NSInteger i = 0; i < 8; i++)
	{
		for (NSInteger j = 0; j < 16; j++)
		{
			UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
			button.frame = [self _frameForButtonOnColumn:i row:(j + 1)];
			button.contentMode = UIViewContentModeScaleToFill;
			[button setBackgroundImage:[UIImage imageNamed:@"button.png"] forState:UIControlStateNormal];
			[button setBackgroundImage:[UIImage imageNamed:@"button-highlight.png"] forState:UIControlStateHighlighted];
			[button setBackgroundImage:[UIImage imageNamed:@"button-active.png"] forState:UIControlStateSelected];
			[button addTarget:self action:@selector(_buttonTouched:) forControlEvents:UIControlEventTouchUpInside];
			button.tag = tagCounter + 1;
			[self.buttonContainer addSubview:button];
			
			tagCounter = tagCounter + 1;
		}
	}
}

- (void)_layoutButtonsWithoutRemoval
{
	__block NSInteger tagCounter = 0;

	[UIView animateWithDuration:UINavigationControllerHideShowBarDuration animations:^{
		for (NSInteger i = 0; i < 8; i++)
		{
			for (NSInteger j = 0; j < 16; j++)
			{
				UIButton *button = (UIButton *)[self.buttonContainer viewWithTag:tagCounter + 1];
				button.frame = [self _frameForButtonOnColumn:i row:(j + 1)];
				button.tag = tagCounter + 1;
				tagCounter = tagCounter + 1;
			}
		}
	}];
}

- (void)_resetButtonTouched
{
	[self _clearButtonTouched];
	[self _layoutButtonsWithoutRemoval];
}

- (void)_downButtonTouched:(id)sender
{
	if ([sender isKindOfClass:[UIButton class]])
	{
		UIButton *downButton = sender;
		CGRect frame = downButton.frame;
		
		for (id subview in [self.buttonContainer subviews])
		{
			if ([subview isKindOfClass:[UIButton class]] && [subview tag] < kProtectedSubviewTag)
			{
				UIButton *button = subview;
				
				// +-1 pixel margin should be enough :)
				if (frame.origin.x - 1 < button.frame.origin.x && frame.origin.x + 1 > button.frame.origin.x)
				{
					[self _forceSelectionForButtonWithTag:button.tag];
				}
			}
		}
	}
	
	[self _updateAudioStatus];
}

- (void)_updateAudioStatus
{
	NSInteger selectedCount = 0;
	
	for (id subview in [self.buttonContainer subviews])
	{
		UIButton *button = (UIButton *)subview;

		if (button.tag < kProtectedSubviewTag && button.selected)
		{
			selectedCount++;
		}
	}
	
	[self.sequencer updateAudioWithSelectedCount:selectedCount];
}

- (void)_allButtonTouched
{
	for (id subview in [self.buttonContainer subviews])
	{
		if ([subview isKindOfClass:[UIButton class]] && [subview tag] < kProtectedSubviewTag)
		{
			[self _moveButtonWithTag:[subview tag]];
		}
	}
}

- (void)_bankMinusTouched
{
	[self.sequencer decrementBank];
}

- (void)_bankPlusTouched
{
	[self.sequencer incrementBank];
}

- (void)_selectionMinusTouched
{
	NSMutableArray *buttons = [[NSMutableArray alloc] init];
	for (id subview in [self.buttonContainer subviews])
	{
		if ([subview isKindOfClass:[UIButton class]] && [subview tag] < kProtectedSubviewTag)
		{
			UIButton *button = (UIButton *)subview;
			if (button.selected)
			{
				[buttons addObject:button];
			}
		}
	}
	
	if ([buttons count] == 0)
	{
		return;
	}
	
	for (NSInteger i = 0; i < 8; i++)
	{
		if ([buttons count] == 0)
		{
			break;
		}
		
		NSInteger index = arc4random() % [buttons count];
		UIButton *button = buttons[index];
		[self _setButtonSelected:NO tag:button.tag];
	}
	
	[self _updateAudioStatus];
}

- (void)_layoutInterface
{
	[self _layoutButtons];
		
	for (NSInteger i = 0; i < 8; i++)
	{
		UIButton *downButton = [UIButton buttonWithType:UIButtonTypeCustom];
		downButton.frame = [self _frameForButtonOnColumn:i row:0];
		downButton.tag = kGenericTag;
		[downButton setBackgroundImage:[UIImage imageNamed:@"down"] forState:UIControlStateNormal];
		[downButton setBackgroundImage:[UIImage imageNamed:@"down-h"] forState:UIControlStateHighlighted];
		[downButton addTarget:self action:@selector(_downButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
		[self.buttonContainer addSubview:downButton];
	}
	
	NSMutableArray *bips = [[NSMutableArray alloc] init];
	for (NSInteger i = 0; i < 16; i++)
	{
		for (NSInteger j = 0; j < 2; j++)
		{
			UIButton *bipButton = [UIButton buttonWithType:UIButtonTypeCustom];
			NSInteger column = (j == 0) ? -1 : 8;
			bipButton.frame = [self _frameForButtonOnColumn:column row:(i + 1)];
			bipButton.contentMode = UIViewContentModeScaleToFill;
			[bipButton setBackgroundImage:[UIImage imageNamed:@"button"] forState:UIControlStateNormal];
			bipButton.tag = kGenericTag;
			bipButton.alpha = 0;
			[self.buttonContainer addSubview:bipButton];
			[bips addObject:bipButton];
		}
	}
	self.bipButtons = bips;
	
	NSInteger bottomRow = 17;
	
	UIButton *randomButton = [UIButton buttonWithType:UIButtonTypeCustom];
	randomButton.frame = [self _frameForButtonOnColumn:2 row:bottomRow];
	randomButton.tag = kRandomizeButtonTag;
	[randomButton setBackgroundImage:[UIImage imageNamed:@"rs"] forState:UIControlStateNormal];
	[randomButton setBackgroundImage:[UIImage imageNamed:@"rs-h"] forState:UIControlStateHighlighted];
	[randomButton addTarget:self action:@selector(_randomizeButtonTouched) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonContainer addSubview:randomButton];

	UIButton *resetButton = [UIButton buttonWithType:UIButtonTypeCustom];
	resetButton.frame = [self _frameForButtonOnColumn:0 row:bottomRow];
	resetButton.tag = kResetButtonTag;
	[resetButton setBackgroundImage:[UIImage imageNamed:@"reset"] forState:UIControlStateNormal];
	[resetButton setBackgroundImage:[UIImage imageNamed:@"reset-h"] forState:UIControlStateHighlighted];
	[resetButton addTarget:self action:@selector(_resetButtonTouched) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonContainer addSubview:resetButton];

	UIButton *allButton = [UIButton buttonWithType:UIButtonTypeCustom];
	allButton.frame = [self _frameForButtonOnColumn:1 row:bottomRow];
	allButton.tag = kGenericTag;
	[allButton setBackgroundImage:[UIImage imageNamed:@"rp"] forState:UIControlStateNormal];
	[allButton setBackgroundImage:[UIImage imageNamed:@"rp-h"] forState:UIControlStateHighlighted];
	[allButton addTarget:self action:@selector(_allButtonTouched) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonContainer addSubview:allButton];

	UIButton *bankMinusButton = [UIButton buttonWithType:UIButtonTypeCustom];
	bankMinusButton.frame = [self _frameForButtonOnColumn:3 row:bottomRow];
	bankMinusButton.tag = kGenericTag;
	[bankMinusButton setBackgroundImage:[UIImage imageNamed:@"bankminus"] forState:UIControlStateNormal];
	[bankMinusButton setBackgroundImage:[UIImage imageNamed:@"bankminus-h"] forState:UIControlStateHighlighted];
	[bankMinusButton addTarget:self action:@selector(_bankMinusTouched) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonContainer addSubview:bankMinusButton];
	
	UIButton *bankPlusButton = [UIButton buttonWithType:UIButtonTypeCustom];
	bankPlusButton.frame = [self _frameForButtonOnColumn:4 row:bottomRow];
	bankPlusButton.tag = kGenericTag;
	[bankPlusButton setBackgroundImage:[UIImage imageNamed:@"bankplus"] forState:UIControlStateNormal];
	[bankPlusButton setBackgroundImage:[UIImage imageNamed:@"bankplus-h"] forState:UIControlStateHighlighted];
	[bankPlusButton addTarget:self action:@selector(_bankPlusTouched) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonContainer addSubview:bankPlusButton];
	
	UIButton *selectionMinusButton = [UIButton buttonWithType:UIButtonTypeCustom];
	selectionMinusButton.frame = [self _frameForButtonOnColumn:5 row:bottomRow];
	selectionMinusButton.tag = kGenericTag;
	[selectionMinusButton setBackgroundImage:[UIImage imageNamed:@"sminus"] forState:UIControlStateNormal];
	[selectionMinusButton setBackgroundImage:[UIImage imageNamed:@"sminus-h"] forState:UIControlStateHighlighted];
	[selectionMinusButton addTarget:self action:@selector(_selectionMinusTouched) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonContainer addSubview:selectionMinusButton];
	
	self.pulseButton = [UIButton buttonWithType:UIButtonTypeCustom];
	self.pulseButton.frame = [self _frameForButtonOnColumn:7 row:bottomRow];
	self.pulseButton.tag = kGenericTag;
	[self.pulseButton setBackgroundColor:[UIColor blackColor]];
	self.pulseButton.alpha = 0;
	[self.buttonContainer addSubview:self.pulseButton];
	
	UIButton *hiddenPulseButton = [UIButton buttonWithType:UIButtonTypeCustom];
	hiddenPulseButton.frame = self.pulseButton.frame;
	hiddenPulseButton.tag = kGenericTag;
	hiddenPulseButton.backgroundColor = [UIColor clearColor];
	[hiddenPulseButton addTarget:self action:@selector(_pulseButtonTouched:) forControlEvents:UIControlEventTouchUpInside];
	[self.buttonContainer addSubview:hiddenPulseButton];
	
	NSMutableArray *hihats = [[NSMutableArray alloc] init];
	CGFloat offset = 200.0;
	CGRect hihatRect = CGRectMake(-offset,
								  0,
								  MAX(self.view.bounds.size.width, self.view.bounds.size.height) + (offset * 2.0),
								  MIN(self.view.bounds.size.width, self.view.bounds.size.height));
	self.hihatContainer = [[UIView alloc] initWithFrame:hihatRect];
	self.hihatContainer.backgroundColor = [UIColor whiteColor];
	[self.view insertSubview:self.hihatContainer belowSubview:self.buttonContainer];
	for (NSInteger i = 0; i < kPatternLength; i++)
	{
		CGFloat height = self.hihatContainer.bounds.size.height / kPatternLength;
		CGRect rect = CGRectMake(0,
								 i * height,
								 self.hihatContainer.bounds.size.width,
								 height);
		UIView *view = [[UIView alloc] initWithFrame:rect];
		view.backgroundColor = [UIColor blackColor];
		view.alpha = 0;
		[hihats addObject:view];
		[self.hihatContainer addSubview:view];
	}
	self.hihatViews = hihats;
	
	self.boopView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, MAX(self.view.bounds.size.width, self.view.bounds.size.height), 0)];
	self.boopView.backgroundColor = [UIColor blackColor];
	self.boopView.alpha = 0;
	[self.view insertSubview:self.boopView aboveSubview:self.hihatContainer];
}

- (void)_pulseButtonTouched:(id)sender
{
	BOOL pulse = [self.sequencer togglePulse];
	if ( ! pulse)
	{
		self.pulseButton.alpha = 0.5;
	}
}

- (void)_addAnimationToHihatLayer
{
	CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"transform.rotation.z"];
	animation.toValue = [NSNumber numberWithFloat:M_PI * 2.0];
	animation.cumulative = YES;
	animation.duration = 60.0;
	animation.repeatCount = NSIntegerMax;
	[self.hihatContainer.layer addAnimation:animation forKey:kHihatLayerAnimationKey];
}

- (void)_playedSoundWithChannel:(NSInteger)channel step:(NSInteger)step
{
	NSInteger tag = ((channel * kPatternLength) + step) + 1;
	
	[self _moveButtonWithTag:tag];
}

- (void)_flashPulsebutton
{
	self.pulseButton.alpha = 0.5;
	
	[UIView animateWithDuration:0.5 delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
		self.pulseButton.alpha = 0;
	} completion:nil];
}

- (void)_kickEvent
{
	CGFloat angle = .125 - ((arc4random() % 1000) / 4000.0);
	self.buttonContainer.transform = CGAffineTransformRotate(CGAffineTransformIdentity, angle);
	
	[UIView animateWithDuration:0.1 delay:0 options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionCurveEaseOut animations:^{
		self.buttonContainer.transform = CGAffineTransformRotate(CGAffineTransformIdentity, 0);
	} completion:nil];
}

- (void)_hihatEvent:(NSInteger)step
{
	UIView *view = [self.hihatViews objectAtIndex:step];
	view.alpha = 0.15;
	[UIView animateWithDuration:1.0 delay:0 options:0 animations:^{
		view.alpha = 0;
	} completion:nil];
}

- (void)_clapEvent
{
	NSInteger direction = arc4random() % 4;
	CGRect originalRect = self.buttonContainer.frame;
	CGRect animationRect = originalRect;
	CGFloat offset = 5.0;
	
	switch (direction)
	{
		case 0:
			animationRect.origin.x -= offset;
			break;
		case 1:
			animationRect.origin.x += offset;
			break;
		case 2:
			animationRect.origin.y -= offset;
			break;
		case 3:
			animationRect.origin.y += offset;
			break;
		default:
			break;
	}
	
	[UIView animateWithDuration:0.05 delay:0 options:0 animations:^{
		self.buttonContainer.frame = animationRect;
	} completion:^(BOOL finished) {
		[UIView animateWithDuration:0.05 delay:0 options:0 animations:^{
			self.buttonContainer.frame = originalRect;
		} completion:nil];
	}];
}

- (void)_bipEvent:(NSInteger)step
{
	NSInteger offset = arc4random() % 2;
	UIButton *button = self.bipButtons[(step * 2) + offset];
	button.alpha = 0.5;
	[UIView animateWithDuration:0.2 animations:^{
		button.alpha = 0;
	}];
}

- (void)_boopEvent
{
	CGFloat inY = arc4random() % (NSInteger)self.view.bounds.size.height;
	CGFloat inHeight = arc4random() % (NSInteger)self.view.bounds.size.height;
	CGFloat outY = arc4random() % (NSInteger)self.view.bounds.size.height;
	CGFloat outHeight = arc4random() % (NSInteger)self.view.bounds.size.height;
	self.boopView.frame = CGRectMake(self.boopView.frame.origin.x, inY, self.boopView.frame.size.width, inHeight);
	self.boopView.alpha = 0.5;
	[UIView animateWithDuration:3 delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
		self.boopView.frame = CGRectMake(self.boopView.frame.origin.x, outY, self.boopView.frame.size.width, outHeight);
		self.boopView.alpha = 0;
	} completion:nil];
}

- (void)_appDidBecomeActive:(NSNotification *)notification
{
	if ([self.hihatContainer.layer animationForKey:kHihatLayerAnimationKey] == nil)
	{
		[self _addAnimationToHihatLayer];
	}
}

- (void)_showAudioAlert
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error initializing sound", nil) message:NSLocalizedString(@"There was a problem with starting the audio engine. Try restarting the app.", nil) delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Dismiss", nil];
	[alert show];
}

#pragma mark - UIViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_appDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
	
	self.view.backgroundColor = [UIColor whiteColor];	
	
	self.sequencer = [[ConformSequencer alloc] init];
	BOOL success = [self.sequencer configureWithMainCallback:^(NSInteger channel, NSInteger step) {
		[self _playedSoundWithChannel:channel step:step];
	} kickCallback:^(NSInteger channel, NSInteger step) {
		[self _kickEvent];
	} hihatCallback:^(NSInteger channel, NSInteger step) {
		[self _hihatEvent:step];
	} clapCallback:^(NSInteger channel, NSInteger step) {
		[self _clapEvent];
	} pulseCallback:^(NSInteger step, NSInteger note) {
		[self _flashPulsebutton];
	} bipCallback:^(NSInteger step, NSInteger note) {
		[self _bipEvent:step];
	} boopCallback:^(NSInteger step, NSInteger note) {
		[self _boopEvent];
	}];
	
	if ( ! success)
	{
		[self _showAudioAlert];
	}
	
	self.buttonContainer = [[UIView alloc] initWithFrame:self.view.bounds];
	self.buttonContainer.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	[self.view addSubview:self.buttonContainer];
	
	[self _layoutInterface];
	
	self.defaultImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default-Landscape"]];
	self.defaultImageView.frame = CGRectMake(0, 0, MAX(self.view.bounds.size.width, self.view.bounds.size.height), MIN(self.view.bounds.size.width, self.view.bounds.size.height));
	[self.view addSubview:self.defaultImageView];
}

- (void)viewWillAppear:(BOOL)animated
{
	[super viewWillAppear:animated];
	
	[self _addAnimationToHihatLayer];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	if ( ! [self.sequencer start])
	{
		[self _showAudioAlert];
	}
	
	[UIView animateWithDuration:3 delay:2 options:UIViewAnimationOptionCurveLinear animations:^{
		self.defaultImageView.alpha = 0;
	} completion:^(BOOL finished) {
		[self.defaultImageView removeFromSuperview];
		self.defaultImageView = nil;
	}];
}

@end
