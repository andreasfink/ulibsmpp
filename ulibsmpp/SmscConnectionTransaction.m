//
//  SmscConnectionTransaction.m
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "SmscConnectionTransaction.h"
#import <ulibsmpp/UMSmppError.h>

@implementation SmscConnectionTransaction

- (NSString *)description
{
    NSMutableString *desc;
    @autoreleasepool
    {
        desc = [[NSMutableString alloc] initWithFormat:@"SmscConnectionTransaction %p\n", self];
        [desc appendFormat:@"---\n"];
        [desc appendFormat:@" sequenceNumber %@\n",                 _sequenceNumber];
        [desc appendFormat:@" message %@\n",                        _message];
        [desc appendFormat:@" transaction was created at %@\n",     _created];
        [desc appendFormat:@" timeout for transaction is %8.4fs\n", _timeout];
        [desc appendFormat:@" upperObject has name %@\n",           [_upperObject name]];
        [desc appendFormat:@" lowerObject has name %@\n",           [_lowerObject name]];
        if(_error)
        {
            [desc appendFormat:@" error %@ (%@)\n",             _error, UMSmppErrorAsString(_error.integerValue)];
        }
        [desc appendFormat:@"transaction was %@\n",                 _incoming ? @"incoming" : @"outgoing"];
        switch(_type)
        {
            case TT_SUBMIT_MESSAGE:
                [desc appendFormat:@"transaction type was TT_SUBMIT_MESSAGE\n"];
                break;
            case TT_SUBMIT_REPORT:
                [desc appendFormat:@"transaction type was TT_SUBMIT_REPORT\n"];
                break;
            case TT_DELIVER_MESSAGE:
                [desc appendFormat:@"transaction type was TT_DELIVER_MESSAGE\n"];
                break;
            case TT_DELIVER_REPORT:
                [desc appendFormat:@"transaction type was TT_DELIVER_REPORT\n"];
                break;
            default:
                [desc appendFormat:@"transaction type was TT_UNDEFINED\n"];
                break;
        }
        [desc appendString:@"Transaction dump ends"];
        [desc appendFormat:@"---\n"];
    }
    return desc;
}


- (id) init
{
    if((self = [super init]))
    {
        _created = [[NSDate alloc] init];
        _timeout = 30.0; /* defaults to 30 seconds */
    }
    return self;
}


- (BOOL) isExpired
{
    if ((-[_created timeIntervalSinceNow]) > _timeout)
    {
        return YES;
    }
    return NO;
}

- (void) touch
{
    _created = [[NSDate alloc] init];
}

@end
