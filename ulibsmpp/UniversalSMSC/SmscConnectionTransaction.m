//
//  SmscConnectionTransaction.m
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "SmscConnectionTransaction.h"

@implementation SmscConnectionTransaction

@synthesize type;
@synthesize incoming;
@synthesize status;
@synthesize	sequenceNumber;
@synthesize	_message;
@synthesize	report;
@synthesize upperObject;
@synthesize lowerObject;
@synthesize timeout;


- (NSString *)description
{
    NSMutableString *desc;
    @autoreleasepool
    {
        desc = [[NSMutableString alloc] initWithFormat:@"SmscConnectionTransaction %p\n", self];
        [desc appendFormat:@"---\n"];
        [desc appendFormat:@" sequenceNumber %@\n", sequenceNumber];
        [desc appendFormat:@" message %@\n", _message];
        [desc appendFormat:@" transaction was created at %@\n", created];
        [desc appendFormat:@" timeout for transaction is %8.4fs\n", timeout];
        [desc appendFormat:@" upperObject has name %@\n", [upperObject name]];
        [desc appendFormat:@" lowerObject has name %@\n", [lowerObject name]];
        [desc appendFormat:@"we have status %ld\n", (long)status];
        [desc appendFormat:@"transaction was %@\n", incoming ? @"incoming" : @"outgoing"];
        [desc appendFormat:@"transaction type was %d\n", type];
        [desc appendString:@"Transaction dump ends"];
        [desc appendFormat:@"---\n"];
    }
    return desc;
}


- (id) init
{
    if((self = [super init]))
    {
        created = [[NSDate alloc] init];
        timeout = 30.0; /* defaults to 30 seconds */
    }
    return self;
}


- (BOOL) isExpired
{
    if ((-[created timeIntervalSinceNow]) > timeout)
    {
        return YES;
    }
    return NO;
}

- (void) touch
{
    created = [[NSDate alloc] init];
}

@end
