//
//  SmscConnectionTransactionProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulibsmpp/SmscConnectionMessageProtocol.h>
#import <ulibsmpp/SmscConnectionReportProtocol.h>
//#import "SmscConnectionErrorCode.h"

@protocol SmscConnectionTransactionProtocol<NSObject>

- (void)setMessage:(UMMessage *)msg;
- (UMMessage *)message;

- (void)setReport:(UMMessageReport *)report;
- (UMMessageReport *)report;

- (void) setReference:(NSString *)refe;
- (NSString *)reference;

- (void) setStatus:(SmscRouterError *)status;
- (SmscRouterError *)status;

- (void) setType:(int)type;
- (int)type;

- (void) setIncoming:(int)type;
- (int) incoming;

- (BOOL) isExpired;
- (void) setTimeout:(NSTimeInterval) seconds;

@end
