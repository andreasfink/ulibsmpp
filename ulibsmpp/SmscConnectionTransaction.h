//
//  SmscConnectionTransaction.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <um/um.h>

#import <ulibsmpp/SmscConnectionMessageProtocol.h>
#import <ulibsmpp/SmscConnectionTransactionProtocol.h>


@interface SmscConnectionTransaction : UMObject<SmscConnectionTransactionProtocol>
{
    NSString                            *_sequenceNumber;
    UMMessage                           *_message;
    UMMessageReport                     *_report;
    id                                  _upperObject;
    id                                  _lowerObject;
    NSDate                              *_created;
    NSTimeInterval                      _timeout;
    NSNumber                            *_error; /* UMSmppError value */
	BOOL   			    			    _incoming;
    SmscConnectionTransactionType       _type;
}

@property(readwrite,strong)			NSString *sequenceNumber;
@property(readwrite,strong)			UMMessage       *message;   //Transaction retains the message; it will released when no more needed
@property(readwrite,strong)			UMMessageReport *report;
@property(readwrite,strong)			id              upperObject;
@property(readwrite,strong)			id              lowerObject;
@property(readwrite,assign)			NSTimeInterval  timeout;
@property(readwrite,strong)         NSNumber        *error;
@property(readwrite,assign)			BOOL            incoming;
@property(readwrite,assign)			SmscConnectionTransactionType type; /* SmscConnectionTransactionType */


- (id) init;
- (BOOL) isExpired;
- (NSString *)description;
- (void) touch;

@end
