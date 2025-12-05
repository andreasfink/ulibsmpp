//
//  SmscConnectionTransaction.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ummessage/ummessage.h>

#import <ulibsmpp/SmscConnectionMessageProtocol.h>
#import <ulibsmpp/SmscConnectionTransactionProtocol.h>


@interface SmscConnectionTransaction : UMObject<SmscConnectionTransactionProtocol>
{
    NSString                            *_sequenceNumber;
    UMMessageObject                           *_message;
    UMMessageReport                     *_report;
    id                                  _upperObject;
    id                                  _lowerObject;
    NSDate                              *_created;
    NSTimeInterval                      _timeout;
    NSNumber                            *_error; /* UMSmppError value */
	BOOL   			    			    _incoming;
    SmscConnectionTransactionType       _type;
}

@property(readwrite,atomic,strong)			NSString *sequenceNumber;

@property(readwrite,atomic,strong)  UMMessageObject                       *message;   //Transaction retains the message; it will released when no more needed
@property(readwrite,atomic,strong)  UMMessageReport                 *report;
@property(readwrite,atomic,strong)  NSNumber                        *error;
@property(readwrite,atomic,strong)  NSString                        *reference;
@property(readwrite,atomic,assign)  BOOL                            incoming;
@property(readwrite,atomic,assign)  SmscConnectionTransactionType   type;
@property(readwrite,strong)            id              upperObject;
@property(readwrite,strong)            id              lowerObject;
@property(readwrite,assign)            NSTimeInterval  timeout;


- (id) init;
- (BOOL) isExpired;
- (NSString *)description;
- (void) touch;

@end
