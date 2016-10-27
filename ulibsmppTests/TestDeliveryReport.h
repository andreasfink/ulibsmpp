//
//  TestDeliveryReport.h
//  smsrouter
//
//  Created by Aarno Syvänen on 01.02.13.
//  Copyright (c) 2013 Andreas Fink. All rights reserved.
//

#import "ulib/ulib.h"
#import "SmscConnectionReportProtocol.h"
#import "smpptest.h"

@class SmscConnectionSMPP, SmscConnection;

@interface TestDeliveryReport : UMObject
{
    NSString *userReference;
    NSString *routerReference;
    NSString *connectionReference;
    
    id originalSendingObject;
    
    UMSigAddr *destination;
    UMSigAddr *source;
    NSString *reportText;
    DeliveryReportType reportType;
    SmscConnectionErrorCode errorCode;
    int priority;
    NSString *hlrReport;
    
    NSString *provider;
    HLRResponseCode responseCode;
    NSString *imsi;
    NSString *msc;
    NSString *hlrGt;
    NSString *mcc;
    NSString *mnc;
    NSDictionary *tlvs;
    
    SmscConnection *connection;
    int reportState;
    NSString *usedAt;                        // for debugging
    UMHistoryLog    *reportHistory;
    long long startTime;
    
    DeliverReportState deliverReportState;
    BOOL deliveryAcked;
    SmscConnectionSMPP *deliverer;
    NSString *pduContent;
}

@property (readwrite,assign)    ReportFormat reportFormat;
@property (readwrite,strong)    NSString *userReference;
@property (readwrite,strong)    NSString *routerReference;
@property (readwrite,strong)    NSString *connectionReference;
@property (readwrite,strong)    id originalSendingObject;
@property (readwrite,strong)    UMSigAddr *destination;
@property (readwrite,strong)    UMSigAddr *source;
@property (readwrite,strong)    NSString *reportText;
@property (readwrite,assign)    DeliveryReportType reportType;
@property (readwrite,assign)    SmscConnectionErrorCode errorCode;
@property (readwrite,assign)    int priority;
@property (readwrite,strong)    NSString *hlrReport;
@property (readwrite,strong)    SmscConnection *connection;
@property (readwrite,strong)    NSString *provider;
@property (readwrite,strong)    NSString *imsi;
@property (readwrite,strong)    NSString *msc;
@property (readwrite,strong)    NSString *hlrGt;
@property (readwrite,assign)    HLRResponseCode responseCode;
@property (readwrite,strong)    NSString *mcc;
@property (readwrite,strong)    NSString *mnc;
@property (readwrite,assign)    int reportState;
@property (readwrite,strong)    NSDictionary *tlvs;
@property (readwrite,strong)    NSString *usedAt;


@property (readwrite,assign) DeliverReportState deliverReportState;
@property (readwrite,assign) BOOL deliveryAcked;
@property (readwrite,strong) SmscConnectionSMPP *deliverer;
@property (readwrite,strong) NSString *pduContent;


- (TestDeliveryReport *)initWithReport:(id <SmscConnectionReportProtocol>)report;
- (BOOL)equals:(TestDeliveryReport*)msg;
- (NSString *)description;
- (NSString *)deliverReportStateToString;
- (NSString *)reportStateToString;


@end
