//
//  SmscRouterError.h
//  ulibsmpp
//
//  Created by Andreas Fink on 06/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import "GSMErrorCode.h"
//#import "SmscConnectionErrorCode.h"
#import "SmppErrorCode.h"
#import "DeliveryReportErrorCode.h"


typedef int SmscRouterInternalError;

#define SMSError_none                                 0
#define SMSError_DeliveryFailure                      481
#define SMSError_AllOutgoingConnectionsUnavailable    482
#define SMSError_ConnectionOffline                    483
#define SMSError_Timeout                              484
#define SMSError_SubmissionFailure                    485

#define SmscRouterError_TypeSMPP     1
#define SmscRouterError_TypeGSM      2
#define SmscRouterError_TypeDLR      4
//#define SmscRouterError_TypeSMSC     8
#define SmscRouterError_TypeINTERNAL 16
#define SmscRouterError_TypeNONE     0


#define SmscRouterError_UNDEFINED   -99


#if __OBJC2__
__attribute__((__objc_exception__))
#endif

@interface SmscRouterError : UMObject
{
    int                     errorTypes; /*bitfield */
    
    DeliveryReportErrorCode dlrErr;
    SmppErrorCode           smppErr;
    GSMErrorCode            gsmErr;
//    SmscConnectionErrorCode smscErr;
    SmscRouterInternalError internalErr;
    
}

-(int) errorTypes;

- (SmscRouterError *)initWithGsmErrorCode:(GSMErrorCode)e;
- (SmscRouterError *)initWithGsmErrorCode:(GSMErrorCode)e usingOptions:(NSDictionary *)options;

- (SmscRouterError *)initWithDeliveryReportErrorCode:(DeliveryReportErrorCode)e;
- (SmscRouterError *)initWithDeliveryReportErrorCode:(DeliveryReportErrorCode)e usingOptions:(NSDictionary *)options;


- (SmscRouterError *)initWithSmppErrorCode:(SmppErrorCode)e;
- (SmscRouterError *)initWithSmppErrorCode:(SmppErrorCode)e usingOptions:(NSDictionary *)options;

//- (SmscRouterError *)initWithSmscConnectionErrorCode:(SmscConnectionErrorCode)e;
//- (SmscRouterError *)initWithSmscConnectionErrorCode:(SmscConnectionErrorCode)e usingOptions:(NSDictionary *)options;

- (SmscRouterError *)initWithInternalErrorCode:(SmscRouterInternalError)e;
- (SmscRouterError *)initWithInternalErrorCode:(SmscRouterInternalError)e usingOptions:(NSDictionary *)options;


- (void)setGsmErrorCode:(GSMErrorCode)e;
- (void)setGsmErrorCode:(GSMErrorCode)e usingOptions:(NSDictionary *)options;
- (void)setDeliveryReportErrorCode:(DeliveryReportErrorCode)e;
- (void)setDeliveryReportErrorCode:(DeliveryReportErrorCode)e usingOptions:(NSDictionary *)options;
- (void)setSmppErrorCode:(SmppErrorCode)e;
- (void)setSmppErrorCode:(SmppErrorCode)e usingOptions:(NSDictionary *)options;
//- (void)setSmscConnectionErrorCode:(SmscConnectionErrorCode)e;
//- (void)setSmscConnectionErrorCode:(SmscConnectionErrorCode)e usingOptions:(NSDictionary *)options;
- (void)setInternalErrorCode:(SmscRouterInternalError)e;
- (void)setInternalErrorCode:(SmscRouterInternalError)e usingOptions:(NSDictionary *)options;

- (GSMErrorCode)gsmErrorUsingOptions:(NSDictionary *)options;
- (SmppErrorCode)smppErrorUsingOptions:(NSDictionary *)options;
//- (SmscConnectionErrorCode)smscErrorUsingOptions:(NSDictionary *)options;
- (SmscRouterInternalError)internalErrorUsingOptions:(NSDictionary *)options;

- (GSMErrorCode)gsmError;
- (DeliveryReportErrorCode)dlrError;
- (SmppErrorCode)smppError;
//- (SmscConnectionErrorCode)smscError;
- (SmscRouterInternalError)internalError;

- (NSString *)description;
- (NSString *)descriptionSmppError;
- (NSString *)descriptionGsmError;
- (NSString *)descriptionInternalError;


-(void)convertGsmToInternal:(NSDictionary *)options;
-(void)convertDlrToInternal:(NSDictionary *)options;
-(void)convertSmppToInternal:(NSDictionary *)options;

-(void)convertInternalToGsm:(NSDictionary *)options;
-(void)convertInternalToDlr:(NSDictionary *)options;
-(void)convertInternalToSmpp:(NSDictionary *)options;
- (BOOL)allowsRerouting;
- (BOOL)allowUpdatingStats;


@end
