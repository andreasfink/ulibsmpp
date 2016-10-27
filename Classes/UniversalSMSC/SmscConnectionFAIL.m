//
//  SmscConnectionFAIL.m
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC which always return Failed

#import "SmscConnectionFAIL.h"
#import <ulib/ulib.h>
#include <sys/signal.h>
#include <unistd.h> /* for usleep */
#import "NSMutableString+UniversalSMPP.h"
#import "NSString+UniversalSMPP.h"
#import "SmppErrorCode.h"
#import "SmscRouterError.h"

@implementation SmscConnectionFAIL

@synthesize errorToReturn;


- (SmscConnectionFAIL *)init
{
    self=[super init];
    if(self)
    {
        [super setVersion: @"1.0"];
        [super setType: @"fail"];
        self.errorToReturn = NULL;
        self.lastActivity =[NSDate date];
    }
    return self;
}

- (NSString *)type
{
    return @"fail";
}

- (NSString *) getType
{
    return @"null";
}

- (BOOL) isConnected
{
    return YES;
}

- (BOOL) isAuthenticated
{
    return YES;
}

#pragma mark handling config

- (int) setConfig: (NSDictionary *) dict
{
    errorToReturn = [router createError];
    if(errorToReturn==NULL)
    {
        errorToReturn = [[SmscRouterError alloc]init];
    }

    
    if([dict[PREFS_CON_GSM_ERRCODE] isKindOfClass:[NSNumber class]])
    {
        
        NSNumber *v = dict[PREFS_CON_GSM_ERRCODE];
        [errorToReturn setGsmErrorCode:[v intValue]];
    }
    if([dict[PREFS_CON_SMPP_ERRCODE] isKindOfClass:[NSNumber class]])
    {
        
        NSNumber *v = dict[PREFS_CON_SMPP_ERRCODE];
        [errorToReturn setSmppErrorCode:[v intValue]];
    }
    if([dict[PREFS_CON_DLR_ERRCODE] isKindOfClass:[NSNumber class]])
    {
        
        NSNumber *v = dict[PREFS_CON_DLR_ERRCODE];
        [errorToReturn setDeliveryReportErrorCode:[v intValue]];
    }
    /*
    if([dict[PREFS_CON_SMSC_ERRCODE] isKindOfClass:[NSNumber class]])
    {
        
        NSNumber *v = dict[PREFS_CON_SMSC_ERRCODE];
        [errorToReturn setSmscConnectionErrorCode:[v intValue]];
    }
     */
    if([dict[PREFS_CON_INTERNAL_ERRCODE] isKindOfClass:[NSNumber class]])
    {
        
        NSNumber *v = dict[PREFS_CON_INTERNAL_ERRCODE];
        [errorToReturn setInternalErrorCode:[v intValue]];
    }
    if(errorToReturn.errorTypes == SmscRouterError_TypeNONE)
    {
        [errorToReturn setSmppErrorCode:ESME_RSYSERR];
    }
    return -1;
}

- (NSDictionary *) getConfig
{
    NSMutableDictionary *dict;
    
    dict = [NSMutableDictionary dictionaryWithDictionary: [super getConfig]];
    dict[PREFS_CON_PROTO] = @"fail";
    
    if(errorToReturn)
    {
        if(errorToReturn.errorTypes & SmscRouterError_TypeSMPP)
        {
            dict[PREFS_CON_SMPP_ERRCODE] = @(errorToReturn.smppError);
        }
        if(errorToReturn.errorTypes & SmscRouterError_TypeGSM)
        {
            dict[PREFS_CON_GSM_ERRCODE] = @(errorToReturn.gsmError);
        }
        if(errorToReturn.errorTypes & SmscRouterError_TypeDLR)
        {
            dict[PREFS_CON_DLR_ERRCODE] = @(errorToReturn.dlrError);
        }
        if(errorToReturn.errorTypes & SmscRouterError_TypeINTERNAL)
        {
            dict[PREFS_CON_INTERNAL_ERRCODE] = @(errorToReturn.internalError);
        }
    }
    return dict;
}



- (NSDictionary *) getClientConfig
{
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] init];
    dict[PREFS_CON_NAME] = @"fail";
    if(errorToReturn)
    {
        if(errorToReturn.errorTypes & SmscRouterError_TypeSMPP)
        {
            dict[PREFS_CON_SMPP_ERRCODE] = @(errorToReturn.smppError);
        }
        if(errorToReturn.errorTypes & SmscRouterError_TypeGSM)
        {
            dict[PREFS_CON_GSM_ERRCODE] = @(errorToReturn.gsmError);
        }
        if(errorToReturn.errorTypes & SmscRouterError_TypeDLR)
        {
            dict[PREFS_CON_DLR_ERRCODE] = @(errorToReturn.dlrError);
        }
        if(errorToReturn.errorTypes & SmscRouterError_TypeINTERNAL)
        {
            dict[PREFS_CON_INTERNAL_ERRCODE] = @(errorToReturn.internalError);
        }
    }
    return dict;
}

+ (NSDictionary *) getDefaultConnectionConfig
{
    NSDictionary *smppConnectionDict;
    
    smppConnectionDict = @{ PREFS_CON_NAME : @"fail",
                            PREFS_CON_SMPP_ERRCODE : @(ESME_RSYSERR)};
    return smppConnectionDict;
}

+ (NSDictionary *) getDefaultListenerConfig
{
    return @{ PREFS_CON_NAME : @"fail",
              PREFS_CON_SMPP_ERRCODE : @(ESME_RSYSERR)};
}

#pragma mark sendingPDUs

- (NSString *)connectedFrom
{
    return @"fail";
}

- (NSString *)connectedTo
{
    return @"fail";
}

- (void) outbound
{
    /* first, register self to sms router */
    @autoreleasepool
    {
        [self setIsInbound:NO];
        [router registerOutgoingSmscConnection:self];
    }
}

/* submit Message: router->outbound TX connection */
- (void) submitMessage:(id<SmscConnectionMessageProtocol>)msg
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
    char *this_msg_id = malloc(14);
    time_t this_msgid_time_t;
    struct tm *this_msgid_time_trec;
    
    time(&this_msgid_time_t);
    this_msgid_time_trec = gmtime(&this_msgid_time_t);
    this_msgid_time_trec->tm_mon++;
    sprintf((char *)this_msg_id,"%04d%02d%02d%02d%02d%02d%04d",
            this_msgid_time_trec->tm_year+1900,
            this_msgid_time_trec->tm_mon,
            this_msgid_time_trec->tm_mday,
            this_msgid_time_trec->tm_hour,
            this_msgid_time_trec->tm_min,
            this_msgid_time_trec->tm_sec,
            0);
    
    id<SmscConnectionReportProtocol> report = NULL;
    
    msg.providerReference = [NSString stringWithUTF8String:this_msg_id];
    [sendingObject submitMessageSent:msg
                           forObject:self
                         synchronous:NO];

    sleep(1); /* TODO: well NULL is only good for debugging anyway */
    report = [router createReport];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:UNDELVRD err:%03d text:no-route-to-destination",
                            msg.routerReference,
                            msg.submitDate ?    [formatter stringFromDate:msg.submitDate]:[formatter stringFromDate:[NSDate date]],
                            msg.attemptedDate ? [formatter stringFromDate:msg.attemptedDate]:[formatter stringFromDate:[NSDate date]],
                            errorToReturn.dlrError];
    report.reportType               = SMS_REPORT_UNDELIVERABLE;
    if(errorToReturn == NULL)
    {
        errorToReturn = [router createError];
        [errorToReturn setSmppErrorCode:ESME_RSYSERR];
    }
    report.error                    = errorToReturn;
    report.routerReference          = msg.routerReference;
    report.providerReference      = msg.providerReference;
    report.userReference            = msg.userReference;
    report.originalSendingObject    = msg.originalSendingObject;
    report.reportText               = reportText;
    report.source                   = msg.to;
    report.destination              = msg.from;
    
    [sendingObject deliverReport:report
                       forObject:self
                     synchronous:NO];
    free(this_msg_id);
}

- (void) submitReport:(id<SmscConnectionReportProtocol>)report
            forObject:(id)sendingObject
          synchronous:(BOOL)sync
{
    [sendingObject submitReportSent:report
                          forObject:self
                        synchronous:!sync];
}

- (void) submitReportSent:(id<SmscConnectionReportProtocol>)report
                forObject:(id)reportingObject
              synchronous:(BOOL)sync
{
}

- (void) submitReportFailed:(id<SmscConnectionReportProtocol>)report
                  withError:(SmscRouterError *)err
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync
{
    
}

/* deliverMessage: router->inbound RX connection . we just ack it.*/
- (void) deliverMessage:(id<SmscConnectionMessageProtocol>)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync
{
    id<SmscConnectionReportProtocol> report = NULL;
    
    [sendingObject deliverMessageSent:msg
                            forObject:self
                          synchronous:!sync];
    report = [router createReport];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:DELIVRD err:000",
                            msg.routerReference,
                            msg.submitDate ?    [formatter stringFromDate:msg.submitDate]:[formatter stringFromDate:[NSDate date]],
                            msg.attemptedDate ? [formatter stringFromDate:msg.attemptedDate]:[formatter stringFromDate:[NSDate date]]];
    report.reportType               = SMS_REPORT_DELIVERED;
    report.error                    = NULL;
    report.routerReference          = msg.routerReference;
    report.providerReference        = msg.providerReference;
    report.userReference            = msg.userReference;
    report.originalSendingObject    = msg.originalSendingObject;
    report.reportText               = reportText;
    report.source                   = msg.to;
    report.destination              = msg.from;
    [sendingObject submitReport:report
                      forObject:self
                    synchronous:NO];
}

- (void) deliverReport:(id<SmscConnectionReportProtocol>)report
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
    [sendingObject deliverReportSent:report
                           forObject:self
                         synchronous:!sync];
}

- (void) deliverReportSent:(id<SmscConnectionReportProtocol>)report
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync
{
}

- (void) deliverReportFailed:(id<SmscConnectionReportProtocol>)report
                   withError:(SmscRouterError *)err
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync
{
    
}

@end
