//
//  SmscConnectionTransaction.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 09.03.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#import "SmscConnectionMessageProtocol.h"
#import "SmscConnectionTransactionProtocol.h"
#import "SmscConnectionReportProtocol.h"

typedef enum SmscConnectionTransactionType
{
    TT_UNDEFINED        = 0,
    TT_SUBMIT_MESSAGE   = 1,
    TT_SUBMIT_REPORT    = 2,
    TT_DELIVER_MESSAGE  = 3,
    TT_DELIVER_REPORT   = 4,
} SmscConnectionTransactionType;

@interface SmscConnectionTransaction : UMObject
{
    NSString *sequenceNumber;
    id<SmscConnectionMessageProtocol>	_message;
    id<SmscConnectionReportProtocol>	report;
    id  upperObject;
    id  lowerObject;
    NSDate *created;
    NSTimeInterval timeout;

	SmscRouterError                     *status;
	BOOL								incoming;
	SmscConnectionTransactionType       type;
}

@property(readwrite,strong)			NSString *sequenceNumber;
@property(readwrite,strong)			id<SmscConnectionMessageProtocol>  _message;   //Transaction retains the message; it will released when no more needed
@property(readwrite,strong)			id<SmscConnectionReportProtocol> report;
@property(readwrite,strong)			id upperObject;
@property(readwrite,strong)			id lowerObject;
@property(readwrite,assign)			NSTimeInterval timeout;
@property(readwrite,strong)			SmscRouterError *status;
@property(readwrite,assign)			BOOL	incoming;
@property(readwrite,assign)			SmscConnectionTransactionType	type;


- (id) init;
- (BOOL) isExpired;
- (NSString *)description;
- (void) touch;

@end
