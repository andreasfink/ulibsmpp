//
//  TestSMPPAdditions.h
//  ulibsmpp
//
//  Created by Aarno Syvänen on 31.08.12.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#include <uuid/uuid.h>

#import "ulib/ulib.h"
#import "TestObject.h"

#define UUID_STR_LEN 36

typedef enum
{
    SMSCCONN_CONNECTING,
    SMSCCONN_ACTIVE,
    SMSCCONN_ACTIVE_RECV,
    SMSCCONN_RECONNECTING,
    SMSCCONN_DISCONNECTED,
    SMSCCONN_DEAD       /* ready to be cleaned */
} smscconn_status_t;

typedef enum
{
    SMSCCONN_ALIVE = 0,
    SMSCCONN_KILLED_WRONG_PASSWORD = 1,
    SMSCCONN_KILLED_CANNOT_CONNECT = 2,
    SMSCCONN_KILLED_SHUTDOWN = 3
} smscconn_killed_t;

@class UMLogFeed, UMLogHandler, UMConfig;


@interface TestMutableArray : UMObject
{
    NSMutableArray *array;
    NSCondition *nonempty;
    NSLock *singleOperationLock;
    NSLock *permanentLock;
    long numProducers;
    long numConsumers;
}

- (TestMutableArray *) init;
- (id) consume;
- (id) consumeUnlocked;
- (void) dealloc;
- (void) addProducer;
- (void) removeProducer;
- (void) addObject:(id)item;
- (void) addObjectUnlocked:(id)item;
- (NSUInteger) count;
- (id) objectAtIndex:(NSUInteger)index;
- (void) insertObject:(id)anObject atIndex:(NSUInteger)index;
- (NSString *) description;
- (void) lock;
- (void) unlock;
- (int) producerCount;

@end


@interface TestElement : TestObject
{
    id item;
    long long seq;
}

@property(readwrite,retain) id item;
@property(readwrite,assign) long long seq;

@end

@interface TestPrioQueue : TestObject
{
    NSLock *mutex;
    NSMutableArray *tab;
    size_t size;
    long len;
    long producers;
    long long seq;
    NSCondition *nonempty;
    int (*cmp)(id, id);
}

/**
 * Create priority queue
 * @cmp - compare function
 * @return newly created priority queue
 */
-(TestPrioQueue *)initWithComparator:(int(*)(id, id))cmp;
-(long)length;

/**
 * Insert item into the priority queue
 * @item - to be inserted item
 */
-(void)insert:(id)tem;

/**
 * Same method with another name
 */
-(void)produce:(id)tem;

- (void) foreachCall:(void(*)(id, long))fn;

/**
 * Remove biggest item from the priority queue, but not block if producers
 * available and none items in the queue
 * @return - biggest item or NULL if none items in the queue
 */
-(id)remove;

/*
 * Same as remove, except that item is not removed from the
 * priority queue
 */
-(id)get;

/**
 * Remove biggest item from the priority queue, but block if producers
 * available and none items in the queue
 * @return biggest item or nil if none items and none producers in the queue
 */
-(id)consume;

/**
 * Add producer to the priority queue
 */
-(void) addProducer;

/**
 * Remove producer from the priority queue
 */
-(void)removeProducer;

/**
 * Return producer count for the priority queue
 * @return producer count
 */
-(long)producerCount;

@end

@interface TestCounter : TestObject
{
    NSLock *lock;
    unsigned long n;
}

/* create a new counter object.*/
- (TestCounter *)init;

/* return the current value of the counter and increase counter by one */
- (unsigned long)increase;

/* return the current value of the counter and increase counter by value */
- (unsigned long)increaseWith:(unsigned long)value;

/* return the current value of the counter */
-(unsigned long)value;

/* return the current value of the counter and decrease counter by one */
- (unsigned long)decrease;

/* return the current value of the counter and set it to the supplied value */
- (unsigned long)setTo:(unsigned long)value;

@end

@interface TestLoadEntry : TestObject
{
    float prev;
    float curr;
    time_t last;
    int interval;
    int dirty;
}

@property(readwrite, assign) float prev;
@property(readwrite, assign) float curr;
@property(readwrite, assign) time_t last;
@property(readwrite, assign) int dirty;
@property(readwrite, assign) int interval;

@end

@class UMReadWriteLock;

@interface TestLoad : UMObject
{
    NSMutableArray *entries;
    int len;
    int heuristic;
    UMReadWriteLock  *lock;
}

/**
 * Create new Load object.
 * @heuristic - 0 disable heuristic (means get always current load); 1 enable
 */
-(TestLoad *)initWithHeuristics:(BOOL)heuristic;

/**
 * Add load measure interval.
 * @interval - measure interval in seconds
 * @return -1 if error occurs (e.g. interval already exists); 0 if all was fine
 */
-(int)addInterval:(int)interval;

/**
 * Increase load values with @value.
 * @valu - how much to increase
 */
-(void) increaseWith:(unsigned long)value;

-(void)dealloc;

/**
 * Get measured load value at position @pos.
 */
-(float) getValueAt:(int)pos;

/**
 * Get length of intervals.
 */
-(int)len;

@end


@interface StatusInfo : TestObject
{
    smscconn_status_t status;   /* see enumeration, below */
    smscconn_killed_t killed;   /* if we are killed, why */
    int is_stopped;             /* is connection currently in stopped state? */
    unsigned long received;     /* total number */
    unsigned long received_dlr; /* total number */
    unsigned long sent;         /* total number */
    unsigned long sent_dlr;     /* total number */
    unsigned long failed;       /* total number */
    long queued;                /* set our internal outgoing queue length */
    long online;                /* in seconds */
    int load;                   /* subjective value 'how loaded we are' for
                                 * routing purposes, similar to sms/wapbox load */
}

@end

enum msg_type
{
    heartbeat,
    admin,
    sms,
    ack
};

enum
{
    mo = 0,
    mt_reply = 1,
    mt_push = 2,
    report_mo = 3,
    report_mt = 4
};

/* admin commands */
enum
{
    cmd_shutdown = 0,
    cmd_suspend = 1,
    cmd_resume = 2,
    cmd_identify = 3,
    cmd_restart = 4
};

/* ack message status */
typedef enum
{
    ack_success = 0,
    ack_failed = 1,     /* do not try again (e.g. no route) */
    ack_failed_tmp = 2, /* temporary failed, try again (e.g. queue full) */
    ack_buffered = 3
} ack_status_t;


@interface Msg : TestObject
{
    enum msg_type type;
    
    long load;
    
    long command;
    NSString *boxc_id;
    
    NSString *sender;
    NSString *receiver;
    NSData *udhdata;
    NSMutableData *msgdata;
    time_t time;
    NSString *smsc_id;
    NSString *smsc_number;
    NSString *foreign_id;
    NSString *service;
    NSString *account;
    uuid_t uuid;
    long sms_type;
    long mclass;
    long mwi;
    long coding;
    long compress;
    long validity;
    long deferred;
    long dlr_mask;
    NSString *dlr_url;
    long pid;
    long alt_dcs;
    long rpi;
    NSString *charset;
    NSString *binfo;
    long msg_left;
    id split_parts;
    long priority;
    long resend_retry;
    long resend_time;
    NSMutableString *meta_data;
    
    long nack;
}

@property(readwrite,assign) enum msg_type type;

@property(readwrite,assign) long load;

@property(readwrite,assign) long command;
@property(readwrite,retain) NSString *boxc_id;

@property(readwrite,retain) NSString *sender;
@property(readwrite,retain) NSString *receiver;
@property(readwrite,retain) NSData *udhdata;
@property(readwrite,retain) NSMutableData *msgdata;
@property(readwrite,assign) time_t time;
@property(readwrite,retain) NSString *smsc_id;
@property(readwrite,retain) NSString *smsc_number;
@property(readwrite,retain) NSString *foreign_id;
@property(readwrite,retain) NSString *service;
@property(readwrite,retain) NSString *account;
@property(readwrite,assign) long sms_type;
@property(readwrite,assign) long mclass;
@property(readwrite,assign) long mwi;
@property(readwrite,assign) long coding;
@property(readwrite,assign) long compress;
@property(readwrite,assign) long validity;
@property(readwrite,assign) long deferred;
@property(readwrite,assign) long dlr_mask;
@property(readwrite,retain) NSString *dlr_url;
@property(readwrite,assign) long pid;
@property(readwrite,assign) long alt_dcs;
@property(readwrite,assign) long rpi;
@property(readwrite,retain) NSString *charset;
@property(readwrite,retain) NSString *binfo;
@property(readwrite,assign) long msg_left;
@property(readwrite,retain) id split_parts;
@property(readwrite,assign) long priority;
@property(readwrite,assign) long resend_retry;
@property(readwrite,assign) long resend_time;
@property(readwrite,retain) NSMutableString *meta_data;

@property(readwrite,assign) long nack;

- (void)setUUID:(uuid_t)iUUID;

/*
 * Create a new, empty Msg object.
 */
- (Msg *)initWithType:(enum msg_type) type;

/*
 * Create a new Msg object that is a copy of an existing one.
 */
- (Msg *)copy;

/*
 * Destroy an Msg object. All fields are also destroyed.
 */
- (void) dealloc;

/*
 * For debugging: Output with `debug' (in gwlib/log.h) the contents of
 * an Msg object.
 */
- (NSString *) description;

/*
 * Pack an Msg into an NSData.
 */
- (NSData *)pack;


/*
 * Unpack an Msg from an NSData. Return nil for failure, otherwise a pointer
 * to the Msg.
 */
- (Msg *)unpack:(NSData *)data;

/*
 * Compare Msg priorities
 */
int sms_priority_compare(id a, id b);

- (int) dcsToFieldsWithDcs:(int)dcs;

@end

@interface NSMutableString (TestCharset)

/**
 * Convert NSString in GSM format to UTF-8.
 * Every GSM character can be represented with unicode, hence nothing will
 * be lost. Escaped charaters will be translated into appropriate UTF-8 character.
 */
- (void)convertFromGsmToUTF8;

/**
 * Convert NSString in UTF-8 format to GSM 03.38.
 * Because not all UTF-8 charater can be converted to GSM 03.38 non
 * convertable character replaces with NRP character (see define above).
 * Special characters will be formed into escape sequences.
 * Incomplete UTF-8 characters at the end of the string will be skipped.
 */
- (void)convertFromUTF8ToGsm;

/*
 * Convert from GSM default character set to NRC ISO 21 (German)
 * and vise versa.
 */
- (void) convertFromGsmToNrcIso21German;
- (void) convertNrcIso21GermanToGsm;

/* Trunctate a string of GSM characters to a maximum length.
 * Make sure the last remaining character is a whole character,
 * and not half of an escape sequence.
 * Return 1 if any characters were removed, otherwise 0.
 */
- (int) truncateToLength:(long)len;

/* Convert a string in the GSM default character set (GSM 03.38)
 * to ISO-8859-1.  A series of Greek characters (codes 16, 18-26)
 * are not representable and are converted to '?' characters.
 * GSM default is a 7-bit alphabet.  Characters with the 8th bit
 * set are left unchanged. */
- (void) convertFromGsmToLatin1;

/* Convert a string in the ISO-8859-1 character set to the GSM
 * default character set (GSM 03.38).  A large number of characters
 * are not representable.  Approximations are made in some cases
 * (accented characters to their unaccented versions, for example),
 * and the rest are converted to '?' characters. */
- (void)convertFromLatin1ToGsm;

/* use iconv library to convert an NSString in place, from source character set to
 * destination character set
 */
- (int)convertFrom:(char *)charset_from to:(char *)charset_to;

@end

@interface NSMutableData (TestCharset)

/* use iconv library to convert an NSData in place, from source character set to
 * destination character set
 */
- (int)convertFrom:(char *)charset_from to:(char *)charset_to;

/**
 * Convert NSData in GSM format to UTF-8.
 * Every GSM character can be represented with unicode, hence nothing will
 * be lost. Escaped charaters will be translated into appropriate UTF-8 character.
 */
- (void)convertFromGsmToUTF8;

@end

@interface MetaData : TestObject
{
    NSString *group;
    NSMutableDictionary *values;
    MetaData *next;
}

@property(readwrite,retain) NSString *group;
@property(readwrite,retain) NSMutableDictionary *values;
@property(readwrite,retain)  MetaData *next;

- (MetaData *)init;
- (void)dealloc;

@end

@interface NSMutableString (MetaData)

- (MetaData *)metaDataUnpack;
- (int) metaDataPackInto:(MetaData *)mdata;

/**
 * Get Dictionary with all values for this group.
 */
- (NSDictionary *)getMetaDataValuesOfGroup:(const char *)group;
/**
 * Replace Dictionary for the given group.
 */
- (int) setMetaDataValuesIn:(const NSMutableDictionary *)dict fromGroup:(const char *)group replaceExisting:(BOOL)replace;
/**
 * Set or replace value for a given group and key.
 */
- (int) setMetaDataValueForGroup:(const char *)group andKey:(const NSString *)key insertValue:(const NSString*) value replaceExisitng:(BOOL)replace;
/**
 * Get value for a given group and key.
 */
- (NSString *) getMetaDataValueWithGroup:(const char *)group andKey:(const NSString *)key;

@end
