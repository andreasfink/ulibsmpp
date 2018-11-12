
//
//  smpptest.m
//  smpptest
//
//  Created by Aarno Syvänen on 25.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "smpptest.h"

#import "UniversalSMPP.h"
#import "ulib/UMLogHandler.h"
#import "ulib/UMLogFeed.h"
#import "ulib/UMConfig.h"
//#import "TestRouter.h"
#import "ulib/UMHost.h"
#import "TestMessage.h"
#import "TestLogFile.h"
//#import "TestDeliveryReport.h"
#import "NSString+TestSMPPAdditions.h"
//#import "TestDelegate.h"

static void setup_signal_handlers(void)
{
    struct sigaction act;
    
    act.sa_handler = SIG_IGN;
    sigemptyset(&act.sa_mask);
    act.sa_flags = 0;
    sigaction(SIGINT, &act, NULL);
    sigaction(SIGQUIT, &act, NULL);
    sigaction(SIGHUP, &act, NULL);
    sigaction(SIGPIPE, &act, NULL);
}

@implementation smpptest

- (void)setUp
{
    [super setUp];
    
    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

+ (void)configSubmitTest:(TestMessage **)t
{
    NSString *type;
    NSString *fromString;
    NSString *toString;
    NSInteger pid;
    int priority;
    NSString *deferredString;
    NSDate *deferred;
    NSString *validityString;
    NSDate *validity;
    NSInteger reportMask;
    BOOL replaceIfPresent;
    NSInteger dcs;
    NSString *payloadString;
    NSData *payload;
    UMStringWithHistory *dbType, *dbFrom, *dbTo;
    UMIntegerWithHistory *dbPduPid, *dbPriority, *dbReportMask, *dbReplaceIfPresentFlag, *dbPduDcs;
    UMDateWithHistory *dbDeferred, *dbValidity;
    UMDataWithHistory *dbPduContent;
    
    UMConfig *cfg = [[UMConfig alloc] initWithFileName:@"/etc/submit-test.conf"];
    [cfg allowSingleGroup:@"submit"];
    [cfg read];
    
    NSDictionary *grp = [cfg getSingleGroup:@"submit"];
    if (!grp)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group submit" userInfo:nil];
    
    *t = [[TestMessage alloc] init];
    type = [grp objectForKey:@"service-type"];
    dbType = [*t dbType];
    [dbType setString:type];
    fromString = [grp objectForKey:@"from"];
    dbFrom = [*t dbFrom];
    [dbFrom setString:fromString];
    toString = [grp objectForKey:@"to"];
    dbTo = [*t dbTo];
    [dbTo setString:toString];
    pid = [[grp objectForKey:@"pid"] integerValue];
    dbPduPid = [*t dbPduPid];
    [dbPduPid setInteger:pid];
    priority = (int)[[grp objectForKey:@"priority"] integerValue];
    dbPriority = [*t dbPriority];
    [dbPriority setInteger:priority];
    deferredString = [grp objectForKey:@"deferred"];
    deferred = [NSDate dateWithString:deferredString];
    dbDeferred = [*t dbDeferred];
    [dbDeferred setDate:deferred];
    validityString = [grp objectForKey:@"validity"];
    validity = [NSDate dateWithString:validityString];
    dbValidity = [*t dbValidity];
    [dbValidity setDate:validity];
    reportMask = (ReportMaskValue)[[grp objectForKey:@"report-mask"] integerValue];
    dbReportMask = [*t dbReportMask];
    [dbReportMask setInteger:reportMask];
    replaceIfPresent = [[grp objectForKey:@"replace-if-present"] boolValue];
    dbReplaceIfPresentFlag = [*t dbReplaceIfPresentFlag];
    [dbReplaceIfPresentFlag setInteger:replaceIfPresent];
    dcs = [[grp objectForKey:@"dcs"] integerValue];
    dbPduDcs = [*t dbPduDcs];
    [dbPduDcs setInteger:dcs];
    payloadString = [grp objectForKey:@"payload"];
    payload = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
    dbPduContent = [*t dbPduContent];
    [dbPduContent setData:payload];
}

+ (void)configDeliverTest:(TestMessage **)t
{
    NSString *type;
    NSString *fromString;
    NSString *toString;
    NSInteger pid;
    int priority;
    NSString *deferredString;
    NSDate *deferred;
    NSString *validityString;
    NSDate *validity;
    NSInteger reportMask;
    BOOL replaceIfPresent;
    NSInteger dcs;
    NSString *payloadString;
    NSData *payload;
    UMStringWithHistory *dbType, *dbFrom, *dbTo;
    UMIntegerWithHistory *dbPduPid, *dbPriority, *dbReportMask, *dbReplaceIfPresentFlag, *dbPduDcs;
    UMDateWithHistory *dbDeferred, *dbValidity;
    UMDataWithHistory *dbPduContent;
    
    UMConfig *cfg = [[UMConfig alloc] initWithFileName:@"/etc/deliver-test.conf"];
    [cfg allowSingleGroup:@"deliver"];
    [cfg read];
    
    NSDictionary *grp = [cfg getSingleGroup:@"deliver"];
    if (!grp)
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"configuration file must have group deliver" userInfo:nil];
    
    *t = [[TestMessage alloc] init];
    type = [grp objectForKey:@"service-type"];
    dbType = [*t dbType];
    [dbType setString:type];
    fromString = [grp objectForKey:@"from"];
    dbFrom = [*t dbFrom];
    [dbFrom setString:fromString];
    toString = [grp objectForKey:@"to"];
    dbTo = [*t dbTo];
    [dbTo setString:toString];
    pid = [[grp objectForKey:@"pid"] integerValue];
    dbPduPid = [*t dbPduPid];
    [dbPduPid setInteger:pid];
    priority = (int)[[grp objectForKey:@"priority"] integerValue];
    dbPriority = [*t dbPriority];
    [dbPriority setInteger:priority];
    deferredString = [grp objectForKey:@"deferred"];
    deferred = [NSDate dateWithString:deferredString];
    dbDeferred = [*t dbDeferred];
    [dbDeferred setDate:deferred];
    validityString = [grp objectForKey:@"validity"];
    validity = [NSDate dateWithString:validityString];
    dbValidity = [*t dbValidity];
    [dbValidity setDate:validity];
    reportMask = (ReportMaskValue)[[grp objectForKey:@"report-mask"] integerValue];
    dbReportMask = [*t dbReportMask];
    [dbReportMask setInteger:reportMask];
    replaceIfPresent = [[grp objectForKey:@"replace-if-present"] boolValue];
    dbReplaceIfPresentFlag = [*t dbReplaceIfPresentFlag];
    [dbReplaceIfPresentFlag setInteger:replaceIfPresent];
    dcs = [[grp objectForKey:@"dcs"] integerValue];
    dbPduDcs = [*t dbPduDcs];
    [dbPduDcs setInteger:dcs];
    payloadString = [grp objectForKey:@"payload"];
    payload = [payloadString dataUsingEncoding:NSUTF8StringEncoding];
    dbPduContent = [*t dbPduContent];
    [dbPduContent setData:payload];
}

+ (BOOL)outconnectionClosed
{
    SmscConnectionSMPP *smppHlrConnection = [global_appDelegate smppHlrConnection];
    SmscConnectionSMPP *smppForwardConnection = [global_appDelegate smppForwardConnection];
    SmscConnectionSMPP *smppProxyConnection = [global_appDelegate smppProxyConnection];
    
    if ([smppHlrConnection outboundState] == SMPP_STATE_CLOSED)
        return YES;
    
    if ([smppForwardConnection outboundState] == SMPP_STATE_CLOSED)
        return YES;
    
    if ([smppProxyConnection outboundState] == SMPP_STATE_CLOSED)
        return YES;
    
    return NO;
}

+ (BOOL)inconnectionClosed
{
    SmscConnectionSMPP *smppIncomingConnection = [global_appDelegate smppIncomingConnection];
    
    if ([smppIncomingConnection inboundState] == SMPP_STATE_CLOSED)
        return YES;
    
    return NO;
}


- (void)testSMPP
{
    TestMessage *msg, *msg2;
    NSDictionary *inMessages, *outMessages, *outReports;
    NSArray *outKeys, *inKeys, *outValues, *inValues, *reportKeys, *reportValues;
    TestMessage *inMessage, *outMessage;
    TestDeliveryReport *outReport, *inReport;
    int networkErrorCode;
    TestRouter *router;
    int ret;
    
    setup_signal_handlers();

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [[TestDelegate alloc]init];
    [global_appDelegate  applicationDidFinishLaunching:NULL];
    
    [smpptest configSubmitTest:&msg];
    router = [global_appDelegate messageRouter];
    [router submitMessage:msg forObject:[global_appDelegate smppHlrConnection]];
    
    ret = usleep(600000);
    if (ret == -1)
    {
        NSLog(@"sleep with err %d (cannot connect to HLR)", errno);
        goto noSubmitTest;
    }
    
    outMessages = [router outMessages];
    STAssertNotNil(outMessages, @"outMessages directory should exist after sending a message from client to server");
    STAssertTrue([outMessages count] == 1, @"we should have zero messages in outMessages directory");
    outKeys = [outMessages allKeys];
    outValues = [outMessages allValues];
    
    inMessages = [router inMessages];
    STAssertNotNil(inMessages, @"inMessages directory should exist after sending a message from client to server");
    STAssertTrue([inMessages count] == 0, @"we should have zero messages in inMessages directory");
    inKeys = [inMessages allKeys];
    inValues = [inMessages allValues];
    
    outReports = [router outReports];
    STAssertNotNil(outReports, @"outReports directory should exist after sending a message from client to server");
    STAssertTrue([outReports count] == 0, @"we should have zero reports in outReports directory");
    reportKeys = [outReports allKeys];
    reportValues = [outReports allValues];
    
    BOOL closed = YES;
    ret = 0;
    while ((closed = [smpptest outconnectionClosed]) && ret == 0)
        ret = usleep(10000);
    if (ret == -1)
    {
        NSLog(@"sleep with err %d (connection to HLR closed)", errno);
        goto noSubmitTest;
    }
    
    MessageState messageState = notKnown;
    outMessage = nil;
    while (messageState < hlrResponse && !(closed = [smpptest outconnectionClosed]) && ret == 0) /* HLR response to submit, i.e, a route query*/
    {
        outMessages = [router outMessages];
        outKeys = [outMessages allKeys];
        if ([outKeys count] > 0)
            outMessage = [outMessages objectForKey:[outKeys objectAtIndex:0]];
        if (outMessage)
            messageState = [outMessage state];
        ret = usleep(10000);
        if (ret == -1)
            NSLog(@"sleep with err %d (state HLR response)", errno);
    }
    
    /* If no response from HLR, we cannot continue the test */
    if (messageState == noHlrResponse)
        goto noSubmitTest;
    if (closed)
        goto noSubmitTest;
    if (ret == -1)
        goto noSubmitTest;
    
    BOOL messages_equal = [outMessage equals:msg];
    STAssertTrue(messages_equal, @"the message the server receivedpo msg should be same as the client sent");
    networkErrorCode = [outMessage networkErrorCode];
    [outMessage networkErrorCode];
    STAssertTrue(networkErrorCode == 0, @"network error code should be ESME ROK");
    
    ReportState reportState = reportNotKnown;
    BOOL mustQuit;
    outMessage = nil;
    while (reportState < hlrSent && messageState < hlrReport && !(closed = [smpptest outconnectionClosed]) && ret == 0) /* HLR delivery report, i.e., route avaibility */
    {
        outReports = [router outReports];
        reportKeys = [outReports allKeys];
        reportValues = [outReports allValues];
        if ([reportValues count] > 0)
            outReport = [reportValues objectAtIndex:0];
        if (outReport)
             reportState = [outReport reportState];
        
        outMessages = [router outMessages];
        outKeys = [outMessages allKeys];
        outValues = [outMessages allValues];
        if ([outValues count] > 0)
            outMessage = [outValues objectAtIndex:0];
        if (outMessage)
            messageState = [outMessage state];
        mustQuit = [router mustQuit];
        
        ret = usleep(10000);
        if (ret == -1)
            NSLog(@"sleep with err %d (state HLR report)", errno);
    }
    
    /* If no routing information, end the submit test*/
    if (reportState == noHlrSent && messageState == noHlrReport)
        goto noSubmitTest;
    if (mustQuit)
        goto noSubmitTest;
    if (closed)
        goto noSubmitTest;
    if (ret == -1)
        goto noSubmitTest;
    
    outValues = [outMessages allValues];
    if ([outValues count] > 0)
        outMessage = [outValues objectAtIndex:0];
    else
        outMessage = nil;
    networkErrorCode = [outMessage networkErrorCode];
    STAssertTrue(networkErrorCode == 0, @"network error code should be ESME ROK");
    
    outMessage = nil;
    while (messageState < acked && !(closed = [smpptest outconnectionClosed]) && ret == 0) /* Forwarder response to submit */
    {
        outMessages = [router outMessages];
        outKeys = [outMessages allKeys];
        if ([outKeys count] > 0)
            outMessage = [outMessages objectForKey:[outKeys objectAtIndex:0]];
        if (outMessage)
            messageState = [outMessage state];
        ret = usleep(10000);
        if (ret == -1)
            NSLog(@"sleep with err %d (state acked)", errno);
    }
    if (messageState == notSent)
        goto noSubmitTest;
    if (closed)
        goto noSubmitTest;
    if (ret == -1)
        goto noSubmitTest;
    
    while (reportState < reportSent && messageState < delivered && !(closed = [smpptest outconnectionClosed]) && ret == 0) /* delivery report from forwarder */
    {
        outReports = [router outReports];
        reportKeys = [outReports allKeys];
        reportValues = [outReports allValues];
        if ([reportValues count] > 0)
            outReport = [reportValues objectAtIndex:0];
        if (outReport)
            reportState = [outReport reportState];
        
        outMessages = [router outMessages];
        outKeys = [outMessages allKeys];
        outValues = [outMessages allValues];
        if ([outValues count] > 0)
            outMessage = [outValues objectAtIndex:0];
        if (outMessage)
            messageState = [outMessage state];
        
        ret = usleep(10000);
        if (ret == -1)
            NSLog(@"sleep with err %d (state delivered)", errno);
    }
    
    if (messageState == notDelivered)
        goto noSubmitTest;
    if (reportState == reportNotSent)
        goto noSubmitTest;
    if (closed)
        goto noSubmitTest;
    if (ret == -1)
        goto noSubmitTest;
    
    outValues = [outMessages allValues];
    if ([outValues count] > 0)
         outMessage = [outValues objectAtIndex:0];
    else
        outMessage = nil;
    messageState = [outMessage state];
    STAssertTrue(messageState == delivered, @"message state should be delivered");
    
noSubmitTest:
    [smpptest configDeliverTest:&msg2];
    [router proxyDeliverMessage:msg2 forObject:[global_appDelegate smppProxyConnection]];
    outMessages = [router outMessages];
    STAssertNotNil(outMessages, @"outMessages directory should exist after sending a message from server to client");
    STAssertTrue([outMessages count] == 1, @"we should have one message in outMessages directory");
    outKeys = [outMessages allKeys];
    outValues = [outMessages allValues];
    
    inMessages = [router inMessages];
    STAssertNotNil(inMessages, @"inMessages directory should exist after sending a message from server to client");
    STAssertTrue([inMessages count] == 1, @"we should have zeros in inMessages directory");
    inKeys = [inMessages allKeys];
    inValues = [inMessages allValues];
    
    outReports = [router outReports];
    STAssertNotNil(outReports, @"outReports directory should exist after sending a message from client to server");
    STAssertTrue([outReports count] == 2, @"we should have two reports (one fron HLR and one from forwarder)in outReports directory");
    reportKeys = [outReports allKeys];
    reportValues = [outReports allValues];

    DeliverMessageState deliverMessageState = deliverNotKnown;
    while (deliverMessageState < deliverHlrResponse && !(closed = [smpptest outconnectionClosed]) && ret == 0) /* HLR response to submit, i.e, a route query*/
    {
        inMessages = [router inMessages];
        inKeys = [inMessages allKeys];
        if ([inKeys count] > 0)
            inMessage = [inMessages objectForKey:[inKeys objectAtIndex:0]];
        if (inMessage)
            deliverMessageState = [inMessage state];
        ret = usleep(10000);
        if (ret == -1)
            NSLog(@"sleep with err %d, incoming %@ (waiting for deliverHlrResponse)", errno, [smpptest inconnectionClosed] ? @"closed" : @"not closed");
    }
    
    /* If no response from HLR, we cannot continue the test */
    if (messageState == deliverNoHlrResponse)
        goto testEnd;
    if (closed)
        goto testEnd;
    if (ret == -1)
        goto testEnd;
    
    messages_equal = [inMessage equals:msg2];
    STAssertTrue(messages_equal, @"the message the server receivedpo msg should be same as the client sent");
    networkErrorCode = [inMessage networkErrorCode];
    STAssertTrue(networkErrorCode == 0, @"network error code should be ESME ROK");
    
    DeliverReportState deliverReportState = deliverReportNotKnown;
    outMessage = nil;
    while (deliverReportState < deliverHlrSent && deliverMessageState < deliverHlrReport && !(closed = [smpptest outconnectionClosed])  && ret == 0) /* HLR delivery report, i.e., route avaibility */
    {
        outReports = [router outReports];
        reportKeys = [outReports allKeys];
        reportValues = [outReports allValues];
        if ([reportValues count] > 0)
            outReport = [reportValues objectAtIndex:1];
        if (outReport)
            deliverReportState = [outReport reportState];
        
        inMessages = [router inMessages];
        inKeys = [inMessages allKeys];
        inValues = [inMessages allValues];
        if ([inValues count] > 0)
            inMessage = [inValues objectAtIndex:1];
        if (inMessage)
            deliverMessageState = [inMessage state];
        
        ret = usleep(10000);
        if (ret == -1)
            NSLog(@"sleep with err %d incoming %@ (waiting for deliverHlrReport)", errno, [smpptest inconnectionClosed] ? @"closed" : @"not closed");
    }

    /* If no routing information, end the test*/
    if (deliverReportState == deliverNoHlrSent && deliverMessageState == deliverNoHlrReport)
        goto testEnd;
    if ([router mustQuit])
        goto testEnd;
    if (closed)
        goto testEnd;
    if (ret == -1)
        goto testEnd;
    
    inValues = [inMessages allValues];
    if ([inValues count] > 0)
        inMessage = [inValues objectAtIndex:1];
    else
        inMessage = nil;
    networkErrorCode = [inMessage networkErrorCode];
    STAssertTrue(networkErrorCode == 0, @"network error code should be ESME ROK");
    
    inMessage = nil;
    while (deliverMessageState < deliverAcked && !(closed = [smpptest outconnectionClosed]) && ret == 0) /* Icoming response to deliver */
    {
        inMessages = [router inMessages];
        inKeys = [inMessages allKeys];
        inValues = [inMessages allValues];
        if ([inValues count] > 0)
            inMessage = [inValues objectAtIndex:0];
        if (inMessage)
            deliverMessageState = [inMessage state];
        ret = usleep(10000);
        if (ret == -1)
            NSLog(@"sleep with err %d incoming %@ (waiting for deliver ack)", errno, [smpptest inconnectionClosed] ? @"closed" : @"not closed");
    }
    if (deliverMessageState == deliverNotSent)
        goto testEnd;
    if (closed)
        goto testEnd;
    if (ret == -1)
        goto testEnd;
    
    inMessages = [router inMessages];
    STAssertNotNil(inMessages, @"inMessages directory should exist after sending a message from server to client");
    STAssertTrue([inMessages count] == 1, @"we should have one message in inMessages directory");
    inKeys = [inMessages allKeys];
    inValues = [inMessages allValues];
    inMessage = [inValues objectAtIndex:0];
    STAssertTrue([inMessage equals:msg], @"the message the client received should be same as the server sent");
    networkErrorCode = [inMessage networkErrorCode];
    STAssertTrue(networkErrorCode == 0, @"network error code should be ESME ROK");
    
    usleep(50000);

testEnd:
 //   [global_appDelegate release];
 //   [pool release];
}

@end
