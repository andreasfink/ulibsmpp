//
//  TestSMPPAdditions.m
//  ulibsmpp
//
//  Created by Aarno Syvänen on 31.08.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "TestSMPPAdditions.h"
#import "TestUtils.h"

#import "ulib/ulib.h"
/*#import "UMLogHandler.h"
#import "UMLogFeed.h"
#import "UMConfig.h"
#import "UMReadWriteLock.h" 
 */
#import "SmscConnectionMessageProtocol.h"

#include <iconv.h>


@implementation TestElement

@synthesize item;
@synthesize seq;

@end

@interface TestPrioQueue (PRIVATE)

- (void)lock;
- (void)unlock;
- (int)compare:(TestElement *)a with:(TestElement *)b;
- (void) upheapFromIndex:(long)index;
- (void) downheapFromIndex:(long)index;

@end

@implementation TestPrioQueue (PRIVATE)

- (void)lock
{
    [mutex lock];
}


- (void)unlock
{
    [mutex unlock];
}

- (int)compare:(TestElement *)a with:(TestElement *)b
{
    int rc;
    
    rc = cmp([a item], [b item]);
    if (rc == 0)
    {
        /* check sequence to guarantee order */
        if ([a seq] < [b seq])
            rc = 1;
        else if ([a seq] > [b seq])
            rc = -1;
    }
    
    return rc;
}

/**
 * Heapize up
 + @index - start index
 */
- (void) upheapFromIndex:(long)index
{
    TestElement *v = [tab objectAtIndex:index];
    id u = [[tab objectAtIndex:index/2] item];
    TestElement *w = [tab objectAtIndex:index/2];
    
    while (u && [self compare:w with:v] < 0)
    {
        [tab replaceObjectAtIndex:index withObject:[tab objectAtIndex:index/2]];
        index /= 2;
    }
    tab[index] = v;
}

/**
 * Heapize down
 * @index - start index
 */
- (void) downheapFromIndex:(long)index
{
    TestElement *v = tab[index];
    register long j;
    
    while (index <= len / 2)
    {
        j = 2 * index;
        /* take the biggest child item */
        if (j < len && [self compare:[tab objectAtIndex:j] with:[tab objectAtIndex:j + 1]] < 0)
            j++;
        /* break if our item bigger */
        if ([self compare:v with:[tab objectAtIndex:j]] >= 0)
            break;
        [tab replaceObjectAtIndex:index withObject:[tab objectAtIndex:j]];
        index = j;
    }
    tab[index] = v;
}

@end

@implementation TestPrioQueue

- (TestPrioQueue *)initWithComparator:(int(*)(id, id))iCmp
{
    TestElement *telement;
    
    if ((self = [super init]))
    {
        if (!iCmp)
        {
            return nil;
        }
        
        producers = 0;
        nonempty = [[NSCondition alloc] init];
        mutex = [[NSLock alloc] init];
        tab = nil;
        size = 0;
        len = 0;
        seq = 0;
        cmp = cmp;
        
        /* put NULL item at pos 0 that is our stop marker */
        tab = [[NSMutableArray alloc] init];
        telement = [[TestElement alloc] init];
        [telement setItem:nil];
        [telement setSeq:seq++];
        [tab insertObject:telement atIndex:0];
        len++;
    }
    return self;
}                                   
                                   
- (long)length
{
    long oLen;
        
    [self lock];
    oLen = len - 1;
    [self unlock];
        
    return oLen;
}
                                   
- (void) insert:(id)iItem
{
    TestElement *telement;
    
    if (!iItem)
        return;
    
    telement = [[TestElement alloc] init];
    [telement setItem:iItem];
    [telement setSeq:seq++];
        
    [self lock];
    [tab insertObject:telement atIndex:len];
    [self upheapFromIndex:len];
    len++;
    [nonempty signal];
    [self unlock];
}
    
-(void)produce:(id)iItem
{
    [self insert:iItem];
}
                                   
- (void) foreachCall:(void(*)(id, long))fn
{
    long i;
    TestElement *telement;
        
    if (!fn)
        return;
        
    [self lock];
    for (i = 1; i < len; i++)
    {
        telement = [tab objectAtIndex:i];
        fn([telement item], i - 1);
    }
    [self unlock];
}
                                   
- (id) remove
{
    id ret;
    TestElement *telement;
        
    [self lock];
    if (len <= 1)
    {
        [self unlock];
        return nil;
    }
    
    ret = [[tab objectAtIndex:1] item];
    telement = [tab objectAtIndex:--len];
    [tab removeObjectAtIndex:1];
    [tab insertObject:telement atIndex:1];
    [self downheapFromIndex:1];
    [self unlock];
        
    return ret;
}
      
- (id) get
{
    id ret;
        
    [self unlock];
    if (len > 1)
        ret = [[tab objectAtIndex:1] item];
    else
        ret = nil;
    [self unlock];
        
    return ret;
}
                                   
- (id) consume
{
    id ret;
    TestElement *telement;
        
    [self unlock];
    while (len == 1 && producers > 0)
    {
        [nonempty wait];
    }
    
    if (len > 1)
    {
        ret = [[tab objectAtIndex:1] item];
        [tab removeObjectAtIndex:1];
        telement = [tab objectAtIndex:--len];
        [tab insertObject:telement atIndex:1];
        [self downheapFromIndex:1];
    }
    else
        ret = nil;
    [self unlock];
        
    return ret;
}
  
- (void) addProducer
{
    [self lock];
    producers++;
    [self unlock];
}                                   
                                   
- (void) removeProducer
{
    [self unlock];
    if (producers == 0)
    {
        [self unlock];
        return;
    }
    
    producers--;
    [nonempty broadcast];
    [self unlock];
}
                                   
- (long) producerCount
{
    long ret;
        
    [self lock];
    ret = producers;
    [self unlock];
        
    return ret;
}

                                   
@end

@implementation TestCounter

/* create a new counter object.*/
- (TestCounter *)init
{
    if((self=[super init]))
    {
        lock = [[NSLock alloc] init];
        n = 0;
    }
    return self;
}


/* return the current value of the counter and increase counter by one */
- (unsigned long)increase
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    ++n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and increase counter by value */
- (unsigned long)increaseWith:(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    n += value;
    [lock unlock];
    return ret;
}

/* return the current value of the counter */
-(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and decrease counter by one */
- (unsigned long)decrease
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    if (n > 0)
        --n;
    [lock unlock];
    return ret;
}

/* return the current value of the counter and set it to the supplied value */
- (unsigned long)setTo:(unsigned long)value
{
    unsigned long ret;
    
    [lock lock];
    ret = n;
    n = value;
    [lock unlock];
    return ret;
}

@end

@implementation TestMutableArray

- (TestMutableArray *)init
{
    if((self=[super init]))
    {
        array = [[NSMutableArray alloc] init];
        singleOperationLock = [[NSLock alloc] init];
        permanentLock = [[NSLock alloc] init];
        nonempty = [[NSCondition alloc] init];
        numProducers = 0;
        numConsumers = 0;
    }
    return self;
}

- (NSString *)description
{
    NSMutableString *desc;
    long len, i;
    id item;
    
    desc = [[NSMutableString alloc] initWithString:@"Test mutable array dump starts\r\n"];
    [desc appendFormat:@"number of producers is %ld\r\n", numProducers];
    [desc appendFormat:@"number of consumers is %ld\r\n", numConsumers];
    [desc appendString:@"array was %@\r\n", array];
    return desc;
}


- (void) addProducer
{
    [nonempty lock];
    ++numProducers;
    [nonempty unlock];
}

- (void) removeProducer
{
    [nonempty lock];
    --numProducers;
    [nonempty broadcast];
    [nonempty unlock];
}

- (id)consume
{
    id item;
    long len;
    
    [nonempty lock];
    ++numConsumers;
    while ((len = [array count]) == 0 && numProducers > 0)
        [nonempty wait];
    
    if (len > 0)
    {
        item = [array objectAtIndex:0];
        [array removeObjectAtIndex:0];
    }
    else
        item = nil;
    
    --numConsumers;
    [nonempty unlock];
    return item;
}

- (id)consumeUnlocked
{
    id item;
    long len;
    
    len = [array count];
    
    if (len > 0)
    {
        item = [array objectAtIndex:0];
        [array removeObjectAtIndex:0];
    }
    else
        item = nil;
    
    return item;
}

- (void)addObject:(id)item
{
    if (!item)
        return;
    
    [nonempty lock];
    [array addObject:item];
    [nonempty signal];
    [nonempty unlock];
}

- (void)addObjectUnlocked:(id)item
{
    if (!item)
        return;
    
    [array addObject:item];
}

- (NSUInteger)count
{
    return [array count];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return [array objectAtIndex:index];
}

-(void)insertObject:(id)anObject atIndex:(NSUInteger)index
{
    if (!anObject)
        return;
    
    [array insertObject:anObject atIndex:index];
}

- (void)lock
{
    [singleOperationLock lock];
}

- (void)unlock
{
    [singleOperationLock unlock];
    
}

- (int) producerCount
{
    int ret;
    [nonempty lock];
    ret = (int)numProducers;
    [nonempty unlock];
    return ret;
}

@end
                                   
@implementation TestLoadEntry
                                   
@synthesize prev;
@synthesize curr;
@synthesize interval;
@synthesize dirty;
@synthesize last;
                                   
@end

@implementation TestLoad
                                   
- (TestLoad *) initWithHeuristics:(BOOL)iHeuristic
{
    if ((self = [super init]))
    {
        len = 0;
        entries = [[NSMutableArray alloc] init];
        heuristic = iHeuristic;
        lock = [[UMReadWriteLock  alloc] init];
    }
    return self;
}
                                   
- (int) addInterval:(int)iInterval
{
    int i;
    TestLoadEntry *entry;
    int ourInterval;
        
    [lock writeLock];
        
    /* first look if we have equal interval added already */
    for (i = 0; i < len; i++)
    {
        ourInterval = [[entries objectAtIndex:i] interval];
        if (ourInterval == iInterval)
        {
            [lock unlock];
            return -1;
        }
    }
    
    /* so no equal interval there, add new one */
    entry = [[TestLoadEntry alloc] init];
    [entry setPrev:0.0];
    [entry setCurr:0.0];
    [entry setInterval:iInterval];
    [entry setDirty:1];
    [entry setLast:time(NULL)];
        
    [entries addObject:entry];
    len++;
        
    [lock unlock];
        
    return 0;
}
                                   
- (void)dealloc
{
 //   [entries release];
 //   [lock release];
    [super dealloc];
}
                                   
- (void) increaseWith:(unsigned long)value
{
    time_t now;
    int i;
    float curr;
    int interval;
    float prev;
        
    [lock writeLock];
    time(&now);
    for (i = 0; i < len; i++)
    {
        TestLoadEntry *entry = [entries objectAtIndex:i];
        
        /* check for special case, load over whole live time */
        if (interval != -1 && now >= [entry last] + [entry interval])
        {
            /* rotate */
            curr = [entry curr];
            interval = [entry interval];
            [entry setCurr:curr /= interval];
            
            if ((prev = [entry prev]) > 0)
                [entry setPrev:(2 * curr + prev)/3];
            else
                [entry setPrev:curr];
                 
            [entry setLast:now];
            [entry setCurr:0.0];
            [entry setDirty:0];
        }
        [entry setCurr:curr += value];
    }
    [lock unlock];
}

- (float) getValueAt:(int)pos
{
    float ret;
    time_t now;
    TestLoadEntry *entry;
                
    if (pos >= len) 
        return -1.0;
                
    /* first maybe rotate load */
    [self increaseWith:0];
                
    time(&now);
    [lock readLock];
    entry = [entries objectAtIndex:pos];
    
    if (heuristic && ![entry dirty])
        ret = [entry prev];
    else
    {
        time_t diff = (now - [entry last]);
        if (diff == 0) diff = 1;
            ret = [entry curr] / diff;
    }
    [lock unlock];
                
    return ret;
}

- (int) len
{
    int ret;
        
    [lock readLock];
    ret = len;
    [lock unlock];
    return ret;
}
     
@end
     
#define MSG_PARAM_UNDEFINED -1

@interface Msg (PRIVATE)

+ (void) appendToData:(NSMutableData *)data anInteger:(long)i;
+ (void) appendToData:(NSMutableData *)data aString:(NSString *)field;
+ (void) appendToData:(NSMutableData *)data anUUID:(uuid_t)uuid;
+ (void) appendToData:(NSMutableData *)data aData:(NSData *)field;

+ (int) parseToInteger:(long *)i fromData:(NSData *)packed withNewPos:(int *)off;
+ (int) parseToString:(NSString **)os fromData:(NSData *)packed withNewPos:(int *)off;
+ (int) parseToUUID:(uuid_t)uuid fromData:(NSData *)packed withNewPos:(int *)off;
+ (int) parseToData:(NSData **)field fromData:(NSData *)packed withNewPos:(int *)off;

- (char *)typeAsString;

@end
     

@implementation Msg (PRIVATE)
     
+ (void) appendToData:(NSMutableData *)data anInteger:(long)i
{
    unsigned char buf[4];
    
    [TestUtils encodeToNetworkLong:buf withValue:i];
    [data appendBytes:buf length:4];
}

+ (void) appendToData:(NSMutableData *)data aString:(NSString *)field
{
    if (!field)
        [Msg appendToData:data anInteger:-1];
    else
    {
        [Msg appendToData:data anInteger:[field length]];
        [data appendData:[field dataUsingEncoding:NSUTF8StringEncoding]];
    }

}

+ (void) appendToData:(NSMutableData *)data anUUID:(uuid_t)uuid
{
    char buf[UUID_STR_LEN + 1];
    
    uuid_unparse(uuid, buf);
    [Msg appendToData:data anInteger:UUID_STR_LEN];
    [data appendBytes:buf length:UUID_STR_LEN];
}

+ (void) appendToData:(NSMutableData *)data aData:(NSData *)field
{
    if (!field)
        [Msg appendToData:data anInteger:-1];
    else
    {
        [Msg appendToData:data anInteger:[field length]];
        [data appendData:field];
    }
}

+ (int) parseToInteger:(long *)i fromData:(NSData *)packed withNewPos:(int *)off
{
    unsigned char buf[4];
    
    if (*off < 0)
        return -1;
    
    if (*off + 4 > [packed length])
        return -1;
    
    [packed getBytes:buf range:NSMakeRange(*off, 4)];
    *i = [TestUtils decodeNetworkLong:buf];
    *off += 4;
    return 0;
}

+ (int) parseToString:(NSString **)os fromData:(NSData *)packed withNewPos:(int *)off
{
    long len;
    
    if ([Msg parseToInteger:&len fromData:packed withNewPos:off] == -1)
        return -1;
    
    if (len == -1)
    {
        *os = NULL;
        return 0;
    }
    
    /* XXX check that len is ok */
    
    *os = [[NSString alloc] initWithData:[packed subdataWithRange:NSMakeRange(*off, len)] encoding:NSUTF8StringEncoding];
    if (!*os)
        return -1;
    *off += len;
    
    return 0;
}

+ (int) parseToUUID:(uuid_t)uuid fromData:(NSData *)packed withNewPos:(int *)off
{
    NSString *tmp;
    
    if ([Msg parseToString:&tmp fromData:packed withNewPos:off] == -1)
        return -1;
    
    if (uuid_parse([tmp UTF8String], uuid) == -1)
        return -1;
    
    return 0;
}

+ (int) parseToData:(NSData **)field fromData:(NSData *)packed withNewPos:(int *)off
{
    long len;
    
    if ([Msg parseToInteger:&len fromData:packed withNewPos:off] == -1)
        return -1;
    
    if (len == -1)
    {
        *field = nil;
        return 0;
    }
    
    /* XXX check that len is ok */
    
    *field = [packed subdataWithRange:NSMakeRange(*off, len)];
    if (!*field)
        return -1;
    *off += len;
    
    return 0;
}


- (char *)typeAsString
{
    switch (type)
    {
        case heartbeat:
            return "heartbeat";
        case admin:
            return "admin";
        case sms:
            return "sms";
        case ack:
            return "ack";
    }
    
    return "unknown type";
}

@end
     
@implementation Msg
     
@synthesize type;
@synthesize load;
     
@synthesize command;
     
@synthesize sender;
@synthesize receiver;
@synthesize udhdata;
@synthesize msgdata;
@synthesize time;
@synthesize smsc_id;
@synthesize smsc_number;
@synthesize foreign_id;
@synthesize service;
@synthesize account;
@synthesize sms_type;
@synthesize mclass;
@synthesize mwi;
@synthesize coding;
@synthesize compress;
@synthesize validity;
@synthesize deferred;
@synthesize dlr_mask;
@synthesize dlr_url;
@synthesize pid;
@synthesize alt_dcs;
@synthesize rpi;
@synthesize charset;
@synthesize boxc_id;
@synthesize binfo;
@synthesize msg_left;
@synthesize split_parts;
@synthesize priority;
@synthesize resend_retry;
@synthesize resend_time;
@synthesize meta_data;
     
@synthesize nack;

- (void)setUUID:(uuid_t)iUUID
{
    uuid_copy(uuid, iUUID);
}

- (Msg *)initWithType:(enum msg_type) iType
{
    if ((self = [super init]))
    {
        type = iType;
        load =  MSG_PARAM_UNDEFINED;
            
        command = MSG_PARAM_UNDEFINED;
        
        time = MSG_PARAM_UNDEFINED;
        uuid_generate_random(uuid);
        sms_type = MSG_PARAM_UNDEFINED;
        mclass = MSG_PARAM_UNDEFINED;
        mwi = MSG_PARAM_UNDEFINED;
        coding = MSG_PARAM_UNDEFINED;
        compress = MSG_PARAM_UNDEFINED;
        validity = MSG_PARAM_UNDEFINED;
        deferred = MSG_PARAM_UNDEFINED;
        dlr_mask = MSG_PARAM_UNDEFINED;
        pid = MSG_PARAM_UNDEFINED;
        alt_dcs = MSG_PARAM_UNDEFINED;
        rpi = MSG_PARAM_UNDEFINED;
        msg_left = MSG_PARAM_UNDEFINED;
        priority = MSG_PARAM_UNDEFINED;
        resend_retry = MSG_PARAM_UNDEFINED;
        resend_time = MSG_PARAM_UNDEFINED;
        
        nack = MSG_PARAM_UNDEFINED;
    }
    return self;
}

- (Msg *)copy
{
    Msg *new;
        
    new = [[Msg alloc] initWithType:type];
    if (!new)
        return nil;
    
    [new setType:[self type]];
    
    [new setCommand:command];
    [new setBoxc_id:boxc_id];
    
    [new setSender:sender];
    [new setReceiver:receiver];
    [new setUdhdata:udhdata];
    [new setMsgdata:msgdata];
    [new setTime:time];
    [new setSmsc_id:smsc_id];
    [new setSmsc_number:smsc_number];
    [new setForeign_id:foreign_id];
    [new setService:service];
    [new setAccount:account];
    uuid_copy(new->uuid, uuid);
    [new setSms_type:sms_type];
    [new setMclass:mclass];
    [new setMwi:mwi];
    [new setCoding:coding];
    [new setCompress:compress];
    [new setValidity:validity];
    [new setDeferred:deferred];
    [new setDlr_mask:dlr_mask];
    [new setDlr_url:dlr_url];
    [new setPid:pid];
    [new setAlt_dcs:alt_dcs];
    [new setRpi:rpi];
    [new setCharset:charset];
    [new setBinfo:binfo];
    [new setMsg_left:msg_left];
    [new setSplit_parts:split_parts];
    [new setPriority:priority];
    [new setResend_retry:resend_retry];
    [new setResend_time:resend_time];
    [new setMeta_data:meta_data];
    
    [new setNack:nack];
        
    return new;
}


- (NSString *) description
{
    NSMutableString *desc = [NSMutableString stringWithString:@"Msg dump starts\r\n"];
    
    [desc appendFormat:@"msg type was %d\r\n", type];
    
    [desc appendFormat:@"msg load was %ld\r\n", load];
    
    [desc appendFormat:@"msg admin command was %ld\r\n", command];
    [desc appendFormat:@"msg admin command box id was %@̌\r\n", boxc_id];
    
    [desc appendFormat:@"msg sender was %@\r\n", sender];
    [desc appendFormat:@"msg receiver was %@\r\n", receiver];
    [desc appendFormat:@"msg udhdata was %@\r\n", udhdata];
    [desc appendFormat:@"msg msgdata was %@\r\n", msgdata];
    [desc appendFormat:@"msg timestamp was %ld\r\n", time];
    [desc appendFormat:@"msg smsc id was %@\r\n", smsc_id];
    [desc appendFormat:@"msg smsc number was %@\r\n", smsc_number];
    [desc appendFormat:@"msg foreign id was %@\r\n", foreign_id];
    [desc appendFormat:@"msg service was %@\r\n", service];
    [desc appendFormat:@"msg account was %@\r\n", account];
    [desc appendFormat:@"msg UUID was %s\r\n", uuid];
    [desc appendFormat:@"msg sms type was %ld\r\n", sms_type];
    [desc appendFormat:@"msg class was %ld\r\n", mclass];
    [desc appendFormat:@"msg message waiting indicator was %ld\r\n", mwi];
    [desc appendFormat:@"msg coding was %ldr\n", coding];
    [desc appendFormat:@"msg compress indicator was %ld\r\n", compress];
    [desc appendFormat:@"msg validity period was %ld\r\n", validity];
    [desc appendFormat:@"msg deferred flag was %ld\r\n", deferred];
    [desc appendFormat:@"msg DLR mask was %ld\r\n", dlr_mask];
    [desc appendFormat:@"msg DLR URL was %@\r\n", dlr_url];
    [desc appendFormat:@"msg process id was %ld\r\n", pid];
    [desc appendFormat:@"msg alternate data coding scheme was was %ld\r\n", alt_dcs];
    [desc appendFormat:@"msg return path indicator was %ld\r\n", rpi];
    [desc appendFormat:@"msg charset was %@\r\n", charset];
    [desc appendFormat:@"msg binfo was %@\r\n", binfo];
    [desc appendFormat:@"%ld messages left\r\n", msg_left];
    [desc appendFormat:@"msg split parts were %@\r\n", split_parts];
    [desc appendFormat:@"msg priority was %ld\r\n", priority];
    [desc appendFormat:@"%ld resend attemps\r\n", resend_retry];
    [desc appendFormat:@"msg will be resend at %ld\r\n", resend_time];
    [desc appendFormat:@"customised data was %@\r\n", meta_data];
    
    [desc appendFormat:@"msg nack nack was %ld\r\n", nack];
     
     [desc appendString:@"Msg dump ends"];
    
     return desc;
}

- (NSData *)pack
{
    NSMutableData *data;
    
    if (strcmp([self typeAsString], "unknown type") == 0)
        return nil;
    
    data = [[NSMutableData alloc] init];
    [Msg appendToData:data anInteger:type];
    
    [Msg appendToData:data anInteger:load];
    
    [Msg appendToData:data anInteger:command];
    [Msg appendToData:data aString:boxc_id];
    
    [Msg appendToData:data aString:sender];
    [Msg appendToData:data aString:receiver];
    [Msg appendToData:data aData:udhdata];
    [Msg appendToData:data aData:msgdata];
    [Msg appendToData:data anInteger:time];
    [Msg appendToData:data aString:smsc_id];
    [Msg appendToData:data aString:smsc_number];
    [Msg appendToData:data aString:foreign_id];
    [Msg appendToData:data aString:service];
    [Msg appendToData:data aString:account];
    [Msg appendToData:data anUUID:uuid];
    [Msg appendToData:data anInteger:sms_type];
    [Msg appendToData:data anInteger:mclass];
    [Msg appendToData:data anInteger:mwi];
    [Msg appendToData:data anInteger:coding];
    [Msg appendToData:data anInteger:compress];
    [Msg appendToData:data anInteger:validity];
    [Msg appendToData:data anInteger:deferred];
    [Msg appendToData:data anInteger:dlr_mask];
    [Msg appendToData:data aString:dlr_url];
    [Msg appendToData:data anInteger:pid];
    [Msg appendToData:data anInteger:alt_dcs];
    [Msg appendToData:data anInteger:rpi];
    [Msg appendToData:data aString:charset];
    [Msg appendToData:data aString:binfo];
    [Msg appendToData:data anInteger:msg_left];
    [Msg appendToData:data anInteger:priority];
    [Msg appendToData:data anInteger:resend_retry];
    [Msg appendToData:data anInteger:resend_time];
    [Msg appendToData:data aString:meta_data];
    
    return data;
    
}

- (Msg *)unpack:(NSData *)data
{
    Msg *msg;
    int off;
    long i;
    NSString *field;
    NSData *fData;
    uuid_t our_uuid;
    
    msg = [[Msg alloc] initWithType:0];
    
    off = 0;
    
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setType:(enum msg_type)i];
    
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setLoad:i];
    
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setCommand:i];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setBoxc_id:field];
    
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setSender:field];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setReceiver:field];
    if ([Msg parseToData:&fData fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setUdhdata:fData];
    if ([Msg parseToData:&fData fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setMsgdata:[fData mutableCopy]];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setTime:i];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setSmsc_id:field];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setSmsc_number:field];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setForeign_id:field];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setService:field];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setAccount:field];
    if ([Msg parseToUUID:our_uuid fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setUUID:our_uuid];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setSms_type:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setMclass:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setMwi:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setCoding:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setCompress:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setValidity:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setDeferred:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setDlr_mask:i];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setDlr_url:field];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setPid:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setAlt_dcs:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setRpi:i];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setCharset:field];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setBinfo:field];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setMsg_left:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setPriority:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setResend_retry:i];
    if ([Msg parseToInteger:&i fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setResend_time:i];
    if ([Msg parseToString:&field fromData:data withNewPos:&off] == -1)
        return nil;
    [msg setMeta_data:field];
    
    return msg;
}

int sms_priority_compare(id a, id b)
{
    int ret;
    Msg *msg1 = (Msg*)a, *msg2 = (Msg*)b;
    if ([msg1 type] != sms)
        return -2;
    if ([msg2 type] != sms)
        return -2;
    
    if ([msg1 priority] > [msg2 priority])
        ret = 1;
    else if ([msg1 priority] < [msg2 priority])
        ret = -1;
    else
    {
        if ([msg1 time] > [msg2 time])
            ret = 1;
        else if ([msg1 time] < [msg2 time])
            ret = -1;
        else
            ret = 0;
    }
    
    return ret;
}

- (int) dcsToFieldsWithDcs:(int)dcs
{
    /* Non-MWI Mode 1 */
    if ((dcs & 0xF0) == 0xF0)
    {
        dcs &= 0x07;
        coding = (dcs & 0x04) ? DC_8BIT : DC_7BIT; /* grab bit 2 */
        mclass = dcs & 0x03; /* grab bits 1,0 */
        alt_dcs = 1; /* set 0xFX data coding */
    }
    
    /* Non-MWI Mode 0 */
    else if ((dcs & 0xC0) == 0x00)
    {
        alt_dcs = 0;
        compress = ((dcs & 0x20) == 0x20) ? 1 : 0; /* grab bit 5 */
        mclass = ((dcs & 0x10) == 0x10) ? dcs & 0x03 : MC_UNDEF;
        /* grab bit 0,1 if bit 4 is on */
        coding = (dcs & 0x0C) >> 2; /* grab bit 3,2 */
    }
    
    /* MWI */
    else if ((dcs & 0xC0) == 0xC0)
    {
        alt_dcs = 0;
        coding = ((dcs & 0x30) == 0x30) ? DC_UCS2 : DC_7BIT;
        if (!(dcs & 0x08))
            dcs |= 0x04; /* if bit 3 is active, have mwi += 4 */
        dcs &= 0x07;
        mwi = dcs ; /* grab bits 1,0 */
    }
    
    else 
        return 0;
    
    return 1;
}
     
@end

/* Code used for non-representable characters */
#define NRP 63

/* This is the extension table defined in GSM 03.38.  It is the mapping
 * used for the character after a GSM 27 (Escape) character.  All characters
 * not in the table, as well as characters we can't represent, will map
 * to themselves.  We cannot represent the euro symbol, which is an escaped
 * 'e', so we left it out of this table. */
static const struct {
    int gsmesc;
    int latin1;
} gsm_esctolatin1[] = {
    {  10, 12 }, /* ASCII page break */
    {  20, '^' },
    {  40, '{' },
    {  41, '}' },
    {  47, '\\' },
    {  60, '[' },
    {  61, '~' },
    {  62, ']' },
    {  64, '|' },
    { 101, 128 },
    { -1, -1 }
};

/**
 * Struct maps escaped GSM chars to unicode codeposition.
 */
static const struct {
    int gsmesc;
    int unichar;
} gsm_esctouni[] = {
    { 10, 12 }, /* ASCII page break */
    { 20, '^' },
    { 40, '{' },
    { 41, '}' },
    { 47, '\\' },
    { 60, '[' },
    { 61, '~' },
    { 62, ']' },
    { 64, '|' },
    { 'e', 0x20AC },  /* euro symbol */
    { -1, -1 }
};

/* Map GSM default alphabet characters to ISO-Latin-1 characters.
 * The greek characters at positions 16 and 18 through 26 are not
 * mappable.  They are mapped to '?' characters.
 * The escape character, at position 27, is mapped to a space,
 * though normally the function that indexes into this table will
 * treat it specially. */
static const unsigned char gsm_to_latin1[128] = {
    '@', 0xa3,  '$', 0xa5, 0xe8, 0xe9, 0xf9, 0xec,   /* 0 - 7 */
    0xf2, 0xc7,   10, 0xd8, 0xf8,   13, 0xc5, 0xe5,   /* 8 - 15 */
    '?',  '_',  '?',  '?',  '?',  '?',  '?',  '?',   /* 16 - 23 */
    '?',  '?',  '?',  ' ', 0xc6, 0xe6, 0xdf, 0xc9,   /* 24 - 31 */
    ' ',  '!',  '"',  '#', 0xa4,  '%',  '&', '\'',   /* 32 - 39 */
    '(',  ')',  '*',  '+',  ',',  '-',  '.',  '/',   /* 40 - 47 */
    '0',  '1',  '2',  '3',  '4',  '5',  '6',  '7',   /* 48 - 55 */
    '8',  '9',  ':',  ';',  '<',  '=',  '>',  '?',   /* 56 - 63 */
    0xa1,  'A',  'B',  'C',  'D',  'E',  'F',  'G',   /* 64 - 71 */
    'H',  'I',  'J',  'K',  'L',  'M',  'N',  'O',   /* 73 - 79 */
    'P',  'Q',  'R',  'S',  'T',  'U',  'V',  'W',   /* 80 - 87 */
    'X',  'Y',  'Z', 0xc4, 0xd6, 0xd1, 0xdc, 0xa7,   /* 88 - 95 */
    0xbf,  'a',  'b',  'c',  'd',  'e',  'f',  'g',   /* 96 - 103 */
    'h',  'i',  'j',  'k',  'l',  'm',  'n',  'o',   /* 104 - 111 */
    'p',  'q',  'r',  's',  't',  'u',  'v',  'w',   /* 112 - 119 */
    'x',  'y',  'z', 0xe4, 0xf6, 0xf1, 0xfc, 0xe0    /* 120 - 127 */
};

/**
 * Map GSM default alphabet characters to unicode codeposition.
 * The escape character, at position 27, is mapped to a NRP,
 * though normally the function that indexes into this table will
 * treat it specially.
 */
static const int gsm_to_unicode[128] = {
    '@',  0xA3,   '$',  0xA5,  0xE8,  0xE9,  0xF9,  0xEC,   /* 0 - 7 */
    0xF2,  0xC7,    10,  0xd8,  0xF8,    13,  0xC5,  0xE5,   /* 8 - 15 */
    0x394,   '_', 0x3A6, 0x393, 0x39B, 0x3A9, 0x3A0, 0x3A8,   /* 16 - 23 */
    0x3A3, 0x398, 0x39E,   NRP,  0xC6,  0xE6,  0xDF,  0xC9,   /* 24 - 31 */
    ' ',   '!',   '"',   '#',  0xA4,   '%',   '&',  '\'',   /* 32 - 39 */
    '(',   ')',   '*',   '+',   ',',   '-',   '.',   '/',   /* 40 - 47 */
    '0',   '1',   '2',   '3',   '4',   '5',   '6',   '7',   /* 48 - 55 */
    '8',   '9',   ':',   ';',   '<',   '=',   '>',   '?',   /* 56 - 63 */
    0xA1,  'A',   'B',   'C',   'D',   'E',   'F',   'G',   /* 64 - 71 */
    'H',   'I',   'J',   'K',   'L',   'M',   'N',   'O',   /* 73 - 79 */
    'P',   'Q',   'R',   'S',   'T',   'U',   'V',   'W',   /* 80 - 87 */
    'X',   'Y',   'Z',  0xC4,  0xD6,  0xD1,  0xDC,  0xA7,   /* 88 - 95 */
    0xBF,   'a',   'b',   'c',   'd',   'e',   'f',   'g',   /* 96 - 103 */
    'h',   'i',   'j',   'k',   'l',   'm',   'n',   'o',   /* 104 - 111 */
    'p',   'q',   'r',   's',   't',   'u',   'v',   'w',   /* 112 - 119 */
    'x',   'y',   'z',  0xE4,  0xF6,  0xF1,  0xFC,  0xE0    /* 120 - 127 */
};

static const int latin1_to_gsm[256] = {
    /* 0x00 */ NRP, /* pc: NON PRINTABLE */ /* 0x01 */ NRP, /* pc: NON PRINTABLE */ /* 0x02 */ NRP, /* pc: NON PRINTABLE */
    /* 0x03 */ NRP, /* pc: NON PRINTABLE */ /* 0x04 */ NRP, /* pc: NON PRINTABLE */ /* 0x05 */ NRP, /* pc: NON PRINTABLE */
    /* 0x06 */ NRP, /* pc: NON PRINTABLE */ /* 0x07 */ NRP, /* pc: NON PRINTABLE */ /* 0x08 */ NRP, /* pc: NON PRINTABLE */
    /* 0x09 */ NRP, /* pc: NON PRINTABLE */ /* 0x0a */ 0x0a, /* pc: NON PRINTABLE */ /* 0x0b */ NRP, /* pc: NON PRINTABLE */
    /* 0x0c */ -0x0a, /* pc: NON PRINTABLE */ /* 0x0d */ 0x0d, /* pc: NON PRINTABLE */ /* 0x0e */ NRP, /* pc: NON PRINTABLE */
    /* 0x0f */ NRP, /* pc: NON PRINTABLE */ /* 0x10 */ NRP, /* pc: NON PRINTABLE */ /* 0x11 */ NRP, /* pc: NON PRINTABLE */
    /* 0x12 */ NRP, /* pc: NON PRINTABLE */ /* 0x13 */ NRP, /* pc: NON PRINTABLE */ /* 0x14 */ NRP, /* pc: NON PRINTABLE */
    /* 0x15 */ NRP, /* pc: NON PRINTABLE */ /* 0x16 */ NRP, /* pc: NON PRINTABLE */ /* 0x17 */ NRP, /* pc: NON PRINTABLE */
    /* 0x18 */ NRP, /* pc: NON PRINTABLE */ /* 0x19 */ NRP, /* pc: NON PRINTABLE */ /* 0x1a */ NRP, /* pc: NON PRINTABLE */
    /* 0x1b */ NRP, /* pc: NON PRINTABLE */ /* 0x1c */ NRP, /* pc: NON PRINTABLE */ /* 0x1d */ NRP, /* pc: NON PRINTABLE */
    /* 0x1e */ NRP, /* pc: NON PRINTABLE */
    /* 0x1f */ NRP, /* pc: NON PRINTABLE */ /* 0x20 */ 0x20, /* pc:   */ /* 0x20 */ 0x20, /* pc:   */ /* 0x21 */ 0x21, /* pc: ! */
    /* 0x22 */ 0x22, /* pc: " */ /* 0x23 */ 0x23, /* pc: # */ /* 0x24 */ 0x02, /* pc: $ */ /* 0x25 */ 0x25, /* pc: % */
    /* 0x26 */ 0x26, /* pc: & */ /* 0x27 */ 0x27, /* pc: ' */ /* 0x28 */ 0x28, /* pc: ( */ /* 0x29 */ 0x29, /* pc: ) */
    /* 0x2a */ 0x2a, /* pc: * */ /* 0x2b */ 0x2b, /* pc: + */ /* 0x2c */ 0x2c, /* pc: , */ /* 0x2d */ 0x2d, /* pc: - */
    /* 0x2e */ 0x2e, /* pc: . */ /* 0x2f */ 0x2f, /* pc: / */ /* 0x30 */ 0x30, /* pc: 0 */ /* 0x31 */ 0x31, /* pc: 1 */
    /* 0x32 */ 0x32, /* pc: 2 */ /* 0x32 */ 0x32, /* pc: 2 */ /* 0x33 */ 0x33, /* pc: 3 */ /* 0x34 */ 0x34, /* pc: 4 */
    /* 0x35 */ 0x35, /* pc: 5 */ /* 0x36 */ 0x36, /* pc: 6 */ /* 0x37 */ 0x37, /* pc: 7 */ /* 0x38 */ 0x38, /* pc: 8 */
    /* 0x39 */ 0x39, /* pc: 9 */ /* 0x3a */ 0x3a, /* pc: : */ /* 0x3b */ 0x3b, /* pc: ; */ /* 0x3c */ 0x3c, /* pc: < */
    /* 0x3d */ 0x3d, /* pc: = */ /* 0x3e */ 0x3e, /* pc: > */ /* 0x3f */ 0x3f, /* pc: ? */ /* 0x40 */ 0x00, /* pc: @ */
    /* 0x41 */ 0x41, /* pc: A */ /* 0x42 */ 0x42, /* pc: B */ /* 0x43 */ 0x43, /* pc: C */ /* 0x44 */ 0x44, /* pc: D */
    /* 0x45 */ 0x45, /* pc: E */ /* 0x46 */ 0x46, /* pc: F */ /* 0x47 */ 0x47, /* pc: G */ /* 0x48 */ 0x48, /* pc: H */
    /* 0x49 */ 0x49, /* pc: I */ /* 0x4a */ 0x4a, /* pc: J */ /* 0x4b */ 0x4b, /* pc: K *//* 0x4c */ 0x4c, /* pc: L */
    /* 0x4d */ 0x4d, /* pc: M */ /* 0x4e */ 0x4e, /* pc: N */ /* 0x4f */ 0x4f, /* pc: O */ /* 0x50 */ 0x50, /* pc: P */
    /* 0x51 */ 0x51, /* pc: Q */ /* 0x52 */ 0x52, /* pc: R */ /* 0x53 */ 0x53, /* pc: S */ /* 0x54 */ 0x54, /* pc: T */
    /* 0x55 */ 0x55, /* pc: U */ /* 0x56 */ 0x56, /* pc: V */ /* 0x57 */ 0x57, /* pc: W */ /* 0x58 */ 0x58, /* pc: X */
    /* 0x59 */ 0x59, /* pc: Y */ /* 0x5a */ 0x5a, /* pc: Z */ /* 0x5b */ -0x3c, /* pc: [ */ /* 0x5c */ -0x2f, /* pc: \ */
    /* 0x5d */ -0x3e, /* pc: ] */ /* 0x5e */ -0x14, /* pc: ^ */ /* 0x5f */ 0x11, /* pc: _ */ /* 0x60 */ NRP, /* pc: ` */
    /* 0x61 */ 0x61, /* pc: a */ /* 0x62 */ 0x62, /* pc: b *//* 0x63 */ 0x63, /* pc: c *//* 0x64 */ 0x64, /* pc: d */
    /* 0x65 */ 0x65, /* pc: e */ /* 0x66 */ 0x66, /* pc: f */ /* 0x67 */ 0x67, /* pc: g */ /* 0x68 */ 0x68, /* pc: h */
    /* 0x69 */ 0x69, /* pc: i */ /* 0x6a */ 0x6a, /* pc: j */ /* 0x6b */ 0x6b, /* pc: k *//* 0x6c */ 0x6c, /* pc: l */
    /* 0x6d */ 0x6d, /* pc: m */ /* 0x6e */ 0x6e, /* pc: n */ /* 0x6f */ 0x6f, /* pc: o */ /* 0x70 */ 0x70, /* pc: p */
    /* 0x71 */ 0x71, /* pc: q */ /* 0x72 */ 0x72, /* pc: r */ /* 0x73 */ 0x73, /* pc: s */ /* 0x74 */ 0x74, /* pc: t */
    /* 0x75 */ 0x75, /* pc: u */ /* 0x76 */ 0x76, /* pc: v */ /* 0x77 */ 0x77, /* pc: w */ /* 0x78 */ 0x78, /* pc: x */
    /* 0x79 */ 0x79, /* pc: y */ /* 0x7a */ 0x7a, /* pc: z */ /* 0x7b */ -0x28, /* pc: { */ /* 0x7c */ -0x40, /* pc: | */
    /* 0x7d */ -0x29, /* pc: } */ /* 0x7e */ -0x3d, /* pc: ~ */
    /* 0x7f */ NRP, /* pc: NON PRINTABLE */ /* 0x80 */ NRP, /* pc: NON PRINTABLE */ /* 0x81 */ NRP, /* pc: NON PRINTABLE */
    /* 0x82 */ NRP, /* pc: NON PRINTABLE */ /* 0x83 */ NRP, /* pc: NON PRINTABLE */ /* 0x84 */ NRP, /* pc: NON PRINTABLE */
    /* 0x85 */ NRP, /* pc: NON PRINTABLE */ /* 0x86 */ NRP, /* pc: NON PRINTABLE */ /* 0x87 */ NRP, /* pc: NON PRINTABLE */
    /* 0x88 */ NRP, /* pc: NON PRINTABLE */ /* 0x89 */ NRP, /* pc: NON PRINTABLE */ /* 0x8a */ NRP, /* pc: NON PRINTABLE */
    /* 0x8b */ NRP, /* pc: NON PRINTABLE */ /* 0x8c */ NRP, /* pc: NON PRINTABLE */ /* 0x8d */ NRP, /* pc: NON PRINTABLE */
    /* 0x8e */ NRP, /* pc: NON PRINTABLE */ /* 0x8f */ NRP, /* pc: NON PRINTABLE */ /* 0x90 */ NRP, /* pc: NON PRINTABLE */
    /* 0x91 */ NRP, /* pc: NON PRINTABLE */ /* 0x92 */ NRP, /* pc: NON PRINTABLE */ /* 0x93 */ NRP, /* pc: NON PRINTABLE */
    /* 0x94 */ NRP, /* pc: NON PRINTABLE */ /* 0x95 */ NRP, /* pc: NON PRINTABLE */ /* 0x96 */ NRP, /* pc: NON PRINTABLE */
    /* 0x97 */ NRP, /* pc: NON PRINTABLE */ /* 0x98 */ NRP, /* pc: NON PRINTABLE *//* 0x99 */ NRP, /* pc: NON PRINTABLE */
    /* 0x9a */ NRP, /* pc: NON PRINTABLE */ /* 0x9b */ NRP, /* pc: NON PRINTABLE */ /* 0x9c */ NRP, /* pc: NON PRINTABLE */
    /* 0x9d */ NRP, /* pc: NON PRINTABLE */ /* 0x9e */ NRP, /* pc: NON PRINTABLE */ /* 0x9f */ NRP, /* pc: NON PRINTABLE */
    /* 0xa0 */ NRP, /* pc: NON PRINTABLE */ /* 0xa1 */ 0x40, /* pc: INVERTED EXCLAMATION MARK */ /* 0xa2 */ NRP, /* pc: NON PRINTABLE */
    /* 0xa3 */ 0x01, /* pc: POUND SIGN */ /* 0xa4 */ 0x24, /* pc: CURRENCY SIGN */ /* 0xa5 */ 0x03, /* pc: YEN SIGN*/
    /* 0xa6 */ NRP, /* pc: NON PRINTABLE */ /* 0xa7 */ 0x5f, /* pc: SECTION SIGN */ /* 0xa8 */ NRP, /* pc: NON PRINTABLE */
    /* 0xa9 */ NRP, /* pc: NON PRINTABLE */ /* 0xaa */ NRP, /* pc: NON PRINTABLE */ /* 0xab */ NRP, /* pc: NON PRINTABLE */
    /* 0xac */ NRP, /* pc: NON PRINTABLE */ /* 0xad */ NRP, /* pc: NON PRINTABLE */ /* 0xae */ NRP, /* pc: NON PRINTABLE */
    /* 0xaf */ NRP, /* pc: NON PRINTABLE */ /* 0xb0 */ NRP, /* pc: NON PRINTABLE */ /* 0xb1 */ NRP, /* pc: NON PRINTABLE */
    /* 0xb2 */ NRP, /* pc: NON PRINTABLE */ /* 0xb3 */ NRP, /* pc: NON PRINTABLE */ /* 0xb4 */ NRP, /* pc: NON PRINTABLE */
    /* 0xb5 */ NRP, /* pc: NON PRINTABLE */ /* 0xb6 */ NRP, /* pc: NON PRINTABLE */ /* 0xb7 */ NRP, /* pc: NON PRINTABLE */
    /* 0xb8 */ NRP, /* pc: NON PRINTABLE */ /* 0xb9 */ NRP, /* pc: NON PRINTABLE */ /* 0xba */ NRP, /* pc: NON PRINTABLE */
    /* 0xbb */ NRP, /* pc: NON PRINTABLE */ /* 0xbc */ NRP, /* pc: NON PRINTABLE */ /* 0xbd */ NRP, /* pc: NON PRINTABLE */
    /* 0xbe */ NRP, /* pc: NON PRINTABLE */ /* 0xbf */ 0x60, /* pc: INVERTED QUESTION MARK */ /* 0xc0 */ NRP, /* pc: NON PRINTABLE */
    /* 0xc1 */ NRP, /* pc: NON PRINTABLE */ /* 0xc2 */ NRP, /* pc: NON PRINTABLE */ /* 0xc3 */ NRP, /* pc: NON PRINTABLE */
    /* 0xc4 */ 0x5b, /* pc: LATIN CAPITAL LETTER A WITH DIAERESIS */ /* 0xc5 */ 0x0e, /* pc: LATIN CAPITAL LETTER A WITH RING ABOVE */
    /* 0xc6 */ 0x1c, /* pc: LATIN CAPITAL LETTER AE */ /* 0xc7 */ 0x09, /* pc: LATIN CAPITAL LETTER C WITH CEDILLA (mapped to small) */
    /* 0xc8 */ NRP, /* pc: NON PRINTABLE */ /* 0xc9 */ 0x1f, /* pc: LATIN CAPITAL LETTER E WITH ACUTE  */
    /* 0xca */ NRP, /* pc: NON PRINTABLE */ /* 0xcb */ NRP, /* pc: NON PRINTABLE */ /* 0xcc */ NRP, /* pc: NON PRINTABLE */
    /* 0xcd */ NRP, /* pc: NON PRINTABLE */ /* 0xce */ NRP, /* pc: NON PRINTABLE */ /* 0xcf */ NRP, /* pc: NON PRINTABLE */
    /* 0xd0 */ NRP, /* pc: NON PRINTABLE */ /* 0xd1 */ 0x5d, /* pc: LATIN CAPITAL LETTER N WITH TILDE */ /* 0xd2 */ NRP, /* pc: NON PRINTABLE */
    /* 0xd3 */ NRP, /* pc: NON PRINTABLE */ /* 0xd4 */ NRP, /* pc: NON PRINTABLE */ /* 0xd5 */ NRP, /* pc: NON PRINTABLE */
    /* 0xd6 */ 0x5c, /* pc: LATIN CAPITAL LETTER O WITH DIAEREIS */ /* 0xd7 */ NRP, /* pc: NON PRINTABLE */
    /* 0xd8 */ 0x0b, /* pc: LATIN CAPITAL LETTER O WITH STROKE */ /* 0xd9 */ NRP, /* pc: NON PRINTABLE */ /* 0xda */ NRP, /* pc: NON PRINTABLE */
    /* 0xdb */ NRP, /* pc: NON PRINTABLE */ /* 0xdc */ 0x5e, /* pc: LATIN CAPITAL LETTER U WITH DIAERESIS */
    /* 0xdd */ NRP, /* pc: NON PRINTABLE */ /* 0xde */ NRP, /* pc: NON PRINTABLE */ /* 0xdf */ 0x1e, /* pc: LATIN SMALL LETTER SHARP S */
    /* 0xe0 */ 0x7f, /* pc: LATIN SMALL LETTER A WITH GRAVE */
    /* 0xe1 */ NRP, /* pc: NON PRINTABLE */ /* 0xe2 */ NRP, /* pc: NON PRINTABLE */ /* 0xe3 */ NRP, /* pc: NON PRINTABLE */
    /* 0xe4 */ 0x7b, /* pc: LATIN SMALL LETTER A WITH DIAERESIS */ /* 0xe5 */ 0x0f, /* pc: LATIN SMALL LETTER A WITH RING ABOVE */
    /* 0xe6 */ 0x1d, /* pc: LATIN SMALL LETTER AE */ /* 0xe7 */ 0x09, /* pc: LATIN SMALL LETTER C WITH CEDILLA */
    /* 0xe8 */ 0x04, /* pc: NON PRINTABLE */ /* 0xe9 */ 0x05, /* pc: NON PRINTABLE */ /* 0xea */ NRP, /* pc: NON PRINTABLE */
    /* 0xeb */ NRP, /* pc: NON PRINTABLE */ /* 0xec */ 0x07, /* pc: NON PRINTABLE */ /* 0xed */ NRP, /* pc: NON PRINTABLE */
    /* 0xee */ NRP, /* pc: NON PRINTABLE *//* 0xef */ NRP, /* pc: NON PRINTABLE */ /* 0xf0 */ NRP, /* pc: NON PRINTABLE */
    /* 0xf1 */ 0x7d, /* pc: NON PRINTABLE */ /* 0xf2 */ 0x08, /* pc: NON PRINTABLE */ /* 0xf3 */ NRP, /* pc: NON PRINTABLE */
    /* 0xf4 */ NRP, /* pc: NON PRINTABLE */ /* 0xf5 */ NRP, /* pc: NON PRINTABLE */ /* 0xf6 */ 0x7c, /* pc: NON PRINTABLE */
    /* 0xf7 */ NRP, /* pc: NON PRINTABLE */ /* 0xf8 */ 0x0c, /* pc: NON PRINTABLE */ /* 0xf9 */ 0x06, /* pc: NON PRINTABLE */
    /* 0xfa */ NRP, /* pc: NON PRINTABLE */ /* 0xfb */ NRP, /* pc: NON PRINTABLE */ /* 0xfc */ 0x7e, /* pc: NON PRINTABLE */
    /* 0xfd */ NRP, /* pc: NON PRINTABLE */ /* 0xfe */ NRP, /* pc: NON PRINTABLE *//* 0xff */ NRP, /* pc: NON PRINTABLE */
};


@implementation NSMutableString (TestCharset)

- (void)convertFromGsmToUTF8
{
    long pos, len;
    NSMutableString  *newns;
    
    
    newns = [NSMutableString string];
    len = [self length];
    
    for (pos = 0; pos < len; pos++)
    {
        int c, i;
        
        c = [self characterAtIndex:pos];
        if (c > 127) 
            continue;
        
        if (c == 27 && pos + 1 < len)
        {
            c = [self characterAtIndex:++pos];
            for (i = 0; gsm_esctouni[i].gsmesc >= 0; i++)
            {
                if (gsm_esctouni[i].gsmesc == c)
                    break;
            }
            if (gsm_esctouni[i].gsmesc == c)
            {
                /* found a value for escaped char */
                c = gsm_esctouni[i].unichar;
            }
            else
            {
                /* nothing found, look esc in our table */
                c = gsm_to_unicode[27];
                pos--;
            }
            c = gsm_to_unicode[c];
        }
        
        /* unicode to utf-8 */
        if (c < 128)
        {
            /* 0-127 are ASCII chars that need no conversion */
            [newns appendFormat:@"%c", c];
        }
        else
        {
            /* test if it can be converterd into a two byte char */
            if(c < 0x0800)
            {
                [newns appendFormat:@"%c", ((c >> 6) | 0xC0) & 0xFF]; /* add 110xxxxx */
                [newns appendFormat:@"%c", (c & 0x3F) | 0x80]; /* add 10xxxxxx */
            }
            else
            {
                /* else we encode with 3 bytes. This only happens in case of euro symbol */
                [newns appendFormat:@"%c", ((c >> 12) | 0xE0) & 0xFF]; /* add 1110xxxx */
                [newns appendFormat:@"%c", (((c >> 6) & 0x3F) | 0x80) & 0xFF]; /* add 10xxxxxx */
                [newns appendFormat:@"%c", ((c  & 0x3F) | 0x80) & 0xFF]; /* add 10xxxxxx */
            }
            /* There are no 4 bytes encoded characters in GSM charset */
        }
    }
    
    [self deleteCharactersInRange:NSMakeRange(0, [self length])];
    [self appendString:newns];
}

- (void)convertFromUTF8ToGsm
{
    long pos, len;
    int val1, val2;
    NSMutableString *newns;
    
    newns = [NSMutableString string];
    len = [self length];
    
    for (pos = 0; pos < len; pos++)
    {
        val1 = [self characterAtIndex:pos];
        
        /* check range */
        if (val1 < 0 || val1 > 255) 
            continue;
        
        /* Convert UTF-8 to unicode code */
        
        /* test if two byte utf8 char */
        if ((val1 & 0xE0) == 0xC0)
        {
            /* test if incomplete utf char */
            if (pos + 1 < len)
            {
                val2 = [self characterAtIndex:++pos];
                val1 = (((val1 & ~0xC0) << 6) | (val2 & 0x3F));
            }
            else
            {
                pos += 1;
                continue;
            }
        }
        else if ((val1 & 0xF0) == 0xE0)
        { /* test for three byte utf8 char */
            if (pos + 2 < len)
            {
                val2 = [self characterAtIndex:++pos];
                val1 = (((val1 & ~0xE0) << 6) | (val2 & 0x3F));
                val2 = [self characterAtIndex:++pos];
                val1 = (val1 << 6) | (val2 & 0x3F);
            }
            else
            {
                /* incomplete, ignore it */
                pos += 2;
                continue;
            }
        }

        /* test Latin code page 1 char */
        if (val1 <= 255)
        {
            val1 = latin1_to_gsm[val1];
            /* needs to be escaped ? */
            if(val1 < 0)
            {
                [newns appendFormat:@"%c", 27];
                val1 *= -1;
            }
        }
        else
        {
            /* Its not a Latin1 char, test for allowed GSM chars */
            switch(val1) {
                case 0x394:
                    val1 = 0x10; /* GREEK CAPITAL LETTER DELTA */
                    break;
                case 0x3A6:
                    val1 = 0x12; /* GREEK CAPITAL LETTER PHI */
                    break;
                case 0x393:
                    val1 = 0x13; /* GREEK CAPITAL LETTER GAMMA */
                    break;
                case 0x39B:
                    val1 = 0x14; /* GREEK CAPITAL LETTER LAMBDA */
                    break;
                case 0x3A9:
                    val1 = 0x15; /* GREEK CAPITAL LETTER OMEGA */
                    break;
                case 0x3A0:
                    val1 = 0x16; /* GREEK CAPITAL LETTER PI */
                    break;
                case 0x3A8:
                    val1 = 0x17; /* GREEK CAPITAL LETTER PSI */
                    break;
                case 0x3A3:
                    val1 = 0x18; /* GREEK CAPITAL LETTER SIGMA */
                    break;
                case 0x398:
                    val1 = 0x19; /* GREEK CAPITAL LETTER THETA */
                    break;
                case 0x39E:
                    val1 = 0x1A; /* GREEK CAPITAL LETTER XI */
                    break;
                case 0x20AC:
                    val1 = 'e'; /* EURO SIGN */
                    [newns appendFormat:@"%c", 27];
                    break;
                default: val1 = NRP; /* character cannot be represented in GSM 03.38 */
            }
        }
        [newns appendFormat:@"%c", val1];
    }
    
    [self deleteCharactersInRange:NSMakeRange(0, [self length])];
    [self appendString:newns];
}

/*
 * This function is a wrapper arround charset_latin1_to_gsm()
 * which implements the mapping of a NRCs (national reprentation codes)
 * ISO 21 German.
 */
- (void) convertFromGsmToNrcIso21German
{
    long pos, len;
    int c, new;
    
    len = [self length];
    
    for (pos = 0; pos < len; pos++)
    {
        c = [self characterAtIndex:pos];
        switch (c)
        {
                /* GSM value; NRC value */
            case 0x5b: new = 0x5b; break; /* ï¿½ */
            case 0x5c: new = 0x5c; break; /* ï¿½ */
            case 0x5e: new = 0x5d; break; /* ï¿½ */
            case 0x7b: new = 0x7b; break; /* ï¿½ */
            case 0x7c: new = 0x7c; break; /* ï¿½ */
            case 0x7e: new = 0x7d; break; /* ï¿½ */
            case 0x1e: new = 0x7e; break; /* ï¿½ */
            case 0x5f: new = 0x5e; break; /* ï¿½ */
            default: new = c;
        }
        if (new != c)
        {
            NSString *temp = [NSString stringWithFormat:@"%c", new];
            [self replaceCharactersInRange:NSMakeRange(pos, 1) withString:temp];
        }
    }
}

- (void) convertNrcIso21GermanToGsm
{
    long pos, len;
    int c, new;
    
    len = [self length];
    
    for (pos = 0; pos < len; pos++)
    {
        c = [self characterAtIndex:pos];
        switch (c)
        {
                /* NRC value; GSM value */
            case 0x5b: new = 0x5b; break; /* ï¿½ */
            case 0x5c: new = 0x5c; break; /* ï¿½ */
            case 0x5d: new = 0x5e; break; /* ï¿½ */
            case 0x7b: new = 0x7b; break; /* ï¿½ */
            case 0x7c: new = 0x7c; break; /* ï¿½ */
            case 0x7d: new = 0x7e; break; /* ï¿½ */
            case 0x7e: new = 0x1e; break; /* ï¿½ */
            case 0x5e: new = 0x5f; break; /* ï¿½ */
            default: new = c;
        }
        if (new != c)
        {
            NSString *temp = [NSString stringWithFormat:@"%c", new];
            [self replaceCharactersInRange:NSMakeRange(pos, 1) withString:temp];
        }
    }

}

- (int) truncateToLength:(long)len
{
    if ([self length] > len)
    {
        /* If the last GSM character was an escaped character,
         * then chop off the escape as well as the character. */
        if ([self characterAtIndex:len - 1] == 27)
            [self deleteCharactersInRange:NSMakeRange(len - 1, [self length] - len + 1)];
        else
            [self deleteCharactersInRange:NSMakeRange(len, [self length] - len)];
        return 1;
    }
    return 0;
}

- (void) convertFromGsmToLatin1
{
    long pos, len;
    
    len = [self length];
    for (pos = 0; pos < len; pos++)
    {
        int c, new, i;
        
        c = [self characterAtIndex:pos];
        if (c == 27 && pos + 1 < len)
        {
            /* GSM escape code.  Delete it, then process the next
             * character specially. */
            [self deleteCharactersInRange:NSMakeRange(pos, 1)];
            len--;
            c = [self characterAtIndex:pos];
            for (i = 0; gsm_esctolatin1[i].gsmesc >= 0; i++)
            {
                if (gsm_esctolatin1[i].gsmesc == c)
                    break;
            }
            if (gsm_esctolatin1[i].gsmesc == c)
                new = gsm_esctolatin1[i].latin1;
            else if (c < 128)
                new = gsm_to_latin1[c];
            else
                continue;
        }
        else if (c < 128)
        {
            new = gsm_to_latin1[c];
        }
        else
        {
            continue;
        }
        if (new != c)
        {
            NSString *temp = [NSString stringWithFormat:@"%c", new];
            [self replaceCharactersInRange:NSMakeRange(pos, 1) withString:temp];
        }
    }

}

- (void) convertFromLatin1ToGsm
{
    long pos, len;
    int c, new;
    unsigned char esc = 27;
    
    len = [self length];
    for (pos = 0; pos < len; pos++)
    {
        c = [self characterAtIndex:pos];
        if (c < 0)
            return;
        if (c > 256)
            return;
        new = latin1_to_gsm[c];
        
        if (new < 0)
        {
            /* Escaped GSM code */
            NSString *temp = [NSString stringWithFormat:@"%c", esc];
            [self insertString:temp atIndex:pos];
            pos++;
            len++;
            new = -new;
        }
        if (new != c)
        {
            NSString *temp = [NSString stringWithFormat:@"%c", new];
            [self replaceCharactersInRange:NSMakeRange(pos, 1) withString:temp];
        }
    }

}

- (int)convertFrom:(char *)charset_from to:(char *)charset_to
{
    unichar *from_buf = nil;
    char *to_buf, *pointer;
    size_t inbytesleft, outbytesleft, ret;
    iconv_t cd;
    
    if (!charset_from || !charset_to) /* sanity check */
        return -1;
    
    cd = iconv_open(charset_to, charset_from);
    /* Did I succeed in getting a conversion descriptor ? */
    if (cd == (iconv_t)(-1))
        /* I guess not */
        return -1;
    
    [self getCharacters:from_buf range:NSMakeRange(0, [self length])];
    inbytesleft = [self length];
    /* allocate max sized buffer, assuming target encoding may be 4 byte unicode */
    outbytesleft = inbytesleft * 4;
    pointer = to_buf = malloc(outbytesleft);
    
    do
    {
        ret = iconv(cd, (char**) &from_buf, &inbytesleft, &pointer, &outbytesleft);
        if(ret == -1) {
            long tmp;
            /* the conversion failed somewhere */
            switch(errno)
            {
                case E2BIG: /* no space in output buffer */
                    tmp = pointer - to_buf;
                    to_buf = realloc(to_buf, tmp + inbytesleft * 4);
                    outbytesleft += inbytesleft * 4;
                    pointer = to_buf + tmp;
                    ret = 0;
                    break;
                    
                case EILSEQ: /* invalid multibyte sequence */
                case EINVAL: /* incomplete multibyte sequence */
                    /* skeep char and try next */
                    if (outbytesleft == 0)
                    {
                        /* buffer to small */
                        tmp = pointer - to_buf;
                        to_buf = realloc(to_buf, tmp + inbytesleft * 4);
                        outbytesleft += inbytesleft * 4;
                        pointer = to_buf + tmp;
                    }
                    
                    pointer[0] = from_buf[0];
                    pointer++;
                    from_buf++;
                    inbytesleft--;
                    outbytesleft--;
                    ret = 0;
                    break;
            }
        }
    }
    while(inbytesleft && ret == 0); /* stop if error occurs and not handled above */
    
    iconv_close(cd);
    
    if (ret != -1)
    {
        /* conversion succeeded */
        [self truncateToLength:0];
        [self appendFormat:@"%s", to_buf];
        ret = 0;
    }
    
    free(to_buf);
    return (int)ret;
}

@end

@implementation NSMutableData (TestCharset)

/* use iconv library to convert an NSData in place, from source character set to
 * destination character set
 */
- (int)convertFrom:(char *)charset_from to:(char *)charset_to
{
    unichar *from_buf = nil;
    char *to_buf, *pointer;
    size_t inbytesleft, outbytesleft, ret;
    iconv_t cd;
    
    if (!charset_from || !charset_to) /* sanity check */
        return -1;
    
    cd = iconv_open(charset_to, charset_from);
    /* Did I succeed in getting a conversion descriptor ? */
    if (cd == (iconv_t)(-1))
    /* I guess not */
        return -1;
    
    from_buf = (unichar *)[self bytes];
    inbytesleft = [self length];
    /* allocate max sized buffer, assuming target encoding may be 4 byte unicode */
    outbytesleft = inbytesleft * 4;
    pointer = to_buf = malloc(outbytesleft);
    
    do
    {
        ret = iconv(cd, (char**) &from_buf, &inbytesleft, &pointer, &outbytesleft);
        if(ret == -1) {
            long tmp;
            /* the conversion failed somewhere */
            switch(errno)
            {
                case E2BIG: /* no space in output buffer */
                    tmp = pointer - to_buf;
                    to_buf = realloc(to_buf, tmp + inbytesleft * 4);
                    outbytesleft += inbytesleft * 4;
                    pointer = to_buf + tmp;
                    ret = 0;
                    break;
                    
                case EILSEQ: /* invalid multibyte sequence */
                case EINVAL: /* incomplete multibyte sequence */
                    /* skeep char and try next */
                    if (outbytesleft == 0)
                    {
                        /* buffer to small */
                        tmp = pointer - to_buf;
                        to_buf = realloc(to_buf, tmp + inbytesleft * 4);
                        outbytesleft += inbytesleft * 4;
                        pointer = to_buf + tmp;
                    }
                    
                    pointer[0] = from_buf[0];
                    pointer++;
                    from_buf++;
                    inbytesleft--;
                    outbytesleft--;
                    ret = 0;
                    break;
            }
        }
    }
    while(inbytesleft && ret == 0); /* stop if error occurs and not handled above */
    
    iconv_close(cd);
    
    if (ret != -1)
    {
        /* conversion succeeded */
        [self replaceBytesInRange:NSMakeRange(0, [self length]) withBytes:nil length:0];
        [self appendBytes:to_buf length:outbytesleft];
        ret = 0;
    }
    
    free(to_buf);
    return (int)ret;

}

- (void)convertFromGsmToUTF8
{
    long pos, len;
    NSMutableData  *newdata;
    
    newdata = [NSMutableData data];
    len = [self length];
    
    for (pos = 0; pos < len; pos++)
    {
        int i;
        char *c = malloc(1);
        
        [self getBytes:c range:NSMakeRange(pos, 1)];
        if (c[0] > 127)
            continue;
        
        if (c[0] == 27 && pos + 1 < len)
        {
            [self getBytes:c range:NSMakeRange(++pos, 1)];
            for (i = 0; gsm_esctouni[i].gsmesc >= 0; i++)
            {
                if (gsm_esctouni[i].gsmesc == c[0])
                    break;
            }
            if (gsm_esctouni[i].gsmesc == c[0])
            {
                /* found a value for escaped char */
                c[0] = gsm_esctouni[i].unichar;
            }
            else
            {
                /* nothing found, look esc in our table */
                c[0] = gsm_to_unicode[27];
                pos--;
            }
            c[0] = gsm_to_unicode[c[0]];
        }
        
        /* unicode to utf-8 */
        if (c[0] < 128)
        {
            /* 0-127 are ASCII chars that need no conversion */
            [newdata appendBytes:c length:1];
        }
        else
        {
            /* test if it can be converterd into a two byte char */
            if(c[0] < 0x0800)
            {
                c[0] = ((c[0] >> 6) | 0xC0) & 0xFF;
                [newdata appendBytes:c length:1]; /* add 110xxxxx */
                c[0] = (c[0] & 0x3F) | 0x80;
                [newdata appendBytes:c length:1];; /* add 10xxxxxx */
            }
            else
            {
                /* else we encode with 3 bytes. This only happens in case of euro symbol */
                c[0] = ((c[0] >> 12) | 0xE0) & 0xFF;
                [newdata appendBytes:c length:1]; /* add 1110xxxx */
                c[0] = (((c[0] >> 6) & 0x3F) | 0x80) & 0xFF;
                [newdata appendBytes:c length:1]; /* add 10xxxxxx */
                c[0] = ((c[0]  & 0x3F) | 0x80) & 0xFF;
                [newdata appendBytes:c length:1]; /* add 10xxxxxx */
            }
            /* There are no 4 bytes encoded characters in GSM charset */
        }
    }
    
    [self replaceBytesInRange:NSMakeRange(0, [self length]) withBytes:nil length:0];
    [self appendData:newdata];
}

@end

@implementation MetaData

@synthesize group;
@synthesize values;
@synthesize next;

 - (MetaData *)init
{
    if ((self = [super init]))
    {
        group = nil;
        values = nil;
        next = nil;
    }
    return self;
}


@end

@implementation NSMutableString (MetaData)

/* format: ?group-name?key=value&key=value?group?... group, key, value are urlencoded */
- (MetaData *)metaDataUnpack
{
    MetaData *meta, *our_curr;
    const char *str;
    long pos;
    NSString *key = NULL;
    int type, next_type;
    long start, end;
    
    start = end = -1;
    type = next_type = -1;
    for (pos = 0, str = [self UTF8String]; pos <= [self length]; str++, pos++)
    {
        switch(*str)
        {
            case '?':
                if (start == -1)
                { /* start of str */
                    start = pos;
                    type = 0;
                }
                else if (type == 0)
                { /* end of group */
                    end = pos;
                    next_type = 1;
                }
                else if (type == 2 && key)
                { /* end of value */
                    end = pos;
                    next_type = 0;
                }
                else if (!key)
                { /* start of next group without key and value */
                    start = pos;
                    type = 0;
                }
                else
                {
                    /* FAILED */
                    return nil;
                }
            break;
                
            case '=':
                if (type == 1 && our_curr && !key)
                { /* end of key */
                    end = pos;
                    next_type = 2;
                }
                else
                {
                    /* FAILED */
                    return nil;
                }
            break;
                
            case '&':
                if (type == 2 && our_curr && key)
                { /* end of value */
                    end = pos;
                    next_type = 1;
                }
                else if (type == 1 && !key)
                { /* just & skip it */
                    start = pos;
                }
                else
                {
                    /* FAILED */
                    return nil;
                }
            break;
                
            case '\0':
                if (type == 2) /* end of value */
                    end = pos;
                break;
        }
        
        if (start >= 0 && end >= 0)
        {
            NSString *tmp;
            
            if (end - start - 1 == 0)
                tmp = [NSString string];
            else
                tmp = [NSString stringWithCharacters:(unichar *)str - end + start + 1 length:end - start - 1];
            
            [tmp stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];;
            
            switch(type)
            {
                case 0: /* group */
                    if (!our_curr)
                    {
                        our_curr = [[MetaData alloc] init];
                    }
                    else
                    {
                        [our_curr setNext:[[MetaData alloc] init]];
                        our_curr = [our_curr next];
                    }
                    [our_curr setGroup:tmp];
                    tmp = nil;
                    [our_curr setValues:[[NSMutableDictionary alloc] init]];
                    [our_curr setNext:nil];
                    if (!meta)
                    {
                        meta = [NSDictionary dictionaryWithDictionary:our_curr];
                    }
                    break;
                    
                case 1: /* key */
                    key = tmp;
                    tmp = nil;
                break;
                    
                case 2: /* value */
                    [[our_curr values] setObject:tmp forKey:key];
                    tmp = nil;
                    key = nil;
                    break;
            }
        
            type = next_type;
            next_type = -1;
            start = end;
            end = -1;
        }
    }
    
    return meta;
}

- (int) metaDataPackInto:(MetaData *)mdata
{
    NSArray *l;
    NSString *tmp;
    
    if (!mdata)
        return -1;
    
    [self deleteCharactersInRange:NSMakeRange(0, [self length])];
    do
    {
        NSString *escaped = [[mdata group] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [self appendString:escaped];
        l = [[mdata values] allKeys];
        while (l && (tmp = [l objectAtIndex:0]))
        {
            NSString *pair = [NSString stringWithFormat:@"%@=%@", tmp, [[mdata values] objectForKey:tmp]];
            escaped = [pair stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [self appendString:escaped];
        }
        
        mdata = [mdata next];
    } while (mdata);
    
    return 0;
}

- (NSDictionary *)getMetaDataValuesOfGroup:(const char *)group
{
    MetaData *mdata, *curr;
    NSDictionary *dict;
    
    if (!group)
        return nil;
    
    mdata = [self metaDataUnpack];
    if (!mdata)
        return nil;
    
    for (curr = mdata; curr != nil; curr = [curr next])
    {
        if ([[curr group] caseInsensitiveCompare:[NSString stringWithCString:group encoding:NSUTF8StringEncoding]] == NSOrderedSame)
        {
            dict = [curr values];
            [curr setValues:nil];
            break;
        }
    }
    
    return dict;
}

- (int) setMetaDataValuesIn:(const NSMutableDictionary *)dict fromGroup:(const char *)group replaceExisting:(BOOL)replace
{
    MetaData *mdata, *curr;
    int i;
    NSArray *keys;
    NSString *key;
    
    if (!group)
        return -1;
    
    mdata = [self metaDataUnpack];
    for (curr = mdata; curr != nil; curr = [curr next])
    {
        if ([[curr group] caseInsensitiveCompare:[NSString stringWithCString:group encoding:NSUTF8StringEncoding]] == NSOrderedSame)
        {
            /*
             * If we don't replace the values, copy the old Dict values to the new Dict
             */
            if (replace == 0)
            {
                keys = [[curr values] allKeys];
                while ((key = [keys objectAtIndex:0]))
                {
                    NSString *temp = [[curr values] objectForKey:key];
                    if (![dict objectForKey:key])
                        [dict setObject:temp forKey:key];
                }
            }
            
            [curr setValues:[NSDictionary dictionaryWithDictionary:dict]];
            break;
        }
    }
    
    if (!curr)
    {
        curr = [[MetaData alloc] init];
        [curr setGroup:[NSString stringWithCString:group encoding:NSUTF8StringEncoding]];
        [curr setValues:[NSDictionary dictionaryWithDictionary:dict]];
        [curr setNext:nil];
        
        if (!mdata)
        {
            mdata = curr;
        }
        else
        {
            [curr setNext:[mdata next]];
            [mdata setNext:curr];
        }
    }
    
    i = [self metaDataPackInto:mdata];
    [curr setValues:nil];
    
    return i;
}

- (int) setMetaDataValueForGroup:(const char *)group andKey:(const NSString *)key insertValue:(const NSString*) value replaceExisitng:(BOOL)replace
{
    MetaData *mdata, *curr;
    int result = 0;
    
    if (!group || !value)
        return -1;
    
    mdata = [self metaDataUnpack];;
    for (curr = mdata; curr != nil; curr = [curr next])
    {
        if ([[curr group] caseInsensitiveCompare:[NSString stringWithCString:group encoding:NSUTF8StringEncoding]] == NSOrderedSame)
            break;
    }
    
    if (!curr)
    {
        /* group doesn't exists */
        curr = [[MetaData alloc] init];
        [curr setGroup:[NSString stringWithCString:group encoding:NSUTF8StringEncoding]];
        [curr setValues:[[NSMutableDictionary alloc] init]];
        if (mdata)
        {
            [curr setNext:[mdata next]];
            [mdata setNext:curr];
        }
        else 
            mdata = curr;
    }
    
    if (replace)
        [[curr values] setObject:value forKey:key];
    else if (![[curr values] objectForKey:key])
        /* put new value */
        [[curr values] setValue:value forKey:(NSString *)key];

    /* pack it */
    result = [self metaDataPackInto:mdata];
    
    return result;
}

- (NSString *) getMetaDataValueWithGroup:(const char *)group andKey:(const NSString *)key
{
    MetaData *mdata, *curr;
    NSString *ret = NULL;
    
    if (!group || !key)
        return NULL;
    
    mdata = [self metaDataUnpack];
    if (!mdata)
        return nil;
    
    for (curr = mdata; curr != NULL; curr = [curr next])
    {
        if ([[curr group] caseInsensitiveCompare:[NSString stringWithCString:group encoding:NSUTF8StringEncoding]] == NSOrderedSame)
        {
            ret = [[curr values] objectForKey:key];
            [[curr values] removeObjectForKey:key];
            break;
        }
    }
    
    return ret;
}

@end

