 //
//  TestMessage.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 27.09.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "TestMessage.h"
#import "SmscConnectionSMPP.h"
#import "ulib/ulib.h"

@implementation TestMessage

@synthesize dbStatusFlags;
@synthesize dbRouterReference;
@synthesize dbUserReference;
@synthesize dbUserMessageReference;
@synthesize dbConnectionReference;
@synthesize dbType;
@synthesize dbMethod;
@synthesize dbInboundMethod;
@synthesize dbAddr;
@synthesize dbInboundType;
@synthesize dbInboundAddress;
@synthesize dbFrom;
@synthesize dbTo;
@synthesize dbReportTo;

@synthesize dbReportMask;
@synthesize dbPduDcs;
@synthesize dbPduCoding;
@synthesize dbPduPid;
@synthesize dbPduUdhi;
@synthesize dbPduRp;

@synthesize dbPduUdh;
@synthesize dbPduContent;

@synthesize dbSubmitDate;
@synthesize dbSubmitAckTime;
@synthesize dbSubmitErrTime;
@synthesize dbAttemptedDate;

@synthesize dbValidity;
@synthesize dbDeferred;

@synthesize dbSubmitString;

@synthesize dbSubmitErrCode;
@synthesize dbNetworkErrorCode;

@synthesize dbMessageState;
@synthesize dbPriority;
@synthesize dbReplaceIfPresentFlag;

@synthesize dbMsc;
@synthesize dbSmsc1;
@synthesize dbSmsc2;
@synthesize dbSmsc3;
@synthesize dbOpc1;
@synthesize dbDpc1;
@synthesize dbOpc2;
@synthesize dbDpc2;
@synthesize dbUserflags;

@synthesize dbHlr;
@synthesize dbImsi;
@synthesize dbMnc;
@synthesize dbMcc;
@synthesize dbResponseUrl;

@synthesize userTransaction;
@synthesize routerTransaction;
@synthesize connectionTransaction;
@synthesize originalSendingObject;

@synthesize state;
@synthesize deliverState;

- (TestMessage *)init
{
    if((self=[super init]))
    {
        dbRouterReference = [[UMStringWithHistory alloc]init];
        dbConnectionReference = [[UMStringWithHistory alloc]init];
        dbUserReference = [[UMStringWithHistory alloc]init];
        dbUserMessageReference = [[UMDataWithHistory alloc]init];
        dbType = [[UMStringWithHistory alloc]init];
        dbMethod = [[UMStringWithHistory alloc]init];
        dbInboundMethod = [[UMStringWithHistory alloc]init];
        dbAddr = [[UMStringWithHistory alloc]init];
        dbInboundType = [[UMStringWithHistory alloc]init];
        dbInboundAddress = [[UMStringWithHistory alloc]init];
        dbFrom = [[UMStringWithHistory alloc]init];
        dbTo = [[UMStringWithHistory alloc]init];
        dbReportTo = [[UMStringWithHistory alloc]init];
        dbReportMask = [[UMIntegerWithHistory alloc]init];
        dbPduDcs = [[UMIntegerWithHistory alloc]init];
        dbPduCoding = [[UMIntegerWithHistory alloc]init];
        dbPduPid = [[UMIntegerWithHistory alloc]init];
        dbPduUdhi = [[UMIntegerWithHistory alloc]init];
        dbPduRp = [[UMIntegerWithHistory alloc]init];
        dbPduUdh = [[UMDataWithHistory alloc]init];
        dbPduContent = [[UMDataWithHistory alloc]init];
        dbSubmitDate = [[UMDateWithHistory alloc]init];
        dbSubmitAckTime = [[UMDateWithHistory alloc]init];
        dbSubmitErrTime = [[UMDateWithHistory alloc]init];
        dbAttemptedDate = [[UMDateWithHistory alloc]init];
        dbValidity = [[UMDateWithHistory alloc]init];
        dbDeferred = [[UMDateWithHistory alloc]init];
        dbSubmitString = [[UMStringWithHistory alloc]init];
        dbSubmitErrCode = [[UMIntegerWithHistory alloc]init];
        dbNetworkErrorCode = [[UMIntegerWithHistory alloc]init];
        dbMessageState = [[UMIntegerWithHistory alloc]init];
        dbPriority = [[UMIntegerWithHistory alloc]init];
        dbReplaceIfPresentFlag = [[UMIntegerWithHistory alloc]init];
        dbMsc = [[UMStringWithHistory alloc]init];
        dbSmsc1 = [[UMStringWithHistory alloc]init];
        dbSmsc2 = [[UMStringWithHistory alloc]init];
        dbSmsc3 = [[UMStringWithHistory alloc]init];
        dbOpc1 = [[UMStringWithHistory alloc]init];
        dbDpc1 = [[UMStringWithHistory alloc]init];
        dbOpc2 = [[UMStringWithHistory alloc]init];
        dbDpc2 = [[UMStringWithHistory alloc]init];
        dbUserflags = [[UMStringWithHistory alloc]init];
        dbHlr = [[UMStringWithHistory alloc]init];
        dbImsi = [[UMStringWithHistory alloc]init];
        dbMnc = [[UMStringWithHistory alloc]init];
        dbMcc = [[UMStringWithHistory alloc]init];
        dbResponseUrl = [[UMStringWithHistory alloc]init];
    }
    return self;
}

- (NSString *)description
{
    NSString *contentString = [[NSString alloc] initWithData:[dbPduContent data] encoding:NSUTF8StringEncoding];
    
    NSMutableString *desc = [[NSMutableString alloc]init];
    [desc appendFormat: @"routerReference: %@\n",dbRouterReference];
    [desc appendFormat: @"connectionReference: %@\n",dbConnectionReference];
    [desc appendFormat: @"userReference: %@\n",dbUserReference];
    [desc appendFormat: @"userMessageReference: %@\n",dbUserMessageReference];
    [desc appendFormat: @"type: %@\n",dbType];
    [desc appendFormat: @"method: %@\n",dbMethod];
    [desc appendFormat: @"inboundMethod: %@\n",dbInboundMethod];
    [desc appendFormat: @"addr: %@\n",dbAddr];
    [desc appendFormat: @"inboundType: %@\n",dbInboundType];
    [desc appendFormat: @"inboundAddress: %@\n",dbInboundAddress];
    [desc appendFormat: @"from: %@\n",dbFrom];
    [desc appendFormat: @"to: %@\n",dbTo];
    [desc appendFormat: @"reportTo: %@\n",dbReportTo];
    [desc appendFormat: @"reportMask: %@\n",dbReportMask];
    [desc appendFormat: @"pduDcs: %@\n",dbPduDcs];
    [desc appendFormat: @"pduCoding: %@\n",dbPduCoding];
    [desc appendFormat: @"pduPid: %@\n",dbPduPid];
    [desc appendFormat: @"pduUdhi: %@\n",dbPduUdhi];
    [desc appendFormat: @"pduRp: %@\n",dbPduRp];
    [desc appendFormat: @"pduUDH: %@\n",dbPduUdh];
    [desc appendFormat: @"pduContent: %@\n",dbPduContent];
    [desc appendFormat: @"  = '%@'\n",[[dbPduContent data]stringFromGsm7withNibbleLengthPrefix]];
    [desc appendFormat: @"as string: %@\n", contentString];
    [desc appendFormat: @"submitDate: %@\n",dbSubmitDate];
    [desc appendFormat: @"submitAckTime: %@\n",dbSubmitAckTime];
    [desc appendFormat: @"submitErrTime: %@\n",dbSubmitErrTime];
    [desc appendFormat: @"attemptedDate: %@\n",dbAttemptedDate];
    [desc appendFormat: @"validity: %@\n",dbValidity];
    [desc appendFormat: @"deferred: %@\n",dbDeferred];
    [desc appendFormat: @"submitString: %@\n",dbSubmitString];
    [desc appendFormat: @"submitErrCode: %@\n",dbSubmitErrCode];
    [desc appendFormat: @"networkErrorCode: %@\n",dbNetworkErrorCode];
    [desc appendFormat: @"messageState: %@\n",dbMessageState];
    [desc appendFormat: @"priority: %@\n",dbPriority];
    [desc appendFormat: @"replaceIfPresentFlag: %@\n",dbReplaceIfPresentFlag];
    [desc appendFormat: @"userTransaction: %p\n",userTransaction];
    [desc appendFormat: @"routerTansaction: %p\n",routerTransaction];
    [desc appendFormat: @"connectionTransaction: %p\n",connectionTransaction];
    [desc appendFormat: @"responseUrl: %@\n",dbResponseUrl];
    [desc appendFormat: @"imsi: %@\n",dbImsi];
    [desc appendFormat: @"msc: %@\n",dbMsc];
    [desc appendFormat: @"smsc1: %@\n",dbSmsc1];
    [desc appendFormat: @"smsc2: %@\n",dbSmsc2];
    [desc appendFormat: @"smsc3: %@\n",dbSmsc3];
    [desc appendFormat: @"opc1: %@\n",dbOpc1];
    [desc appendFormat: @"dpc1: %@\n",dbDpc1];
    [desc appendFormat: @"opc2: %@\n",dbOpc2];
    [desc appendFormat: @"dpc2: %@\n",dbDpc2];
    [desc appendFormat: @"userflags: %@\n",dbUserflags];
    [desc appendFormat: @"hlr: %@\n",dbHlr];
    [desc appendFormat: @"mnc: %@\n",dbMnc];
    [desc appendFormat: @"mcc: %@\n",dbMcc];
    [desc appendFormat: @"----\n"];
    [desc appendFormat: @"originalSendingObject: %@\n",originalSendingObject];
    [desc appendFormat: @"userTransaction: %@\n",userTransaction];
    [desc appendFormat: @"routerTransaction: %@\n",routerTransaction];
    [desc appendFormat: @"connectionTransaction: %@\n",connectionTransaction];
    [desc appendFormat: @"message state not in db: %@\n", [self messageStateToString]];
    [desc appendFormat: @"deliver message state not in db: %@\n", [self deliverMessageStateToString]];
    [desc appendFormat: @"----\n"];
    return desc;
}

- (BOOL)equals:(TestMessage *)msg
{
    if (!dbType && [msg dbType])
        return FALSE;
    if (dbType &&  ![msg dbType])
        return FALSE;
    if (![self.type isEqualToString:msg.type])
        return FALSE;
    if (!dbMethod && [msg dbMethod])
        return FALSE;
    if (dbMethod &&  ![msg dbMethod])
        return FALSE;
    if (![self.method isEqualToString:msg.method])
        return FALSE;
    if (!dbInboundMethod && [msg dbInboundMethod])
        return FALSE;
    if (dbInboundMethod &&  ![msg dbInboundMethod])
        return FALSE;
    if (![self.inboundMethod isEqualToString:msg.inboundMethod])
        return FALSE;
    if (!dbAddr && [msg dbAddr])
        return FALSE;
    if (dbAddr &&  ![msg dbAddr])
        return FALSE;
    if (![self.addr isEqualToString:msg.addr])
        return FALSE;
    if (!dbInboundType && [msg dbInboundType])
        return FALSE;
    if (dbInboundType &&  ![msg dbInboundType])
        return FALSE;
    if (![self.inboundType isEqualToString:msg.inboundType])
        return FALSE;
    if (!dbInboundAddress && [msg dbInboundAddress])
        return FALSE;
    if (dbInboundAddress &&  ![msg dbInboundAddress])
        return FALSE;
    if (![self.inboundAddress isEqualToString:msg.inboundAddress])
        return FALSE;
    if (!dbTo && [msg dbTo])
        return FALSE;
    if (dbTo &&  ![msg dbTo])
        return FALSE;
    if (![self.to.asString isEqualToString:msg.to.asString])
        return FALSE;
    if (!dbFrom && [msg dbFrom])
        return FALSE;
    if (dbFrom &&  ![msg dbFrom])
        return FALSE;
    if (![self.from.asString isEqualToString:msg.from.asString])
        return FALSE;
    if (!dbReportTo && [msg dbReportTo])
        return FALSE;
    if (dbReportTo &&  ![msg dbReportTo])
        return FALSE;
    if (![self.reportTo.asString isEqualToString:msg.reportTo.asString])
        return FALSE;
    if (self.reportMask != msg.reportMask)
        return FALSE;
    if (self.pduDcs != msg.pduDcs)
        return FALSE;
    if (self.pduCoding != msg.pduCoding)
        return FALSE;
    if (self.pduPid != msg.pduPid)
        return FALSE;
    if (self.pduUdhi != msg.pduUdhi)
        return FALSE;
    if (self.pduRp != msg.pduRp)
        return FALSE;
    if (!dbPduUdh && [msg dbPduUdh])
        return FALSE;
    if (dbPduUdh &&  ![msg dbPduUdh])
        return FALSE;
    if (![self.pduUdh isEqualToData:msg.pduUdh])
        return FALSE;
    if (!dbPduContent && [msg dbPduContent])
        return FALSE;
    if (dbPduContent &&  ![msg dbPduContent])
        return FALSE;
    if (![self.pduContent isEqualToData:msg.pduContent])
        return FALSE;
    if (!dbSubmitDate && [msg dbSubmitDate])
        return FALSE;
    if (dbSubmitDate &&  ![msg dbPduContent])
        return FALSE;
    if (![self.submitDate isEqualToDate:msg.submitDate])
        return FALSE;
    if (!dbSubmitAckTime && [msg dbSubmitAckTime])
        return FALSE;
    if (dbSubmitAckTime &&  ![msg dbSubmitAckTime])
        return FALSE;
    if (![self.submitAckTime isEqualToDate:msg.submitAckTime])
        return FALSE;
    if (!dbSubmitErrTime && [msg dbSubmitErrTime])
        return FALSE;
    if (dbSubmitErrTime &&  ![msg dbSubmitErrTime])
        return FALSE;
    if (![self.submitErrTime isEqualToDate:msg.submitErrTime])
        return FALSE;
    if (!dbAttemptedDate && [msg dbAttemptedDate])
        return FALSE;
    if (dbAttemptedDate &&  ![msg dbAttemptedDate])
        return FALSE;
    if (![self.attemptedDate isEqualToDate:msg.attemptedDate])
        return FALSE;
    if (!dbValidity && [msg dbValidity])
        return FALSE;
    if (dbValidity &&  ![msg dbValidity])
        return FALSE;
    if (![self.validity isEqualToDate:msg.validity])
        return FALSE;
    if (!dbDeferred && [msg dbDeferred])
        return FALSE;
    if (dbDeferred &&  ![msg dbDeferred])
        return FALSE;
    if (![self.deferred isEqualToDate:msg.deferred])
        return FALSE;
    if (!dbSubmitString && [msg dbSubmitString])
        return FALSE;
    if (dbSubmitString &&  ![msg dbSubmitString])
        return FALSE;
    if (![self.submitString isEqualToString:msg.submitString])
        return FALSE;
    if (self.submitErrCode != msg.submitErrCode)
        return FALSE;
    if (self.networkErrorCode != msg.networkErrorCode)
        return FALSE;
    if (self.priority != msg.priority)
        return FALSE;
    if (self.replaceIfPresentFlag != msg.replaceIfPresentFlag)
        return FALSE;

    return TRUE;
}

- (NSData *)pduContentIncludingUdh
{
    if(self.pduUdhi)
    {
        NSMutableData *d = [NSMutableData dataWithData:self.pduUdh];
        [d appendData:self.pduContent];
        return d;
    }
    else
    {
        return self.pduContent;
    }
}


- (NSString *)messageStateToString
{
    switch (state)
    {
        case notKnown:
            return @"not known";
        case accepted:
            return @"accepted";
        case hlrResponse:
            return @"hlr response";
        case noHlrResponse:
            return @"no hlt response";
        case acked:
            return @"acked";
        case notSent:
            return @"not sent";
        case hlrReport:
            return @"hlr report received";
        case noHlrReport:
            return @"no  hlr report received";
        case delivered:
            return @"delivered";
        case notDelivered:
            return @"not delivered";
    }
    
    return @"unknown";
}

- (NSString *)deliverMessageStateToString
{
    switch (state)
    {
        case deliverNotKnown:
            return @"deliver not known";
        case deliverAccepted:
            return @"deliver accepted";
        case deliverHlrResponse:
            return @"deliver hlr response";
        case deliverNoHlrResponse:
            return @"deliver no hlt response";
        case deliverAcked:
            return @"deliver acked";
        case deliverNotSent:
            return @"deliver ot sent";
        case deliverHlrReport:
            return @"deliver hlr report received";
        case deliverNoHlrReport:
            return @"deliver no hlr report received";
        case deliverDelivered:
            return @"delivered";
        case notDelivered:
            return @"not delivered";
    }
    
    return @"unknown";
}

- (UMSigAddr *)to
{
    SigAddr *toSigaddr = [[SigAddr alloc]initWithString:self.dbTo.string];
    return toSigaddr;
}


- (NSString *)toString
{
    return [dbTo string];
}

- (void)setToString:(NSString *)t
{
    self.dbTo.string = t;
}

- (void) setTo:(UMSigAddr *)to
{
    self.dbTo.string = [to asString];
}


- (UMSigAddr *)from
{
    SigAddr *fromSigaddr = [[SigAddr alloc]initWithString:self.dbFrom.string];
    return fromSigaddr;
}

- (NSString *)fromString
{
    return [dbFrom string];
}

- (void)setFromString:(NSString *)f
{
    self.dbFrom.string = f;
}

- (void) setFrom:(UMSigAddr *)from
{
    self.dbFrom.string = [from asString];
}
#if 0
+(dbFieldDef *)tableDefinition
{
    return db_message_fields;
}
#endif
- (NSArray *)arrayForInsert
{
    NSArray *params  = [NSArray arrayWithObjects:
                        [dbRouterReference nonNullString],
                        [dbConnectionReference nonNullString],
                        [dbUserReference nonNullString],
                        [dbUserMessageReference nonNullString],
                        [dbType nonNullString],
                        [dbMethod nonNullString],
                        [dbInboundMethod nonNullString],
                        [dbAddr nonNullString],
                        [dbInboundType nonNullString],
                        [dbInboundAddress nonNullString],
                        [dbFrom nonNullString],
                        [dbTo nonNullString],
                        [dbReportTo nonNullString],
                        [dbReportMask nonNullString],
                        [dbPduDcs nonNullString],
                        [dbPduCoding nonNullString],
                        [dbPduPid nonNullString],
                        [dbPduUdhi nonNullString],
                        [dbPduRp nonNullString],
                        [dbPduUdh nonNullString],
                        [dbPduContent nonNullString],
                        [dbSubmitDate nonNullString],
                        [dbSubmitAckTime nonNullString],
                        [dbSubmitErrTime nonNullString],
                        [dbAttemptedDate nonNullString],
                        [dbValidity nonNullString],
                        [dbDeferred nonNullString],
                        [dbSubmitString nonNullString],
                        [dbSubmitErrCode nonNullString],
                        [dbNetworkErrorCode nonNullString],
                        [dbMessageState nonNullString],
                        [dbPriority nonNullString],
                        [dbReplaceIfPresentFlag nonNullString],
                        [dbMsc nonNullString],
                        [dbSmsc1 nonNullString],
                        [dbSmsc2 nonNullString],
                        [dbSmsc3 nonNullString],
                        [dbOpc1 nonNullString],
                        [dbDpc1 nonNullString],
                        [dbOpc2 nonNullString],
                        [dbDpc2 nonNullString],
                        [dbUserflags nonNullString],
                        [dbHlr nonNullString],
                        [dbImsi nonNullString],
                        [dbMnc nonNullString],
                        [dbMcc nonNullString],
                        [dbResponseUrl nonNullString],
                        NULL];
    return params;
}

-(void)clearDirtyFlags
{
    [dbRouterReference clearDirtyFlag];
    [dbConnectionReference clearDirtyFlag];
    [dbUserReference clearDirtyFlag];
    [dbUserMessageReference clearDirtyFlag];
    [dbType clearDirtyFlag];
    [dbMethod clearDirtyFlag];
    [dbInboundMethod clearDirtyFlag];
    [dbAddr clearDirtyFlag];
    [dbInboundType clearDirtyFlag];
    [dbInboundAddress clearDirtyFlag];
    [dbFrom clearDirtyFlag];
    [dbTo clearDirtyFlag];
    [dbReportTo clearDirtyFlag];
    [dbReportMask clearDirtyFlag];
    [dbPduDcs clearDirtyFlag];
    [dbPduCoding clearDirtyFlag];
    [dbPduPid clearDirtyFlag];
    [dbPduUdhi clearDirtyFlag];
    [dbPduRp clearDirtyFlag];
    [dbPduUdh clearDirtyFlag];
    [dbPduContent clearDirtyFlag];
    [dbSubmitDate clearDirtyFlag];
    [dbSubmitAckTime clearDirtyFlag];
    [dbSubmitErrTime clearDirtyFlag];
    [dbAttemptedDate clearDirtyFlag];
    [dbValidity clearDirtyFlag];
    [dbDeferred clearDirtyFlag];
    [dbSubmitString clearDirtyFlag];
    [dbSubmitErrCode clearDirtyFlag];
    [dbNetworkErrorCode clearDirtyFlag];
    [dbMessageState clearDirtyFlag];
    [dbPriority clearDirtyFlag];
    [dbReplaceIfPresentFlag clearDirtyFlag];
    [dbMsc clearDirtyFlag];
    [dbSmsc1 clearDirtyFlag];
    [dbSmsc2 clearDirtyFlag];
    [dbSmsc3 clearDirtyFlag];
    [dbOpc1 clearDirtyFlag];
    [dbDpc1 clearDirtyFlag];
    [dbOpc2 clearDirtyFlag];
    [dbDpc2 clearDirtyFlag];
    [dbUserflags clearDirtyFlag];
    [dbHlr clearDirtyFlag];
    [dbImsi clearDirtyFlag];
    [dbMnc clearDirtyFlag];
    [dbMcc clearDirtyFlag];
    [dbResponseUrl clearDirtyFlag];
}

- (NSArray *)arraysForUpdate
{
    NSMutableArray *fields = [[NSMutableArray alloc]init];
    NSMutableArray *values = [[NSMutableArray alloc]init];
    NSMutableArray *oldValues = [[NSMutableArray alloc]init];
    
    if([dbRouterReference hasChanged])
    {
        [fields addObject:@"RouterReference"];
        [values addObject:[dbRouterReference nonNullString]];
        [oldValues addObject:[dbRouterReference oldNonNullString]];
    }
    
    if([dbConnectionReference hasChanged])
    {
        [fields addObject:@"ConnectionReference"];
        [values addObject:[dbConnectionReference nonNullString]];
        [oldValues addObject:[dbConnectionReference oldNonNullString]];
    }
    if([dbUserReference hasChanged])
    {
        [fields addObject:@"UserReference"];
        [values addObject:[dbUserReference nonNullString]];
        [oldValues addObject:[dbUserReference oldNonNullString]];
    }
    
    if([dbUserMessageReference hasChanged])
    {
        [fields addObject:@"UserMessageReference"];
        [values addObject:[dbUserMessageReference nonNullString]];
        [oldValues addObject:[dbUserMessageReference oldNonNullString]];
    }
    
    if([dbType hasChanged])
    {
        [fields addObject:@"Type"];
        [values addObject:[dbType nonNullString]];
        [oldValues addObject:[dbType oldNonNullString]];
    }
    
    if([dbMethod hasChanged])
    {
        [fields addObject:@"Method"];
        [values addObject:[dbMethod nonNullString]];
        [oldValues addObject:[dbMethod oldNonNullString]];
    }
    
    if([dbInboundMethod hasChanged])
    {
        [fields addObject:@"InboundMethod"];
        [values addObject:[dbInboundMethod nonNullString]];
        [oldValues addObject:[dbInboundMethod oldNonNullString]];
    }
    
    if([dbAddr hasChanged])
    {
        [fields addObject:@"Addr"];
        [values addObject:[dbAddr nonNullString]];
        [oldValues addObject:[dbAddr oldNonNullString]];
    }
    
    if([dbInboundType hasChanged])
    {
        [fields addObject:@"InboundType"];
        [values addObject:[dbInboundType nonNullString]];
        [oldValues addObject:[dbInboundType oldNonNullString]];
    }
    
    if([dbInboundAddress hasChanged])
    {
        [fields addObject:@"InboundAddress"];
        [values addObject:[dbInboundAddress nonNullString]];
        [oldValues addObject:[dbInboundAddress oldNonNullString]];
    }
    
    if([dbFrom hasChanged])
    {
        [fields addObject:@"From"];
        [values addObject:[dbFrom nonNullString]];
        [oldValues addObject:[dbFrom oldNonNullString]];
    }
    
    if([dbTo hasChanged])
    {
        [fields addObject:@"To"];
        [values addObject:[dbTo nonNullString]];
        [oldValues addObject:[dbTo oldNonNullString]];
    }
    
    if([dbReportTo hasChanged])
    {
        [fields addObject:@"ReportTo"];
        [values addObject:[dbReportTo nonNullString]];
        [oldValues addObject:[dbReportTo oldNonNullString]];
    }
    
    if([dbReportMask hasChanged])
    {
        [fields addObject:@"ReportMask"];
        [values addObject:[dbReportMask nonNullString]];
        [oldValues addObject:[dbReportMask oldNonNullString]];
    }
    
    if([dbPduDcs hasChanged])
    {
        [fields addObject:@"PduDcs"];
        [values addObject:[dbPduDcs nonNullString]];
        [oldValues addObject:[dbPduDcs oldNonNullString]];
    }
    
    if([dbPduCoding hasChanged])
    {
        [fields addObject:@"PduCoding"];
        [values addObject:[dbPduCoding nonNullString]];
        [oldValues addObject:[dbPduCoding oldNonNullString]];
    }
    
    if([dbPduPid hasChanged])
    {
        [fields addObject:@"PduPid"];
        [values addObject:[dbPduPid nonNullString]];
        [oldValues addObject:[dbPduPid oldNonNullString]];
    }
    
    if([dbPduUdhi hasChanged])
    {
        [fields addObject:@"PduUdhi"];
        [values addObject:[dbPduUdhi nonNullString]];
        [oldValues addObject:[dbPduUdhi oldNonNullString]];
    }
    
    if([dbPduRp hasChanged])
    {
        [fields addObject:@"PduRp"];
        [values addObject:[dbPduRp nonNullString]];
        [oldValues addObject:[dbPduRp oldNonNullString]];
    }
    
    if([dbPduUdh hasChanged])
    {
        [fields addObject:@"PduUdh"];
        [values addObject:[dbPduUdh nonNullString]];
        [oldValues addObject:[dbPduUdh oldNonNullString]];
    }
    
    if([dbPduContent hasChanged])
    {
        [fields addObject:@"PduContent"];
        [values addObject:[dbPduContent nonNullString]];
        [oldValues addObject:[dbPduContent oldNonNullString]];
    }
    
    if([dbSubmitDate hasChanged])
    {
        [fields addObject:@"SubmitDate"];
        [values addObject:[dbSubmitDate nonNullString]];
        [oldValues addObject:[dbSubmitDate oldNonNullString]];
    }
    
    if([dbSubmitAckTime hasChanged])
    {
        [fields addObject:@"SubmitAckTime"];
        [values addObject:[dbSubmitAckTime nonNullString]];
        [oldValues addObject:[dbSubmitAckTime oldNonNullString]];
    }
    
    if([dbSubmitErrTime hasChanged])
    {
        [fields addObject:@"SubmitErrTime"];
        [values addObject:[dbSubmitErrTime nonNullString]];
        [oldValues addObject:[dbSubmitErrTime oldNonNullString]];
    }
    
    if([dbAttemptedDate hasChanged])
    {
        [fields addObject:@"AttemptedDate"];
        [values addObject:[dbAttemptedDate nonNullString]];
        [oldValues addObject:[dbAttemptedDate oldNonNullString]];
    }
    
    if([dbValidity hasChanged])
    {
        [fields addObject:@"Validity"];
        [values addObject:[dbValidity nonNullString]];
        [oldValues addObject:[dbValidity oldNonNullString]];
    }
    
    if([dbDeferred hasChanged])
    {
        [fields addObject:@"Deferred"];
        [values addObject:[dbDeferred nonNullString]];
        [oldValues addObject:[dbDeferred oldNonNullString]];
    }
    
    if([dbSubmitString hasChanged])
    {
        [fields addObject:@"SubmitString"];
        [values addObject:[dbSubmitString nonNullString]];
        [oldValues addObject:[dbSubmitString oldNonNullString]];
    }
    
    if([dbSubmitErrCode hasChanged])
    {
        [fields addObject:@"SubmitErrCode"];
        [values addObject:[dbSubmitErrCode nonNullString]];
        [oldValues addObject:[dbSubmitErrCode oldNonNullString]];
    }
    
    if([dbNetworkErrorCode hasChanged])
    {
        [fields addObject:@"NetworkErrorCode"];
        [values addObject:[dbNetworkErrorCode nonNullString]];
        [oldValues addObject:[dbNetworkErrorCode oldNonNullString]];
    }
    
    if([dbMessageState hasChanged])
    {
        [fields addObject:@"MessageState"];
        [values addObject:[dbMessageState nonNullString]];
        [oldValues addObject:[dbMessageState oldNonNullString]];
    }
    
    if([dbPriority hasChanged])
    {
        [fields addObject:@"Priority"];
        [values addObject:[dbPriority nonNullString]];
        [oldValues addObject:[dbPriority oldNonNullString]];
    }
    
    if([dbReplaceIfPresentFlag hasChanged])
    {
        [fields addObject:@"ReplaceIfPresentFlag"];
        [values addObject:[dbReplaceIfPresentFlag nonNullString]];
        [oldValues addObject:[dbReplaceIfPresentFlag oldNonNullString]];
    }
    
    if([dbMsc hasChanged])
    {
        [fields addObject:@"Msc"];
        [values addObject:[dbMsc nonNullString]];
        [oldValues addObject:[dbMsc oldNonNullString]];
    }
    
    if([dbSmsc1 hasChanged])
    {
        [fields addObject:@"Smsc1"];
        [values addObject:[dbSmsc1 nonNullString]];
        [oldValues addObject:[dbSmsc1 oldNonNullString]];
    }
    
    if([dbSmsc2 hasChanged])
    {
        [fields addObject:@"Smsc2"];
        [values addObject:[dbSmsc2 nonNullString]];
        [oldValues addObject:[dbSmsc2 oldNonNullString]];
    }
    
    if([dbSmsc3 hasChanged])
    {
        [fields addObject:@"Smsc3"];
        [values addObject:[dbSmsc3 nonNullString]];
        [oldValues addObject:[dbSmsc3 oldNonNullString]];
    }
    
    if([dbOpc1 hasChanged])
    {
        [fields addObject:@"Opc1"];
        [values addObject:[dbOpc1 nonNullString]];
        [oldValues addObject:[dbOpc1 oldNonNullString]];
    }
    
    if([dbDpc1 hasChanged])
    {
        [fields addObject:@"Dpc1"];
        [values addObject:[dbDpc1 nonNullString]];
        [oldValues addObject:[dbDpc1 oldNonNullString]];
    }
    
    if([dbOpc2 hasChanged])
    {
        [fields addObject:@"Opc2"];
        [values addObject:[dbOpc2 nonNullString]];
        [oldValues addObject:[dbOpc2 oldNonNullString]];
    }
    
    if([dbDpc2 hasChanged])
    {
        [fields addObject:@"Dpc2"];
        [values addObject:[dbDpc2 nonNullString]];
        [oldValues addObject:[dbDpc2 oldNonNullString]];
    }
    
    if([dbUserflags hasChanged])
    {
        [fields addObject:@"Userflags"];
        [values addObject:[dbUserflags nonNullString]];
        [oldValues addObject:[dbUserflags oldNonNullString]];
    }
    
    if([dbHlr hasChanged])
    {
        [fields addObject:@"Hlr"];
        [values addObject:[dbHlr nonNullString]];
        [oldValues addObject:[dbHlr oldNonNullString]];
    }
    
    if([dbImsi hasChanged])
    {
        [fields addObject:@"Imsi"];
        [values addObject:[dbImsi nonNullString]];
        [oldValues addObject:[dbImsi oldNonNullString]];
    }
    
    if([dbMnc hasChanged])
    {
        [fields addObject:@"Mnc"];
        [values addObject:[dbMnc nonNullString]];
        [oldValues addObject:[dbMnc oldNonNullString]];
    }
    
    if([dbMcc hasChanged])
    {
        [fields addObject:@"Mcc"];
        [values addObject:[dbMcc nonNullString]];
        [oldValues addObject:[dbMcc oldNonNullString]];
    }
    
    if([dbResponseUrl hasChanged])
    {
        [fields addObject:@"ResponseUrl"];
        [values addObject:[dbResponseUrl nonNullString]];
        [oldValues addObject:[dbResponseUrl oldNonNullString]];
    }
    if([fields count]==0)
    {
        /* we return NULL if no update was needed so we can easier skip further processing */
        return NULL;
    }
    NSArray *a = [NSArray arrayWithObjects:fields,values,oldValues,@"RouterReference",[dbRouterReference nonNullString],[dbRouterReference oldNonNullString],NULL];
    return a;
}

- (void)loadFromRow:(NSArray *)row
{
    if(row == NULL)
        return;
    int i=0;
    [dbRouterReference loadFromString:[row objectAtIndex:i++]];
    [dbConnectionReference loadFromString:[row objectAtIndex:i++]];
    [dbUserReference loadFromString:[row objectAtIndex:i++]];
    [dbUserMessageReference loadFromString:[row objectAtIndex:i++]];
    [dbType loadFromString:[row objectAtIndex:i++]];
    [dbMethod loadFromString:[row objectAtIndex:i++]];
    [dbInboundMethod loadFromString:[row objectAtIndex:i++]];
    [dbAddr loadFromString:[row objectAtIndex:i++]];
    [dbInboundType loadFromString:[row objectAtIndex:i++]];
    [dbInboundAddress loadFromString:[row objectAtIndex:i++]];
    [dbFrom loadFromString:[row objectAtIndex:i++]];
    [dbTo loadFromString:[row objectAtIndex:i++]];
    [dbReportTo loadFromString:[row objectAtIndex:i++]];
    [dbReportMask loadFromString:[row objectAtIndex:i++]];
    [dbPduDcs loadFromString:[row objectAtIndex:i++]];
    [dbPduCoding loadFromString:[row objectAtIndex:i++]];
    [dbPduPid loadFromString:[row objectAtIndex:i++]];
    [dbPduUdhi loadFromString:[row objectAtIndex:i++]];
    [dbPduRp loadFromString:[row objectAtIndex:i++]];
    [dbPduUdh loadFromString:[row objectAtIndex:i++]];
    [dbPduContent loadFromString:[row objectAtIndex:i++]];
    [dbSubmitDate loadFromString:[row objectAtIndex:i++]];
    [dbSubmitAckTime loadFromString:[row objectAtIndex:i++]];
    [dbSubmitErrTime loadFromString:[row objectAtIndex:i++]];
    [dbAttemptedDate loadFromString:[row objectAtIndex:i++]];
    [dbValidity loadFromString:[row objectAtIndex:i++]];
    [dbDeferred loadFromString:[row objectAtIndex:i++]];
    [dbSubmitString loadFromString:[row objectAtIndex:i++]];
    [dbSubmitErrCode loadFromString:[row objectAtIndex:i++]];
    [dbNetworkErrorCode loadFromString:[row objectAtIndex:i++]];
    [dbMessageState loadFromString:[row objectAtIndex:i++]];
    [dbPriority loadFromString:[row objectAtIndex:i++]];
    [dbReplaceIfPresentFlag loadFromString:[row objectAtIndex:i++]];
    [dbMsc loadFromString:[row objectAtIndex:i++]];
    [dbSmsc1 loadFromString:[row objectAtIndex:i++]];
    [dbSmsc2 loadFromString:[row objectAtIndex:i++]];
    [dbSmsc3 loadFromString:[row objectAtIndex:i++]];
    [dbOpc1 loadFromString:[row objectAtIndex:i++]];
    [dbDpc1 loadFromString:[row objectAtIndex:i++]];
    [dbOpc2 loadFromString:[row objectAtIndex:i++]];
    [dbDpc2 loadFromString:[row objectAtIndex:i++]];
    [dbUserflags loadFromString:[row objectAtIndex:i++]];
    [dbHlr loadFromString:[row objectAtIndex:i++]];
    [dbImsi loadFromString:[row objectAtIndex:i++]];
    [dbMnc loadFromString:[row objectAtIndex:i++]];
    [dbMcc loadFromString:[row objectAtIndex:i++]];
    [dbResponseUrl loadFromString:[row objectAtIndex:i++]];
}

- (NSString *)textUTF8String
{
    return [self.pduContent stringFromGsm8];
}

- (void)setTextUTF8String:(NSString *)s
{
    self.pduContent = [s gsm8];
}

- (NSString *)userReference
{
	return dbUserReference.string;
}

- (void)setUserReference:(NSString *)string
{
	dbUserReference.string = string;
}


- (NSData *)userMessageReference
{
	return dbUserMessageReference.data;
}

- (void)setUserMessageReference:(NSData *)d
{
	dbUserMessageReference.data = d;
}

- (NSString *)routerReference
{
	return dbRouterReference.string;
}

- (void)setRouterReference:(NSString *)string
{
	dbRouterReference.string = string;
}


- (NSString *)connectionReference
{
	return dbConnectionReference.string;
}

- (void)setConnectionReference:(NSString *)string
{
	dbConnectionReference.string = string;
}

- (NSString *)type
{
	return dbType.string;
}

- (void)setType:(NSString *)string
{
	dbType.string = string;
}


- (NSString *)method
{
	return dbMethod.string;
}

- (void)setMethod:(NSString *)string
{
	dbMethod.string = string;
}


- (NSString *)inboundMethod
{
	return dbInboundMethod.string;
}

- (void)setInboundMethod:(NSString *)string
{
	dbInboundMethod.string = string;
}


- (NSString *)addr
{
	return dbAddr.string;
}

- (void)setAddr:(NSString *)string
{
	dbAddr.string = string;
}


- (NSString *)inboundType
{
	return dbInboundType.string;
}

- (void)setInboundType:(NSString *)string
{
	dbInboundType.string = string;
}

- (NSString *)inboundAddress
{
	return dbInboundAddress.string;
}

- (void)setInboundAddress:(NSString *)string
{
	dbInboundAddress.string = string;
}

- (NSString *)reportTo
{
	return dbReportTo.string;
}

- (void)setReportTo:(NSString *)string
{
	dbReportTo.string = string;
}


- (NSString *)msc
{
	return dbMsc.string;
}

- (void)setMsc:(NSString *)string
{
	dbMsc.string = string;
}

- (NSString *)smsc1
{
	return dbSmsc1.string;
}

- (void)setSmsc1:(NSString *)string
{
	dbSmsc1.string = string;
}

- (NSString *)smsc2
{
	return dbSmsc2.string;
}

- (void)setSmsc2:(NSString *)string
{
	dbSmsc2.string = string;
}

- (NSString *)smsc3
{
	return dbSmsc3.string;
}

- (void)setSmsc3:(NSString *)string
{
	dbSmsc3.string = string;
}

- (NSString *)opc1
{
	return dbOpc1.string;
}

- (void)setOpc1:(NSString *)string
{
	dbOpc1.string = string;
}

- (NSString *)dpc1
{
	return dbDpc1.string;
}

- (void)setDpc1:(NSString *)string
{
	dbDpc1.string = string;
}

- (NSString *)opc2
{
	return dbOpc2.string;
}

- (void)setOpc2:(NSString *)string
{
	dbOpc2.string = string;
}

- (NSString *)dpc2
{
	return dbDpc2.string;
}

- (void)setDpc2:(NSString *)string
{
	dbDpc2.string = string;
}

- (NSString *)userflags
{
	return dbUserflags.string;
}

- (void)setUserflags:(NSString *)string
{
	dbUserflags.string = string;
}


- (NSString *)hlr
{
	return dbHlr.string;
}

- (void)setHlr:(NSString *)string
{
	dbHlr.string = string;
}


- (NSString *)imsi
{
	return dbImsi.string;
}

- (void)setImsi:(NSString *)string
{
	dbImsi.string = string;
}


- (NSString *)mnc
{
	return dbMnc.string;
}

- (void)setMnc:(NSString *)string
{
	dbMnc.string = string;
}


- (NSString *)mcc
{
	return dbMcc.string;
}

- (void)setMcc:(NSString *)string
{
	dbMcc.string = string;
}

- (NSString *)responseUrl
{
	return dbResponseUrl.string;
}

- (void)setResponseUrl:(NSString *)string
{
	dbResponseUrl.string = string;
}


- (NSString *)submitString
{
	return dbSubmitString.string;
}

- (void)setSubmitString:(NSString *)string
{
	dbSubmitString.string = string;
}


- (UMReportMaskValue)reportMask
{
	return (ReportMaskValue)dbReportMask.integer;
}

- (void)setReportMask:(UMReportMaskValue)integer
{
	dbReportMask.integer = integer;
}


- (NSInteger)pduDcs
{
	return dbPduDcs.integer;
}

- (void)setPduDcs:(NSInteger)integer
{
	dbPduDcs.integer = integer;
}


- (NSInteger)pduCoding
{
	return dbPduCoding.integer;
}

- (void)setPduCoding:(NSInteger)integer
{
	dbPduCoding.integer = integer;
}

- (NSInteger)pduPid
{
	return dbPduPid.integer;
}

- (void)setPduPid:(NSInteger)integer
{
	dbPduPid.integer = integer;
}


- (NSInteger)pduUdhi
{
	return dbPduUdhi.integer;
}

- (void)setPduUdhi:(NSInteger)integer
{
	dbPduUdhi.integer = integer;
}


- (NSInteger)pduRp
{
	return dbPduRp.integer;
}

- (void)setPduRp:(NSInteger)integer
{
	dbPduRp.integer = integer;
}


- (NSInteger)submitErrCode
{
	return dbSubmitErrCode.integer;
}

- (void)setSubmitErrCode:(NSInteger)integer
{
	dbSubmitErrCode.integer = integer;
}


- (int)networkErrorCode
{
	return (int)dbNetworkErrorCode.integer;
}

- (void)setNetworkErrorCode:(int)integer
{
	dbNetworkErrorCode.integer = integer;
}


- (int)priority
{
	return (int)dbPriority.integer;
}

- (void)setPriority:(int)integer
{
	dbPriority.integer = integer;
}


- (int)replaceIfPresentFlag
{
	return (int)dbReplaceIfPresentFlag.integer;
}

- (void)setReplaceIfPresentFlag:(int)integer
{
	dbReplaceIfPresentFlag.integer = integer;
}

- (NSData *)pduUdh
{
	return dbPduUdh.data;
}

- (void)setPduUdh:(NSData *)d
{
	dbPduUdh.data = d;
}

- (NSData *)pduContent
{
	return dbPduContent.data;
}

- (void)setPduContent:(NSData *)d
{
	dbPduContent.data = d;
}

- (NSDate *)submitDate
{
	return dbSubmitDate.date;
}

- (void)setSubmitDate:(NSDate *)d
{
	dbSubmitDate.date = d;
}



- (NSDate *)submitAckTime
{
	return dbSubmitAckTime.date;
}

- (void)setSubmitAckTime:(NSDate *)d
{
	dbSubmitAckTime.date = d;
}



- (NSDate *)submitErrTime
{
	return dbSubmitErrTime.date;
}

- (void)setSubmitErrTime:(NSDate *)d
{
	dbSubmitErrTime.date = d;
}

- (NSDate *)attemptedDate
{
	return dbAttemptedDate.date;
}

- (void)setAttemptedDate:(NSDate *)d
{
	dbAttemptedDate.date = d;
}

- (NSDate *)validity
{
	return dbValidity.date;
}

- (void)setValidity:(NSDate *)d
{
	dbValidity.date = d;
}

- (NSDate *)deferred
{
	return dbDeferred.date;
}

- (void)setDeferred:(NSDate *)d
{
	dbDeferred.date = d;
}

- (NSString *)instance
{
    
}

- (void)setInstance:(NSString *)inst
{
    
}

@end
