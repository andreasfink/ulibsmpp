//
//  UniversalSMSCConnection.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#import "UniversalSMSUtilities.h"

@protocol SmscConnectionMessageProtocol;
@protocol SmscConnectionReportProtocol;
@protocol SmscConnectionUserProtocol;
@protocol SmscConnectionRouterProtocol;
@protocol SmscConnectionTransactionProtocol;
@protocol SmscConnectionProtocol;

#import "SmscConnectionTransactionProtocol.h"
#import "SmscConnectionMessageProtocol.h"
#import "SmscConnectionReportProtocol.h"
#import "SmscConnectionUserProtocol.h"
#import "SmscConnectionRouterProtocol.h"
#import "SmscConnectionProtocol.h"
#import "SmscConnectionTransaction.h"
#import "SmscConnection.h"
#import "SmscStandardReport.h"
#import "SmscConnectionNULL.h"
#import "SmscConnectionFAIL.h"
#import "SmscConnectionNACK.h"
#import "DeliveryReportErrorCode.h"
#import "GSMErrorCode.h"
#import "SmscRouterError.h"