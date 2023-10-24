//
//  UniversalSMSCConnection.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/ulib.h>
#import <ulibsmpp/UniversalSMSUtilities.h>

@protocol SmscConnectionMessageProtocol;
@protocol SmscConnectionReportProtocol;
@protocol SmscConnectionUserProtocol;
@protocol SmscConnectionRouterProtocol;
@protocol SmscConnectionTransactionProtocol;
@protocol SmscConnectionProtocol;

#import <ulibsmpp/SmscConnectionTransactionProtocol.h>
#import <ulibsmpp/SmscConnectionMessageProtocol.h>
#import <ulibsmpp/SmscConnectionReportProtocol.h>
#import <ulibsmpp/SmscConnectionUserProtocol.h>
#import <ulibsmpp/SmscConnectionRouterProtocol.h>
#import <ulibsmpp/SmscConnectionProtocol.h>
#import <ulibsmpp/SmscConnectionTransaction.h>
#import <ulibsmpp/SmscConnection.h>
#import <ulibsmpp/SmscStandardReport.h>
#import <ulibsmpp/SmscConnectionNULL.h>
#import <ulibsmpp/SmscConnectionFAIL.h>
#import <ulibsmpp/SmscConnectionNACK.h>
#import <ulibsmpp/DeliveryReportErrorCode.h>
#import <ulibsmpp/GSMErrorCode.h>
#import <ulibsmpp/SmscRouterError.h>
#import <ulibsmpp/SmscConnectionReadyProtocol.h>
