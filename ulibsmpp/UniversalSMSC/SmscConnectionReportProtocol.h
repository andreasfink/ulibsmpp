//
//  SmscConnectionReportProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "UniversalSMSUtilities.h"
#import "SmscConnectionMessageProtocol.h"
#import "SmscRouterError.h"

typedef enum DeliveryReportType
{
    SMS_REPORT_UNSET            = -1,
	SMS_REPORT_SUBMITTED        = 0,
    SMS_REPORT_ENROUTE          = 1,
    SMS_REPORT_DELIVERED        = 2,
    SMS_REPORT_EXPIRED          = 3,
    SMS_REPORT_DELETED          = 4,
    SMS_REPORT_UNDELIVERABLE    = 5,
    SMS_REPORT_ACCEPTED         = 6,
    SMS_REPORT_UNKNOWN          = 7,
    SMS_REPORT_REJECTED         = 8,
} DeliveryReportType;

@protocol SmscConnectionReportProtocol<NSObject>
@property(readwrite,strong,atomic)  id      currentTransaction;
@property(readwrite,strong,atomic)  NSString *userReference;
@property(readwrite,strong,atomic)  NSString *routerReference;
@property(readwrite,strong,atomic)  NSString *providerReference;
@property(readwrite,strong,atomic)  UMSigAddr *destination;
@property(readwrite,strong,atomic)  UMSigAddr *source;
@property(readwrite,strong,atomic)  NSString *reportText;
@property(readwrite,assign,atomic)  DeliveryReportType reportType;
@property(readwrite,strong,atomic)  SmscRouterError *error;
@property(readwrite,assign,atomic)  int             priority;
@property(readwrite,strong,atomic)  id              originalSendingObject;
@property(readwrite,strong,atomic)  NSString        *imsi;
@property(readwrite,strong,atomic)  NSString        *msc;
@property(readwrite,strong,atomic)  NSString        *mcc;
@property(readwrite,strong,atomic)  NSString        *mnc;
@property(readwrite,assign,atomic)  int             responseCode;
@property(readwrite,strong,atomic)  id<SmscConnectionMessageProtocol>  reportToMsg;
@property(readwrite,strong,atomic)  NSString        *reportTypeAsString;

@optional

@property(readwrite,strong,atomic)  NSDictionary *tlvs;
@property(readwrite,strong,atomic)  NSString *hlrGt;
@property(readwrite,strong,atomic)  NSString *provider;

@end
