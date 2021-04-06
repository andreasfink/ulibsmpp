//
//  SmppPdu.h
//  SMPP-SMPP
//
//  Created by Andreas Fink on 11.12.08.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import <Foundation/Foundation.h>

#import "UniversalSMSC.h"
#import "SmppErrorCode.h"
#import "SmppTlv.h"
#import "SmppMultiResult.h"

typedef	enum SmppReportingEntity
{
	SMPP_REPORTING_ENTITY_SMSC = 0,
	SMPP_REPORTING_ENTITY_HANDSET = 1,
	SMPP_REPORTING_ENTITY_MANUAL = 2,
} SmppReportingEntity;

typedef enum SmppNetworkType
{
	SMPP_NETWORK_TYPE_ANSI_I36 = 1,
	SMPP_NETWORK_TYPE_IS_95    = 2,
	SMPP_NETWORK_TYPE_GSM      = 3,
	SMPP_NETWORK_TYPE_RESERVED = 4,
} SmppNetworkType;


typedef enum SmppIncomingStatus
{
	SMPP_STATUS_INCOMING_OFF					= 0,
	SMPP_STATUS_INCOMING_HAS_SOCKET				= 1,
	SMPP_STATUS_INCOMING_BOUND					= 2,
	SMPP_STATUS_INCOMING_LISTENING              = 3,
	SMPP_STATUS_INCOMING_CONNECTED				= 4,/* but not authenticated yet	*/
	SMPP_STATUS_INCOMING_ACTIVE					= 5,/* correctly logged in			*/
	SMPP_STATUS_INCOMING_CONNECT_RETRY_TIMER	= 6,
	SMPP_STATUS_INCOMING_BIND_RETRY_TIMER		= 7,
	SMPP_STATUS_INCOMING_LOGIN_WAIT_TIMER		= 8,
	SMPP_STATUS_INCOMING_LISTEN_WAIT_TIMER		= 9,
	SMPP_STATUS_INCOMING_MAJOR_FAILURE			= 10,
	SMPP_STATUS_LISTENER_MAJOR_FAILURE_RESTART_TIMER	= 11,
} SmppIncomingStatus;

typedef enum SmppOutgoingStatus
{
    SMPP_STATUS_OUTGOING_OFF                        = 100,
    SMPP_STATUS_OUTGOING_HAS_SOCKET                 = 101,
    SMPP_STATUS_OUTGOING_MAJOR_FAILURE              = 102,
    SMPP_STATUS_OUTGOING_MAJOR_FAILURE_RETRY_TIMER  = 103,
    SMPP_STATUS_OUTGOING_CONNECTING                 = 104,
    SMPP_STATUS_OUTGOING_CONNECTED                  = 105,     /* but not authenticated yet	*/
    SMPP_STATUS_OUTGOING_ACTIVE                     = 106,  /* correctly logged in			*/
    SMPP_STATUS_OUTGOING_CONNECT_RETRY_TIMER        = 107
} SmppOutgoingStatus;

typedef enum SmppState
{
	SMPP_STATE_CLOSED 			= 0x00,
	SMPP_STATE_IN_OPEN 			= 0x01,		/* connections which are established incoming */
	SMPP_STATE_IN_BOUND_TX 		= 0x02,
	SMPP_STATE_IN_BOUND_RX		= 0x04,
	SMPP_STATE_IN_BOUND_TRX 	= (SMPP_STATE_IN_BOUND_TX | SMPP_STATE_IN_BOUND_RX),
	SMPP_STATE_OUT_OPEN			= 0x10, 	/* connections which are established outgoing */
	SMPP_STATE_OUT_BOUND_TX 	= 0x20,
	SMPP_STATE_OUT_BOUND_RX		= 0x40,
	SMPP_STATE_OUT_BOUND_TRX 	= (SMPP_STATE_OUT_BOUND_TX | SMPP_STATE_OUT_BOUND_RX),
    SMPP_STATE_ANY_BOUND_TRX    = (SMPP_STATE_IN_BOUND_TRX | SMPP_STATE_OUT_BOUND_TRX),
    SMPP_STATE_ANY              = (SMPP_STATE_ANY_BOUND_TRX | SMPP_STATE_IN_OPEN | SMPP_STATE_OUT_OPEN),
} SmppState;

typedef	enum SmppMessageState
{
	SMPP_MESSAGE_STATE_ENROUTE		= 1,
	SMPP_MESSAGE_STATE_DELIVERED	= 2,
	SMPP_MESSAGE_STATE_EXPIRED		= 3,
	SMPP_MESSAGE_STATE_DELETED		= 4,
	SMPP_MESSAGE_STATE_UNDELIVERABLE = 5,
	SMPP_MESSAGE_STATE_ACCEPTED		= 6,
	SMPP_MESSAGE_STATE_UNKNOWN		= 7,
	SMPP_MESSAGE_STATE_REJECTED		= 8,
} SmppMessageState;
	
typedef	enum	SmppSource
{
	SMPP_SOURCE_SMSC = 0x01,
	SMPP_SOURCE_ESME = 0x02,
	SMPP_SOURCE_BOTH = 0x03,
} SmppSource;

typedef enum SmppPduType
{
	SMPP_PDU_GENERIC_NACK			= 0x80000000,
	SMPP_PDU_BIND_RECEIVER 			= 0x00000001,
	SMPP_PDU_BIND_RECEIVER_RESP 	= 0x80000001,
	SMPP_PDU_BIND_TRANSMITTER		= 0x00000002,
	SMPP_PDU_BIND_TRANSMITTER_RESP  = 0x80000002,
	SMPP_PDU_QUERY_SM				= 0x00000003,
	SMPP_PDU_QUERY_SM_RESP			= 0x80000003,
	SMPP_PDU_SUBMIT_SM				= 0x00000004,
	SMPP_PDU_SUBMIT_SM_RESP			= 0x80000004,
	SMPP_PDU_DELIVER_SM				= 0x00000005,
	SMPP_PDU_DELIVER_SM_RESP		= 0x80000005,
	SMPP_PDU_UNBIND					= 0x00000006,
	SMPP_PDU_UNBIND_RESP			= 0x80000006,
	SMPP_PDU_REPLACE_SM				= 0x00000007,
	SMPP_PDU_REPLACE_SM_RESP		= 0x80000007,
	SMPP_PDU_CANCEL_SM				= 0x00000008,
	SMPP_PDU_CANCEL_SM_RESP			= 0x80000008,
	SMPP_PDU_BIND_TRANSCEIVER		= 0x00000009,
	SMPP_PDU_BIND_TRANSCEIVER_RESP	= 0x80000009,
	SMPP_PDU_OUTBIND				= 0x0000000B,
	SMPP_PDU_ENQUIRE_LINK			= 0x00000015,
	SMPP_PDU_ENQUIRE_LINK_RESP		= 0x80000015,
	SMPP_PDU_SUBMIT_SM_MULTI		= 0x00000021,
	SMPP_PDU_SUBMIT_SM_MULTI_RESP	= 0x80000021,
	SMPP_PDU_ALERT_NOTIFICATION		= 0x00000102,
	SMPP_PDU_DATA_SM				= 0x00000103,
	SMPP_PDU_DATA_SM_RESP			= 0x80000103,
    SMPP_PDU_EXEC                   = 0x00000203,
    SMPP_PDU_EXEC_RESP              = 0x80000204
} SmppPduType;


typedef enum SMPP_ESM_Class
{
	SMPP_PDU_ESM_CLASS_SUBMIT_DEFAULT_SMSC_MODE       	= 0x00000000,
	SMPP_PDU_ESM_CLASS_SUBMIT_DATAGRAM_MODE           	= 0x00000001,
	SMPP_PDU_ESM_CLASS_SUBMIT_FORWARD_MODE            	= 0x00000002,
	SMPP_PDU_ESM_CLASS_SUBMIT_STORE_AND_FORWARD_MODE  	= 0x00000003,
	SMPP_PDU_ESM_CLASS_SUBMIT_DELIVERY_ACK            	= 0x00000008,
	SMPP_PDU_ESM_CLASS_SUBMIT_USER_ACK                	= 0x00000010,
	SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR           	= 0x00000040,
	SMPP_PDU_ESM_CLASS_SUBMIT_RPI                     	= 0x00000080,
	SMPP_PDU_ESM_CLASS_SUBMIT_UDH_AND_RPI             	= 0x000000C0,
    
	SMPP_PDU_ESM_CLASS_DELIVER_DEFAULT_TYPE           	= 0x00000000,
	SMPP_PDU_ESM_CLASS_DELIVER_SMSC_DELIVER_ACK       	= 0x00000004,
	SMPP_PDU_ESM_CLASS_DELIVER_SME_DELIVER_ACK        	= 0x00000008,
	SMPP_PDU_ESM_CLASS_DELIVER_SME_MANULAL_ACK        	= 0x00000010,
	SMPP_PDU_ESM_CLASS_DELIVER_INTERM_DEL_NOTIFICATION	= 0x00000020,
	SMPP_PDU_ESM_CLASS_DELIVER_UDH_INDICATOR          	= 0x00000040,
	SMPP_PDU_ESM_CLASS_DELIVER_RPI                    	= 0x00000080,
	SMPP_PDU_ESM_CLASS_DELIVER_UDH_AND_RPI            	= 0x000000C0,
    
} SMPP_ESM_Class;

/******************************************************************************
 * Numering Plan Indicator and Type of Number codes from
 * GSM 03.40 Version 5.3.0 Section 9.1.2.5.
 * http://www.etsi.org/
 */
enum
{
    GSM_ADDR_TON_UNKNOWN = 0x00000000,
    GSM_ADDR_TON_INTERNATIONAL = 0x00000001,
    GSM_ADDR_TON_NATIONAL = 0x00000002,
    GSM_ADDR_TON_NETWORKSPECIFIC = 0x00000003,
    GSM_ADDR_TON_SUBSCRIBER = 0x00000004,
    GSM_ADDR_TON_ALPHANUMERIC = 0x00000005, /* GSM TS 03.38 */
    GSM_ADDR_TON_ABBREVIATED = 0x00000006,
    GSM_ADDR_TON_EXTENSION = 0x00000007 /* Reserved */
};

typedef unsigned long		SmppPduSequence;
#define	SMPP_SEQ_MASK	0xFFFFFFUL
/* we use ; in the middle because ; is split char in smsc-id and can't be in the smsc-id */
#define DEFAULT_SMSC_ID "def;ault"

@class Tlvs;

@interface SmppPdu : UMObject
{
    size_t              pdulen;
	SmppPduType			type;          /* a.k.a. command id */
	SmppErrorCode		err;           /* a.k.a. command status */
	SmppPduSequence		seq;           /* a.k.a. sequence number */
	NSMutableData		*payload;
	int					cursor;
    
    NSString            *system_id;
    NSString            *password;
    NSString            *system_type;
    long                interface_version;
    long                addr_npi;
    long                addr_ton;
    NSString            *address_range;
    
    long                source_addr_ton;
    long                source_addr_npi;
    NSString            *source_addr;
    long                dest_addr_ton;
    long                dest_addr_npi;
    NSString            *destination_addr;
    long                esm_class;
    long                protocol_id;
    long                priority_flag;
    NSString            *schedule_delivery_time;
    NSString            *validity_period;
    long                registered_delivery;
    long                replace_if_present_flag;
    long                data_coding;
    long                sm_default_msg_id;
    long                sm_length;
    NSData              *short_message;
    long                user_message_reference;
    long                source_port;
    long                source_addr_subunit;
    long                destination_port;
    long                dest_addr_subunit;
    long                sar_msg_ref_num;
    long                sar_total_segments;
    long                sar_segment_seqnum;
    long                more_messages_to_send;
    long                payload_type;
    NSData              *message_payload;
    long                privacy_indicator;
    NSData              *callback_num;
    long                callback_num_pres_ind;
    NSData              *callback_num_atag;
    NSData              *source_subaddress;
    NSData              *dest_subaddress;
    long                user_response_code;
    long                display_time;
    long                sms_signal;
    long                ms_validity;
    long                ms_msg_wait_facilities;
    long                number_of_messages;
    long                alert_on_message_delivery;
    long                language_indicator;
    long                its_reply_type;
    NSData              *its_session_info;
    NSData              *ussd_service_op;
    
    NSString            *message_id;
    
    NSString            *service_type;
    long                number_of_dests;
    NSString            *dest_address_es;
    
    long                no_unsuccess;
    
    NSData              *network_error_code;
    long                message_state;
    NSString            *receipted_message_id;
    
    long                source_network_type;
    long                source_bearer_type;
    long                source_telematics_id;
    long                dest_network_type;
    long                dest_bearer_type;
    long                dest_telematics_id;
    long                qos_time_to_live;
    long                set_dpf;
    
    long                delivery_failure_reason;
    NSString            *additional_status_info_text;
    long                dpf_result;
    
    NSString            *final_date;
    
    long                error_code;
    
    long                esme_addr_ton;
    long                esme_addr_npi;
    NSString            *esme_addr;
    long                ms_availability_status;
    
    long                sc_interface_version;
    NSMutableDictionary *tlv;
}


@property(readonly,assign)	size_t              pdulen;
@property(readonly,assign)	SmppPduType			type;
@property(readonly,assign)	SmppErrorCode		err;
@property(readwrite,assign)	SmppPduSequence		seq;
@property(readwrite,assign)	int					cursor;
@property(readonly,strong)	NSMutableData		*payload;
@property(readwrite,assign) long                source_addr_ton;
@property(readwrite,assign) long                source_addr_npi;
@property(readwrite,strong)  NSString           *source_addr;
@property(readwrite,strong)  NSString           *destination_addr;
@property(readwrite,assign) long                dest_addr_ton;
@property(readwrite,assign) long                dest_addr_npi;
@property(readwrite,strong)  NSString           *service_type;
@property(readwrite,strong)  NSString           *receipted_message_id;
@property(readwrite,assign) long                esm_class;
@property(readwrite,assign) long                sm_length;
@property(readwrite,strong) NSData              *short_message;
@property(readonly,assign) long                 data_coding;
@property(readwrite,assign) long                protocol_id;
@property(readwrite,assign) long                priority_flag;
@property(readwrite,strong) NSData              *message_payload;
@property(readwrite,strong) NSMutableDictionary *tlv;
@property(readwrite,strong) NSString            *message_id;
@property(readwrite,assign) long                replace_if_present_flag;
@property(readwrite,assign) long                dest_addr_subunit;
@property(readwrite,assign) long                source_addr_subunit;

- (void)setSequenceString:(NSString *)s;
- (NSString *)sequenceString;

- (SmppPdu *)initWithType:(SmppPduType)t err:(SmppErrorCode)e;
- (SmppPdu *)initWithType:(SmppPduType)t;
- (SmppPdu *)initFromData:(NSData *)d;

- (NSString *)description;

+ (SmppPdu *)OutgoingBindTransmitter:(NSString *)systemId 
							password:(NSString *)password 
						  systemType:(NSString *)stype
							 version:(NSInteger)version
								 ton:(NSInteger)ton 
								 npi:(NSInteger)npi 
							   range:(NSString *)range;
+ (SmppPdu *)OutgoingBindTransmitterRespError:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingBindTransmitterRespError:(SmppErrorCode) err status:(NSString *)status;
+ (SmppPdu *)OutgoingBindTransmitterRespOK:(NSString *)systemId
						  supportedVersion:(NSInteger)version;
+ (SmppPdu *)OutgoingBindReceiver:(NSString *)systemId 
						 password:(NSString *)password 
					   systemType:(NSString *)stype
						  version:(NSInteger)version
							  ton:(NSInteger)ton 
							  npi:(NSInteger)npi 
							range:(NSString *)range;

+ (SmppPdu *)OutgoingBindReceiverRespError:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingBindReceiverRespError:(SmppErrorCode) err status:(NSString *)status;
+ (SmppPdu *)OutgoingBindReceiverRespOK:(NSString *)systemId
					   supportedVersion:(NSInteger)version;

+ (SmppPdu *)OutgoingBindTransceiver:(NSString *)systemId 
							password:(NSString *)password 
						  systemType:(NSString *)stype
							 version:(NSInteger)version
								 ton:(NSInteger)ton 
								 npi:(NSInteger)npi 
                               range:(NSString *)range;

+ (SmppPdu *)OutgoingBindTransceiverRespError:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingBindTransceiverRespError:(SmppErrorCode) err status:(NSString *)status;
+ (SmppPdu *)OutgoingBindTransceiverRespOK:(NSString *)systemId supportedVersion:(NSInteger)version;

+ (SmppPdu *)OutgoingOutbind:(NSString *)systemId
					password:(NSString *)password;
+ (SmppPdu *)OutgoingUnbind;
+ (SmppPdu *)OutgoingUnbindRespOK;
+ (SmppPdu *)OutgoingUnbindRespErr:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingGenericNack:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg;
+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg options:(NSDictionary *)options;
+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype;
+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype options:(NSDictionary *)options;
+ (SmppPdu *)OutgoingSubmitSmReport:(id<SmscConnectionMessageProtocol>)msg reportingEntity:(SmppReportingEntity)re;
+ (SmppPdu *)OutgoingSubmitSmRespOK:(id<SmscConnectionMessageProtocol>)msg
							 withId:(NSString *)id;
+ (SmppPdu *)OutgoingSubmitSmRespErr:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingSubmitMulti:(id<SmscConnectionMessageProtocol>)msg distributionList:(NSString *) distributionListName;
+ (SmppPdu *)OutgoingSubmitMultiRespOK:(NSArray *)unsuccessfulDeliveries /* array of  SmppMultiResult */
								withId:(NSString *)msgid;
+ (SmppPdu *)OutgoingSubmitMultiRespErr:(SmppErrorCode) err;


+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg;
+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg
                       options:(NSDictionary *)options;
+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg
                      esmClass:(int)esmclass
                serviceType:(NSString *)servicetype;

+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg
                      esmClass:(int)esmclass serviceType:(NSString *)servicetype
                       options:(NSDictionary *)options;

+ (SmppPdu *)OutgoingDeliverSmReport:(id<SmscConnectionMessageProtocol>)msg
                     reportingEntity:(SmppReportingEntity)re;
+ (SmppPdu *)OutgoingDeliverSmRespOK:(id<SmscConnectionMessageProtocol>)msg
							  withId:(NSString *)msg_id;
+ (SmppPdu *)OutgoingDeliverSmReportRespOK:(id<SmscConnectionReportProtocol>)msg
							  withId:(NSString *)msg_id;
+ (SmppPdu *)OutgoingDeliverSmRespErr:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingDataSm:(id<SmscConnectionMessageProtocol>)msg;
+ (SmppPdu *)OutgoingDataSm:(id<SmscConnectionMessageProtocol>)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype;

+ (SmppPdu *)OutgoingDataSmRespOK:(id<SmscConnectionMessageProtocol>)msg
						   withId:(NSString *)msg_id;
+ (SmppPdu *)OutgoingDataSmRespErr:(SmppErrorCode) err messageId:(NSString *)msgid networkType:(SmppNetworkType)nt;
+ (SmppPdu *)OutgoingQuerySm;
+ (SmppPdu *)OutgoingQueryRespOK:(id<SmscConnectionMessageProtocol>)msg
						  withId:(NSString *)msg_id;
+ (SmppPdu *)OutgoingQuerySmRespErr:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingCancelSm;
+ (SmppPdu *)OutgoingCancelSmRespOK;
+ (SmppPdu *)OutgoingCancelSmRespErr:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingReplaceSm;
+ (SmppPdu *)OutgoingReplaceSmRespOK;
+ (SmppPdu *)OutgoingReplaceSmRespErr:(SmppErrorCode) err;
+ (SmppPdu *)OutgoingEnquireLink;
+ (SmppPdu *)OutgoingEnquireLinkResp;
+ (SmppPdu *)OutgoingAlertNotification:(UMSigAddr *)source
								  esme:(UMSigAddr *)esme;

+ (SmppPdu *)OutgoingBindRespError:(SmppErrorCode)err rx:(BOOL)rx tx:(BOOL)tx;
+ (SmppPdu *)OutgoingBindRespError:(SmppErrorCode)err rx:(BOOL)rx tx:(BOOL)tx status:(NSString *)status;
+ (SmppPdu *)OutgoingBindRespOK:(NSString *)systemId supportedVersion:(NSInteger)version rx:(BOOL)rx tx:(BOOL)tx;

- (void) appendNSStringMax:(NSString *)s  maxLength: (NSInteger) maxlen;
- (void) appendCStringMax:(const char *)s maxLength: (NSInteger) maxlen;
- (void) appendBytes:(const void *)bytes length: (NSUInteger) len;
- (void) appendByte:(unsigned char)byte;
- (void) appendTLVData:(NSData *)d withTag:(SMPP_TLV_Tag)tag;
- (void) appendTLVString:(NSString *)s withTag:(SMPP_TLV_Tag)tag;
- (void) appendTLVStringNullTerminated:(NSString *)s withTag:(SMPP_TLV_Tag)tag;
- (void) appendTLVByte:(unsigned char)byte withTag:(SMPP_TLV_Tag)tag;
- (void) appendTLVInt16:(u_int16_t)i withTag:(SMPP_TLV_Tag)tag;
- (void) appendTLVInt32:(u_int32_t)i withTag:(SMPP_TLV_Tag)tag;
- (void) appendTLVNetworkErrorCode:(u_int16_t)i networkType:(SmppNetworkType)nt withTag:(SMPP_TLV_Tag)tag;
- (void) appendDate:(NSDate *) date;
- (void) appendInt8:(NSInteger) i;
- (void) appendInt16:(NSInteger) i;
- (void) appendInt32:(NSInteger) i;
+ (SmppMessageState) messageState:(int)ms;

- (NSInteger)	grabInt8;
- (NSInteger)	grabInt16;
- (NSInteger)	grabInt24;
- (NSInteger)	grabInt32;
- (NSInteger)	grabInt:(long)len;
- (NSString *)  grabStringWithEncoding:(NSStringEncoding)encoding maxLength:(int)max;
- (NSData *)    grabOctetStringWithLength:(int)len;
- (void)        grabTlvsWithDefinitions:(NSDictionary *)tlvDefs;

- (void) resetCursor;

- (int)unpackDeliverSm;
- (int)unpackDeliverSmUsingTlvDefinition:(NSDictionary *)tlvDefs;

+ (NSString *)pduTypeToString:(SmppPduType)type;

+ (NSDate *)smppTimestampFromString:(NSString *)str;

@end
