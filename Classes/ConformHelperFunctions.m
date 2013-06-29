//
//  ConformHelperFunctions.m
//  conform
//
//  Created by Johan Halin on 14.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import "ConformHelperFunctions.h"

float getTickLength(float bpm, float samplingRate)
{
	float tickLength = (samplingRate / 8.0) * (120.0 / bpm);
	
	return tickLength;
}

void clampChannel(float *channel, float max)
{
	if (*channel > max)
	{
		*channel = max;
	}
	else if (*channel < -max)
	{
		*channel = -max;
	}
}

void clampStereo(float *left, float *right, float max)
{
	if (max > 1.0)
	{
		max = 1.0;
	}
	else if (max < 0)
	{
		max = 0;
	}
	
	clampChannel(left, max);
	clampChannel(right, max);
}

@implementation ConformHelperFunctions

@end
