//
//  TestUtils.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 14.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "TestUtils.h"

@implementation TestUtils

+ (void) encodeToNetworkLong:(unsigned char *)data withValue:(unsigned long)value
{
    data[0] = (value >> 24) & 0xff;
    data[1] = (value >> 16) & 0xff;
    data[2] = (value >> 8) & 0xff;
    data[3] = value & 0xff;
}

+ (int) decodeNetworkLong:(unsigned char *)data
{
    return (data[0] << 24) | (data[1] << 16) | (data[2] << 8) | data[3];
}

@end
