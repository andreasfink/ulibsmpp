//
//  SmscConnectionFAIL.m
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC which always return Failed

#import <ulib/ulib.h>
#include <sys/signal.h>
#include <unistd.h> /* for usleep */
#import <ulibsmpp/SmscConnectionFAIL.h>
#import <ulibsmpp/NSMutableString+UniversalSMPP.h>
#import <ulibsmpp/NSString+UniversalSMPP.h>
#import <ulibsmpp/UMSmppError.h>

@implementation SmscConnectionFAIL

@synthesize errorToReturn;


- (SmscConnectionFAIL *)init
{
    self=[super init];
    if(self)
    {
        [super setVersion: @"1.0"];
        [super setType: @"fail"];
        self.errorToReturn = UM_ESME_RSYSERR;
        self.lastActivity =[NSDate new];
    }
    return self;
}

- (NSString *)_type
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
    errorToReturn = UM_ESME_RSYSERR;
    
    if([dict[PREFS_CON_ERRCODE] isKindOfClass:[NSNumber class]])
    {
        
        NSNumber *v = dict[PREFS_CON_ERRCODE];
        errorToReturn = [v intValue];
    }
    return 0;
}

- (NSDictionary *) getConfig
{
    NSMutableDictionary *dict;
    
    dict = [NSMutableDictionary dictionaryWithDictionary: [super getConfig]];
    dict[PREFS_CON_PROTO] = @"fail";
    dict[PREFS_CON_ERRCODE] = @(errorToReturn);
    return dict;
}



- (NSDictionary *) getClientConfig
{
    NSMutableDictionary *dict;
    
    dict = [[NSMutableDictionary alloc] init];
    dict[PREFS_CON_NAME] = @"fail";
    dict[PREFS_CON_ERRCODE] = @(errorToReturn);
    return dict;
}

+ (NSDictionary *) getDefaultConnectionConfig
{
    NSDictionary *smppConnectionDict;
    
    smppConnectionDict = @{ PREFS_CON_NAME : @"fail",
                            PREFS_CON_ERRCODE : @(UM_ESME_RSYSERR)};
    return smppConnectionDict;
}

+ (NSDictionary *) getDefaultListenerConfig
{
    return @{ PREFS_CON_NAME : @"fail",
              PREFS_CON_ERRCODE : @(UM_ESME_RSYSERR)};
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
        [_router registerOutgoingSmscConnection:self];
    }
}

/* submit Message: router->outbound TX connection */
- (void) submitMessage:(UMMessage *)msg
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
    
    UMMessageReport * report = NULL;
    
    msg.providerReference = UMDIRTY_STRING([NSString stringWithUTF8String:this_msg_id]);
    [sendingObject submitMessageSent:msg
                           forObject:self
                         synchronous:NO];

    sleep(1); /* TODO: well NULL is only good for debugging anyway */
    report = [_router createReport];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:UNDELVRD err:%03d text:no-route-to-destination",
                            msg.routerReference,
                            msg.submitTimestamp     ?    [formatter stringFromDate:msg.submitTimestamp.dateValue]
                                                         :[formatter stringFromDate:[NSDate date]],
                            msg.messageAttemptedTimestamp ? [formatter stringFromDate:msg.messageAttemptedTimestamp.dateValue]
                                                          :[formatter stringFromDate:[NSDate date]],
                            errorToReturn];
    report.reportType               = UMMESSAGE_STATE_UNDELIVERABLE;
    report.error                    = @(UM_ESME_RSUBMITFAIL);
    msg.submitErrorCode = [[UMDirtyInteger alloc]initWithInteger:UM_ESME_RSUBMITFAIL];
    report.routerReference          = msg.routerReference.stringValue;
    report.providerReference        = msg.providerReference.stringValue;
    report.userReference            = msg.userReference.stringValue;
    report.originalSendingObject    = msg.originalSendingObject;
    report.reportText               = reportText;
    report.fromNumber               = msg.toNumber.stringValue;
    report.toNumber                 = msg.fromNumber.stringValue;
    
    [sendingObject deliverReport:report
                       forObject:self
                     synchronous:NO];
    free(this_msg_id);
}

- (void) submitReport:(UMMessageReport *)report
            forObject:(id)sendingObject
          synchronous:(BOOL)sync
{
    [sendingObject submitReportSent:report
                          forObject:self
                        synchronous:!sync];
}

- (void) submitReportSent:(UMMessageReport *)report
                forObject:(id)reportingObject
              synchronous:(BOOL)sync
{
}

- (void) submitReportFailed:(UMMessageReport *)report
                      error:(NSNumber *)err
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync
{
    
}

/* deliverMessage: router->inbound RX connection . we just ack it.*/
- (void) deliverMessage:(UMMessage *)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync
{
    UMMessageReport * report = NULL;
    
    [sendingObject deliverMessageSent:msg
                            forObject:self
                          synchronous:!sync];
    report = [_router createReport];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmmss"];
    NSString *reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:DELIVRD err:000",
                            msg.routerReference,
                            msg.submitTimestamp  ?    [formatter stringFromDate:msg.submitTimestamp.dateValue]:[formatter stringFromDate:[NSDate date]],
                            msg.messageAttemptedTimestamp ? [formatter stringFromDate:msg.messageAttemptedTimestamp.dateValue]:[formatter stringFromDate:[NSDate date]]];
    report.reportType               = UMMESSAGE_STATE_DELIVERED;
    report.error                    = NULL;
    report.routerReference          = msg.routerReference.stringValue;
    report.providerReference        = msg.providerReference.stringValue;
    report.userReference            = msg.userReference.stringValue;
    report.originalSendingObject    = msg.originalSendingObject;
    report.reportText               = reportText;
    report.fromNumber               = msg.toNumber.stringValue;
    report.toNumber                 = msg.fromNumber.stringValue;
    [sendingObject submitReport:report
                      forObject:self
                    synchronous:NO];
}

- (void) deliverReport:(UMMessageReport *)report
             forObject:(id)sendingObject
           synchronous:(BOOL)sync
{
    [sendingObject deliverReportSent:report
                           forObject:self
                         synchronous:!sync];
}

- (void) deliverReportSent:(UMMessageReport *)report
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync
{
}

- (void) deliverReportFailed:(UMMessageReport *)report
                       error:(NSNumber *)error
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync
{
    
}

@end
