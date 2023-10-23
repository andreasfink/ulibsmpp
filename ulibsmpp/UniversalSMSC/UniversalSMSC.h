//
//  UniversalSMSCConnection.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <ulib/ulib.h>
#import <ulibsmpp/UniversalSMSUtilities/UniversalSMSUtilities.h>

@protocol SmscConnectionMessageProtocol;
@protocol SmscConnectionReportProtocol;
@protocol SmscConnectionUserProtocol;
@protocol SmscConnectionRouterProtocol;
@protocol SmscConnectionTransactionProtocol;
@protocol SmscConnectionProtocol;

#import <ulibsmpp/UniversalSMSC/SmscConnectionTransactionProtocol.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionMessageProtocol.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionReportProtocol.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionUserProtocol.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionRouterProtocol.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionProtocol.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionTransaction.h>
#import <ulibsmpp/UniversalSMSC/SmscConnection.h>
#import <ulibsmpp/UniversalSMSC/SmscStandardReport.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionNULL.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionFAIL.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionNACK.h>
#import <ulibsmpp/UniversalSMSC/DeliveryReportErrorCode.h>
#import <ulibsmpp/UniversalSMSC/GSMErrorCode.h>
#import <ulibsmpp/UniversalSMSC/SmscRouterError.h>
#import <ulibsmpp/UniversalSMSC/SmscConnectionReadyProtocol.h>
