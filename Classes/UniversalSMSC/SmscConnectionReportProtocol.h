//
//  SmscConnectionReportProtocol.h
//  UniversalSMSCConnection
//
//  Created by Andreas Fink on 01.03.09.
//  Copyright 2008-2014 Andreas Fink, Röschenzerstr. 27, 4058 Basel, Switzerland
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
- (id)currentTransaction;
- (void)setCurrentTransaction:(id)t;

- (NSString *)userReference;
- (void) setUserReference:(NSString *)i;

- (NSString *)routerReference;
- (void) setRouterReference:(NSString *)i;

- (NSString *)providerReference;
- (void) setProviderReference:(NSString *)i;

- (UMSigAddr *)destination;
- (void) setDestination:(UMSigAddr *)s;
- (UMSigAddr *)source;
- (void) setSource:(UMSigAddr *)s;
- (NSString *)reportText;
- (void) setReportText:(NSString *)s;
- (DeliveryReportType)reportType;
- (void) setReportType:(DeliveryReportType)i;
- (SmscRouterError *)error;
- (void) setError:(SmscRouterError *)err;
- (int) priority;
- (void) setPriority:(int)prio;
- (id) originalSendingObject;
- (void) setOriginalSendingObject:(id)o;
- (NSString *)imsi;
- (void) setImsi:(NSString *)imsi;
- (NSString *)msc;
- (void) setMsc:(NSString *)msc;
- (NSString *)mcc;
- (void) setMcc:(NSString *)mcc;
- (NSString *)mnc;
- (void) setMnc:(NSString *)mnc;
- (int) responseCode;
- (void) setResponseCode:(int)code;
- (NSString *)responseCodeToString;

- (id<SmscConnectionMessageProtocol>)reportToMsg;
- (NSString *)reportTypeAsString;


@optional
- (NSDictionary *)tlvs;
- (void)setTlvs:(NSDictionary *)tlvs;

- (NSString *)hlrGt;
- (void) setHlrGt:(NSString *)hlrGt;

- (NSString *)provider;
- (void) setProvider:(NSString *)provider;

@end
