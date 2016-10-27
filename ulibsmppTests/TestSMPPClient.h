//
//  TestSMPPClient.h
//  MessageMover-3.8
//
//  Created by Aarno Syvänen on 31.08.12.
//
//

#import <Foundation/Foundation.h>

#import "UMObject.h"
#import "TestSMPPAdditions.h"

#define SMPP_DEFAULT_CHARSET "UTF-8"

/*
 * Some defaults.
 */

#define SMPP_ENQUIRE_LINK_INTERVAL  30.0
#define SMPP_MAX_PENDING_SUBMITS    10
#define SMPP_DEFAULT_VERSION        0x34
#define SMPP_DEFAULT_PRIORITY       0
#define SMPP_THROTTLING_SLEEP_TIME  1
#define SMPP_DEFAULT_CONNECTION_TIMEOUT  10 * SMPP_ENQUIRE_LINK_INTERVAL
#define SMPP_DEFAULT_WAITACK        60
#define SMPP_DEFAULT_SHUTDOWN_TIMEOUT 30

/*
 * Some defines
 */
#define SMPP_WAITACK_RECONNECT      0x00
#define SMPP_WAITACK_REQUEUE        0x01
#define SMPP_WAITACK_NEVER_EXPIRE   0x02

enum
{
    SMSCCONN_FAILED_TEMPORARILY,
    SMSCCONN_FAILED_REJECTED
};

/*
 * Select these based on whether you want to dump SMPP PDUs as they are
 * sent and received or not. Not dumping should be the default in at least
 * stable releases.
 */

#define DEBUG 1

@class SmppPdu, SmscConnectionSMPP, SmppTlv;

@interface Tlvs : TestObject
{
    NSMutableDictionary *tlvs_by_tag;
    NSMutableDictionary *tlvs_by_name;
    NSMutableArray      *tlvs;
    int initialized;
}

- (Tlvs *)initWithConfig:(UMConfig *)cfg;
- (int) shutdown;
- (SmppTlv *)tlvWithSmscId:(NSString *)smsc_id andName:(NSString *)name;
- (SmppTlv *)tlvWithSmscId:(NSString *)smsc_id andTag:(long)tag;

@end

@interface TestSMPPClient : TestObject
{
    long transmitter;
    long receiver;
    TestPrioQueue *msgs_to_send;
    NSDictionary *sent_msgs;
    NSArray *received_msgs;
    TestCounter *message_id_counter;
    NSString *host;
    NSString *system_type;
    NSString *username;
    NSString *password;
    NSString *address_range;
    NSString *my_number;
    NSString *service_type;
    int source_addr_ton;
    int source_addr_npi;
    int dest_addr_ton;
    int dest_addr_npi;
    long bind_addr_ton;
    long bind_addr_npi;
    int transmit_port;
    int receive_port;
    int use_ssl;
    NSString *ssl_client_certkey_file;
    volatile int quitting;
    long enquire_link_interval;
    long max_pending_submits;
    int version;
    int priority;       /* set default priority for messages */
    int validityperiod;
    time_t throttling_err_time;
    int smpp_msg_id_type;  /* msg id in NSString, hex or decimal */
    int autodetect_addr;
    NSString *alt_charset;
    NSString *alt_addr_charset;
    long connection_timeout;
    long wait_ack;
    int wait_ack_action;
    int esm_class;
    TestLoad *load;
    SmscConnectionSMPP *conn;
    Tlvs *tlvs;
}

@property(readwrite,retain) NSString *service_type;
@property(readwrite,assign) int source_addr_ton;
@property(readwrite,assign) int source_addr_npi;


@end
