//
//  TestCounter.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 16.10.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "TestCounter.h"

@implementation TestCounter
@synthesize lock;

/* create a new counter object.*/
- (TestCounter *)init
{
    if((self=[super init]))
    {
        lock = [[NSLock alloc] init];
        n = 0;
    }
    return self;
}

/* return the current value of the counter and increase counter by one */
- (unsigned long)increase
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    ++n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and increase counter by value */
- (unsigned long)increaseWith:(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    n += value;
    [lock unlock];
    return ret;
}

/* return the current value of the counter */
-(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and decrease counter by one */
- (unsigned long)decrease
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    if (n > 0)
        --n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and set it to the supplied value */
- (unsigned long)setTo:(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    n = value;
    [lock unlock];
    return ret;
}


@end
