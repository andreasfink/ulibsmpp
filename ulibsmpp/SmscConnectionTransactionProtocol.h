//
//  SmscConnectionTransactionProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//
#import <um/um.h>

#import <ulibsmpp/SmscConnectionMessageProtocol.h>

typedef enum SmscConnectionTransactionType
{
    TT_UNDEFINED        = 0,
    TT_SUBMIT_MESSAGE   = 1,
    TT_SUBMIT_REPORT    = 2,
    TT_DELIVER_MESSAGE  = 3,
    TT_DELIVER_REPORT   = 4,
} SmscConnectionTransactionType;

@protocol SmscConnectionTransactionProtocol<NSObject>

@property(readwrite,atomic,strong)  UMMessage       *message;
@property(readwrite,atomic,strong)  UMMessageReport *report;
@property(readwrite,atomic,strong)  NSString        *reference;
@property(readwrite,atomic,strong)  NSNumber        *error;
@property(readwrite,atomic,assign)  BOOL             incoming;
@property(readwrite,atomic,assign)  SmscConnectionTransactionType             type;

- (BOOL) isExpired;
- (void) setTimeout:(NSTimeInterval) seconds;

@end
