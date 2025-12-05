//
//  SmscRouterError.h
//  ulibsmpp
//
//  Created by Andreas Fink on 06/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import <ulib/ulib.h>
#import <ulibasn1/ulibasn1.h>
#import <ulibsmpp/GSMErrorCode.h>
#import <ulibsmpp/UMSmppError.h>
#import <ulibsmpp/UMDeliveryReportErrorCode.h>
typedef enum UMSmscRouterErrorTag
{
    UMSmscRouterErrorTag_dlrError   = 1,
    UMSmscRouterErrorTag_smppError  = 2,
    UMSmscRouterErrorTag_gsmError   = 3,
    UMSmscRouterErrorTag_internalError = 4,
} UMSmscRouterErrorTag;

typedef int SmscRouterInternalError;

#define SMSError_none                                 0
#define SMSError_DeliveryFailure                      481
#define SMSError_AllOutgoingConnectionsUnavailable    482
#define SMSError_ConnectionOffline                    483
#define SMSError_Timeout                              484
#define SMSError_SubmissionFailure                    485
#define SMSError_UserNotFound                         486
#define SMSError_PasswordMismatch                     487
#define SMSError_GroupNotFound                        488
#define SMSError_ExceptionEncountered                 489
#define SMSError_NotImplemented                       490
#define SMSError_OperationFailed                      491


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
@interface SmscRouterError : UMASN1Sequence
{
    int                         _errorTypes; /*bitfield */
    UMDeliveryReportErrorCode   _dlrErr;
    UMSmppError                 _smppErr;
    GSMErrorCode                _gsmErr;
    SmscRouterInternalError     _internalErr;
    NSString                    *_humanReadable;
}
@property(readwrite,strong)     NSString *humanReadable;

-(int) errorTypes;

- (SmscRouterError *)initWithGsmErrorCode:(GSMErrorCode)e;
- (SmscRouterError *)initWithGsmErrorCode:(GSMErrorCode)e usingOptions:(NSDictionary *)options;

- (SmscRouterError *)initWithDeliveryReportErrorCode:(UMDeliveryReportErrorCode)e;
- (SmscRouterError *)initWithDeliveryReportErrorCode:(UMDeliveryReportErrorCode)e usingOptions:(NSDictionary *)options;


- (SmscRouterError *)initWithSmppErrorCode:(UMSmppError)e;
- (SmscRouterError *)initWithSmppErrorCode:(UMSmppError)e usingOptions:(NSDictionary *)options;

//- (SmscRouterError *)initWithSmscConnectionErrorCode:(SmscConnectionErrorCode)e;
//- (SmscRouterError *)initWithSmscConnectionErrorCode:(SmscConnectionErrorCode)e usingOptions:(NSDictionary *)options;

- (SmscRouterError *)initWithInternalErrorCode:(SmscRouterInternalError)e;
- (SmscRouterError *)initWithInternalErrorCode:(SmscRouterInternalError)e usingOptions:(NSDictionary *)options;


- (void)setGsmErrorCode:(GSMErrorCode)e;
- (void)setGsmErrorCode:(GSMErrorCode)e usingOptions:(NSDictionary *)options;
- (void)setDeliveryReportErrorCode:(UMDeliveryReportErrorCode)e;
- (void)setDeliveryReportErrorCode:(UMDeliveryReportErrorCode)e usingOptions:(NSDictionary *)options;
- (void)setSmppErrorCode:(UMSmppError)e;
- (void)setSmppErrorCode:(UMSmppError)e usingOptions:(NSDictionary *)options;
//- (void)setSmscConnectionErrorCode:(SmscConnectionErrorCode)e;
//- (void)setSmscConnectionErrorCode:(SmscConnectionErrorCode)e usingOptions:(NSDictionary *)options;
- (void)setInternalErrorCode:(SmscRouterInternalError)e;
- (void)setInternalErrorCode:(SmscRouterInternalError)e usingOptions:(NSDictionary *)options;

- (GSMErrorCode)gsmErrorUsingOptions:(NSDictionary *)options;
- (UMSmppError)smppErrorUsingOptions:(NSDictionary *)options;
//- (SmscConnectionErrorCode)smscErrorUsingOptions:(NSDictionary *)options;
- (SmscRouterInternalError)internalErrorUsingOptions:(NSDictionary *)options;

- (GSMErrorCode)gsmError;
- (UMDeliveryReportErrorCode)dlrError;
- (UMSmppError)smppError;
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
