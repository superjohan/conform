//
//  ConformHelperFunctions.h
//  conform
//
//  Created by Johan Halin on 14.6.2013.
//  Copyright (c) 2013 Aero Deko. All rights reserved.
//

#import <Foundation/Foundation.h>

float getTickLength(float bpm, float samplingRate);
void clampStereo(float *left, float *right, float max); // if 'max' is higher than 1.0, it's set to 1.0

@interface ConformHelperFunctions : NSObject

@end
