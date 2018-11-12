//
//  NSString+TestSPPAdditions.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 21.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "NSString+TestSMPPAdditions.h"

#include <stdlib.h>

@implementation NSString (TestSMPPAdditions)

- (int) checkRange:(NSRange)range withFunction:(range_func_t)filter
{
    long end = range.location + range.length;
    long pos;
    
    if (range.location >= [self length])
        return 1;
    if (end > [self length])
        end = [self length];
    
    pos = range.location;
    for ( ; pos < end; pos++)
    {
        if (!filter([self characterAtIndex:pos]))
            return 0;
    }
    
    return 1;
}

@end

