//
//  SmppPdu.m
//  SMPP-SMPP
//
//  Created by Andreas Fink on 11.12.08.
//  Copyright 2008-2014 Andreas Fink, Paradieshofstrasse 101, 4054 Basel, Switzerland
//

#import "SmppPdu.h"
#import "ulib/ulib.h"
#import "NSData+HexFunctions.h"
#import "SmscConnectionSMPP.h"




@implementation SmppPdu
@synthesize pdulen;
@synthesize	type;
@synthesize	err;
@synthesize	seq;
@synthesize	payload;
@synthesize cursor;
@synthesize source_addr_ton;
@synthesize source_addr_npi;
@synthesize source_addr;
@synthesize destination_addr;
@synthesize dest_addr_ton;
@synthesize dest_addr_npi;
@synthesize service_type;
@synthesize receipted_message_id;
@synthesize esm_class;
@synthesize sm_length;
@synthesize short_message;
@synthesize data_coding;
@synthesize protocol_id;
@synthesize priority_flag;
@synthesize message_payload;
@synthesize tlv;
@synthesize message_id;
@synthesize replace_if_present_flag;
@synthesize dest_addr_subunit;
@synthesize source_addr_subunit;

- (SmppPdu *)init
{
    self = [super init];
    if(self)
    {
    }
    return self;
}

- (SmppPdu *)initWithType:(SmppPduType)t err:(SmppErrorCode)e;
{
    self = [super init];
    if(self)
    {
        pdulen     = 0;
        type	= t;
        err		= e;
        seq		= 0;
        cursor	= 0;
        payload = [[NSMutableData alloc] init];
    }
	return self;
}

- (SmppPdu *)initFromData:(NSData *)d;
{
	unsigned char header[16];
	unsigned char *ptr;
    
    self = [super init];
    if(self)
    {
        [d getBytes: header length:16];
        pdulen	= ((header[0] << 24) | (header[1] << 16) | (header[2] << 8) | (header[3]));
        type	= ((header[4] << 24) | (header[5] << 16) | (header[6] << 8) | (header[7]));
        err		= ((header[8] << 24) | (header[9] << 16) | (header[10] << 8) | (header[11]));
        seq		= ((header[12] << 24) | (header[13] << 16) | (header[14] << 8) | (header[15]));
        ptr = (unsigned char *) [d bytes];
        
        if(pdulen > 0)
        {
            payload = [[NSMutableData alloc] initWithBytes: &ptr[16] length:pdulen-16];
        }
        else
        {
            payload = [[NSMutableData alloc] init];
        }
        cursor	= 0;
        tlv = [[NSMutableDictionary alloc] init];
    }
	return self;
}



- (size_t)pdulen
{
    pdulen = 16 + [payload length];
    return pdulen;
}

- (SmppPdu *)initWithType:(SmppPduType)t
{
	return [self initWithType:t err:ESME_ROK];
}

- (void) appendNSStringMax:(NSString *)s  maxLength: (NSInteger) maxlen
{
	NSUInteger len;
	NSData *d;
    
    if(s == NULL)
    {
        d = [NSData data];
    }
    else
    {
        d = [s dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
    }
    len = [d length];
	if(len > (maxlen -1))
    {
		len = maxlen - 1;
    }
    [self appendBytes: (const void *) [d bytes] length: len];
	[self appendByte: '\0'];
}

- (void) appendTLVStringNullTerminated:(NSString *)s withTag:(SMPP_TLV_Tag)tag
{
    const char *c="";
    size_t len = 0;
    if(s!=NULL)
    {
        c = [s UTF8String];
        len = strlen(c);
    }
    NSData *d = [NSData dataWithBytes:c length:len+1];
    [self appendTLVData:d withTag:tag];
}

- (void) appendTLVString:(NSString *)s withTag:(SMPP_TLV_Tag)tag
{
    const char *c = [s UTF8String];
    if(s!=NULL)
    {
        size_t len = strlen(c);
        NSData *d = [NSData dataWithBytes:c length:len];
        [self appendTLVData:d withTag:tag];
    }
}

- (void) appendTLVData:(NSData *)d withTag:(SMPP_TLV_Tag)tag
{
	NSUInteger len;
	len = [d length];
	if(len > 0xFFFF)
		len = 0xFFFF;
    if(len>0)
    {
        [self appendInt16:tag];
        [self appendInt16:len];
        [self appendBytes: (const void *) [d bytes] length: len];
    }
}

- (void) appendTLVByte:(unsigned char)byte withTag:(SMPP_TLV_Tag)tag
{
	[self appendInt16:tag];
	[self appendInt16:1];
	[self appendByte: byte];
}

- (void) appendTLVInt16:(u_int16_t)i withTag:(SMPP_TLV_Tag)tag;
{
	[self appendInt16:tag];
	[self appendInt16: 2];
	[self appendInt16: i];
}

- (void) appendTLVInt32:(u_int32_t)i withTag:(SMPP_TLV_Tag)tag;
{
	[self appendInt16:tag];
	[self appendInt16: 4];
	[self appendInt32: i];
}

- (void) appendTLVNetworkErrorCode:(u_int16_t)i networkType:(SmppNetworkType)nt withTag:(SMPP_TLV_Tag)tag
{
	[self appendInt16:tag];
	[self appendInt16: 3];
	[self appendInt8: nt];
	[self appendInt16: i];
}

- (void) appendCStringMax:(const char *)s maxLength: (NSInteger) maxlen
{
	NSUInteger len;
	
	len = strlen(s);
	if(len > (maxlen-1))
		len = maxlen -1;
	[self appendBytes: (const void *) s length: len];
	[self appendByte: '\0'];
}

- (void) appendBytes:(const void *)bytes length: (NSUInteger) len
{
	[payload appendBytes: (const void *) bytes length: len];
}

- (void) appendByte:(unsigned char)byte
{
	[payload appendBytes: (const void *) &byte length: 1];
}

- (void) appendInt8:(NSInteger) i
{
	[self appendByte: (i & 0xFF)];
}

- (void) appendInt16:(NSInteger) i
{
	[self appendByte: ((i & 0x0000FF00) >> 8)];
	[self appendByte: ((i & 0x000000FF) >> 0)];
}

- (void) appendInt32:(NSInteger) i
{
	[self appendByte: ((i & 0xFF000000) >> 24)];
	[self appendByte: ((i & 0x00FF0000) >> 16)];
	[self appendByte: ((i & 0x0000FF00) >> 8)];
	[self appendByte: ((i & 0x000000FF) >> 0)];
}

+(NSDateFormatter *)smppDateFormatter
{
    static NSDateFormatter *_smppDateFormatter;
       
    if(_smppDateFormatter==NULL)
    {
        NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"UTC"];
        NSDateFormatter *sf= [[NSDateFormatter alloc]init];
        NSLocale *usLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
        [sf setLocale:usLocale];
        [sf setDateFormat:@"%y%m%d%H%M%S000+"];
        [sf setTimeZone:tz];
        _smppDateFormatter = sf;
    }
    return _smppDateFormatter;
}

- (void) appendDate:(NSDate *) date
{
	if (!date)
    {
		[self appendByte: 0];
    }
    // This is our zeroDate
    else if ([date isEqualToDate:[NSDate dateWithTimeIntervalSince1970:0]])
    {
        [self appendByte: 0];
    }
	else
	{
        NSDateFormatter *df = [SmppPdu smppDateFormatter];
        NSString *cd = [df stringFromDate:date];
		[self appendNSStringMax: [cd description] maxLength: 17];
	}
}

+ (SmppPdu *)OutgoingBindTransmitter:(NSString *)systemId
							password:(NSString *)password
						  systemType:(NSString *)stype
							 version:(NSInteger)version
								 ton:(NSInteger)ton
								 npi:(NSInteger)npi
							   range:(NSString *)range
{
	SmppPdu *pdu;
    
	pdu = [(SmppPdu *)[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSMITTER];
	[pdu appendNSStringMax:systemId maxLength:16];
	[pdu appendNSStringMax:password maxLength:9];
	[pdu appendNSStringMax:stype maxLength:13];
	[pdu appendInt8: version];
	[pdu appendInt8: ton];
	[pdu appendInt8: npi];
	[pdu appendNSStringMax: range maxLength:41];
	return pdu;
}


+ (SmppPdu *)OutgoingBindRespOK:(NSString *)systemId supportedVersion:(NSInteger)version rx:(BOOL)rx tx:(BOOL)tx
{
	if((rx==YES) && (tx==YES))
		return [self OutgoingBindTransceiverRespOK:systemId supportedVersion:version];
	if(rx==YES)
		return [self OutgoingBindReceiverRespOK:systemId supportedVersion:version];
	return [self OutgoingBindTransmitterRespOK:systemId supportedVersion:version];
}

+ (SmppPdu *)OutgoingBindRespError:(SmppErrorCode) err rx:(BOOL)rx tx:(BOOL)tx
{
    return [SmppPdu OutgoingBindRespError:err rx:rx tx:tx status:NULL];
}

+ (SmppPdu *)OutgoingBindRespError:(SmppErrorCode) err rx:(BOOL)rx tx:(BOOL)tx status:(NSString *)status_text
{
	if((rx==YES) && (tx==YES))
    {
        return [self OutgoingBindTransceiverRespError:err status:status_text];
    }
	if(rx==YES)
    {
		return [self OutgoingBindReceiverRespError:err status:status_text];
    }
	return [self OutgoingBindTransmitterRespError:err status:status_text];
}

+ (SmppPdu *)OutgoingBindTransmitterRespError:(SmppErrorCode) err
{
    return [SmppPdu OutgoingBindTransmitterRespError:err status:NULL];
}

+ (SmppPdu *)OutgoingBindTransmitterRespError:(SmppErrorCode) err status:(NSString *)status
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSMITTER_RESP err:err];
    if(status)
    {
        [pdu appendTLVString:status withTag: SMPP_TLV_ADDITIONAL_STATUS_INFO_TEXT];
    }
	return pdu;
}

+ (SmppPdu *)OutgoingBindTransmitterRespOK:(NSString *)systemId
						  supportedVersion:(NSInteger)version
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSMITTER_RESP err:ESME_ROK];
	[pdu appendNSStringMax:systemId maxLength: 16];
	[pdu appendTLVByte:0x34 withTag: SMPP_TLV_SC_INTERFACE_VERSION];
	return pdu;
}

+ (SmppPdu *)OutgoingBindReceiver:(NSString *)systemId
						 password:(NSString *)password
					   systemType:(NSString *)stype
						  version:(NSInteger)version
							  ton:(NSInteger)ton
							  npi:(NSInteger)npi
							range:(NSString *)range
{
	SmppPdu *pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_RECEIVER err:ESME_ROK];
	[pdu appendNSStringMax:systemId maxLength:16];
	[pdu appendNSStringMax:password maxLength:9];
	[pdu appendNSStringMax:stype    maxLength:13];
	[pdu appendInt8: version                  ];
	[pdu appendInt8: ton                      ];
	[pdu appendInt8: npi                      ];
	[pdu appendNSStringMax: range   maxLength:41];
	return pdu;
}


+ (SmppPdu *)OutgoingBindReceiverRespError:(SmppErrorCode) err
{
    return [SmppPdu OutgoingBindReceiverRespError:err status:NULL];
}

+ (SmppPdu *)OutgoingBindReceiverRespError:(SmppErrorCode) err status:(NSString *)status
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_RECEIVER_RESP err:err];
    if(status)
    {
        [pdu appendTLVString:status withTag: SMPP_TLV_ADDITIONAL_STATUS_INFO_TEXT];
    }
	return pdu;
}

+ (SmppPdu *)OutgoingBindReceiverRespOK:(NSString *)systemId
					   supportedVersion:(NSInteger)version
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_RECEIVER_RESP err:ESME_ROK];
	[pdu appendNSStringMax:systemId maxLength: 16];
	[pdu appendTLVByte:0x34 withTag: SMPP_TLV_SC_INTERFACE_VERSION];
	return pdu;
}

+ (SmppPdu *)OutgoingBindTransceiver:(NSString *)systemId
							password:(NSString *)password
						  systemType:(NSString *)stype
							 version:(NSInteger)version
								 ton:(NSInteger)ton
								 npi:(NSInteger)npi
							   range:(NSString *)range
{
	SmppPdu *pdu;
	pdu = [(SmppPdu *)[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSCEIVER];
	[pdu appendNSStringMax:systemId maxLength:16];
	[pdu appendNSStringMax:password maxLength:9];
	[pdu appendNSStringMax:stype    maxLength:13];
	[pdu appendInt8: version                  ];
	[pdu appendInt8: ton                      ];
	[pdu appendInt8: npi                      ];
	[pdu appendNSStringMax: range   maxLength:41];
	return pdu;
}

+ (SmppPdu *)OutgoingBindTransceiverRespError:(SmppErrorCode) err
{
    return [SmppPdu OutgoingBindTransceiverRespError:err status:NULL];
}
            
+ (SmppPdu *)OutgoingBindTransceiverRespError:(SmppErrorCode) err status:(NSString *)status
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSCEIVER_RESP err:err];
    if(status)
    {
        [pdu appendTLVString:status withTag: SMPP_TLV_ADDITIONAL_STATUS_INFO_TEXT];
    }
	return pdu;
}

+ (SmppPdu *)OutgoingBindTransceiverRespOK:(NSString *)systemId
						  supportedVersion:(NSInteger)version
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSCEIVER_RESP err:ESME_ROK];
	[pdu appendNSStringMax:systemId maxLength: 16];
	[pdu appendTLVByte:0x34 withTag: SMPP_TLV_SC_INTERFACE_VERSION];
	return pdu;
}

+ (SmppPdu *)OutgoingOutbind:(NSString *)systemId
					password:(NSString *)password
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_OUTBIND err:ESME_ROK];
	[pdu appendNSStringMax:systemId maxLength:16];
	[pdu appendNSStringMax:password maxLength:9];
	return pdu;
}

+ (SmppPdu *)OutgoingUnbind
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_UNBIND err:ESME_ROK];
	return pdu;
}

+ (SmppPdu *)OutgoingUnbindRespOK
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_UNBIND_RESP err:ESME_ROK];
	return pdu;
}

+ (SmppPdu *)OutgoingUnbindRespErr:(SmppErrorCode) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_UNBIND_RESP err:err];
	return pdu;
}

+ (SmppPdu *)OutgoingGenericNack:(SmppErrorCode) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_GENERIC_NACK err:err];
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg
{
    return [SmppPdu OutgoingSubmitSm:msg
                            esmClass:SMPP_PDU_ESM_CLASS_SUBMIT_DEFAULT_SMSC_MODE
                         serviceType:NULL
                             options:@{}];
}

+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg
                      options:(NSDictionary *)options
{
    if (options[@"CMT"])
    {
        return [SmppPdu OutgoingSubmitSm:msg
                                esmClass:SMPP_PDU_ESM_CLASS_SUBMIT_DEFAULT_SMSC_MODE
                             serviceType:@"CMT"
                                 options:options];
    }
    return [SmppPdu OutgoingSubmitSm:msg
                            esmClass:SMPP_PDU_ESM_CLASS_SUBMIT_DEFAULT_SMSC_MODE
                         serviceType:NULL
                             options:options];
}

+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype
{
    return [SmppPdu OutgoingSubmitSm:msg esmClass:esmclass serviceType:servicetype options:@{}];
}
        
+ (SmppPdu *)OutgoingSubmitSm:(id<SmscConnectionMessageProtocol>)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype options:(NSDictionary *)options
{
	SmppPdu *pdu;
	NSData *data;
	NSUInteger len;
	int use_message_payload;
	
	if ([msg pduUdhi])
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
    }
	if( [msg pduRp])
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
    }
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM err:ESME_ROK];
    
	[pdu appendNSStringMax:servicetype maxLength: 6];
	[pdu appendInt8: [[msg from] ton]];
	[pdu appendInt8:  [[msg from] npi]];
	[pdu appendNSStringMax: [[msg from] addr]  maxLength:21];
    
	[pdu appendInt8: [[msg to] ton]];
	[pdu appendInt8:  [[msg to] npi]];
	[pdu appendNSStringMax: [[msg to] addr]  maxLength:21];
	[pdu appendInt8:  esmclass]; //5.2.12
	[pdu appendInt8:  [msg pduPid]]; //5.2.13
	[pdu appendInt8:  [msg priority]]; //5.2.13
	[pdu appendDate:  [msg deferred]]; //scheduled time
	[pdu appendDate:  [msg validity]];
    //[pdu appendInt8:  [msg reportMask] ? 1 : 0];
    
    UMReportMaskValue reportMask = [msg reportMask];
    UMRequestMaskValue requestMask = 0;
    if (reportMask & (UMDLR_MASK_SUCCESS | UMDLR_MASK_FAIL))
    {
        requestMask |= REQUEST_MASK_SUCCESS_OR_FAIL;
    }
    else if (reportMask & UMDLR_MASK_FAIL)
    {
        requestMask |= REQUEST_MASK_FAIL;
    }
    if (reportMask & (UMDLR_MASK_BUFFERED | UMDLR_MASK_REPORT_ENROUTE))
    {
        requestMask |= REQUEST_MASK_INTERMEDIATE;
    }
    [pdu appendInt8:  requestMask];
    
	[pdu appendInt8:  [msg replaceIfPresentFlag]];
	[pdu appendInt8:  [msg pduDcs]];
	[pdu appendInt8:  0];	/* predefined message text */
	data = [msg pduContentIncludingUdh];
	
	len = [data length];
	if(len > 254)
	{
		use_message_payload = 1;
		[pdu appendInt8:  0];
	}
	else
	{
		use_message_payload = 0;
		[pdu appendInt8:  len];
		[pdu appendBytes:[data bytes] length:len];
	}
    
    //	if([msg msgid])
    //		[pdu appendTLVString:[msg msgid] withTag:SMPP_TLV_USER_MESSAGE_REFERENCE];
	if(use_message_payload)
    {
		[pdu appendTLVData:data withTag:SMPP_TLV_MESSAGE_PAYLOAD];
    }
    /*
     ADDITIONAL TLV'S POSSIBLE HERE:
     
     SMPP_TLV_SOURCE_PORT					= 0x020A,
     SMPP_TLV_SOURCE_ADDR_SUBUNIT			= 0x000D,
     SMPP_TLV_DESTINATION_PORT				= 0x020B,
     SMPP_TLV_DEST_ADDR_SUBUNIT				= 0x0005,
     SMPP_TLV_SAR_MSG_REF_NUM				= 0x020C,
     SMPP_TLV_SAR_TOTAL_SEGMENTS				= 0x020E,
     SMPP_TLV_SAR_SEGMENT_SEQNUM				= 0x020F,
     SMPP_TLV_MORE_MESSAGES_TO_SEND			= 0x0426,
     SMPP_TLV_PAYLOAD_TYPE					= 0x0019,
     SMPP_TLV_PRIVACY_INDICATOR				= 0x0201,
     SMPP_TLV_CALLBACK_NUM					= 0x0381,
     SMPP_TLV_CALLBACK_NUM_PRES_IND			= 0x0302,
     SMPP_TLV_CALLBACK_NUM_ATAG				= 0x0303,
     SMPP_TLV_SOURCE_SUBADDRESS				= 0x0202,
     SMPP_TLV_DEST_SUBADDRESS				= 0x0203,
     SMPP_TLV_USER_RESPONSE_CODE				= 0x0205,
     SMPP_TLV_DISPLAY_TIME					= 0x1201,
     SMPP_TLV_SMS_SIGNAL						= 0x1203,
     SMPP_TLV_MS_VALIDITY					= 0x1204,
     SMPP_TLV_MS_MSG_WAIT_FACILITIES			= 0x0030,
     SMPP_TLV_NUMBER_OF_MESSAGES				= 0x0304,
     SMPP_TLV_ALERT_ON_MESSAGE_DELIVERY		= 0x130C,
     SMPP_TLV_LANGUAGE_INDICATOR				= 0x020D,
     SMPP_TLV_ITS_REPLY_TYPE					= 0x1380,
     SMPP_TLV_ITS_SESSION_INFO				= 0x1383,
     SMPP_TLV_USSD_SERVICE_OP				= 0x0501,
     */
    if(options[@"set_smsc1"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(smsc1)])
        {
            NSString *smsc1 = [msg smsc1];
            if(smsc1)
            {
                [pdu appendTLVString:smsc1 withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC1];
            }
        }
    }
    if(options[@"set_smsc2"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(smsc2)])
        {
            NSString *smsc2 = [msg smsc2];
            if(smsc2)
            {
                [pdu appendTLVString:smsc2 withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC2];
            }
        }
    }
    if(options[@"set_smsc3"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(smsc3)])
        {
            NSString *smsc3 = [msg smsc3];
            if(smsc3)
            {
                [pdu appendTLVString:smsc3 withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC3];
            }
        }
    }
    if(options[@"set_opc1"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(opc1)])
        {
            NSString *opc1 = [msg opc1];
            if(opc1)
            {
                [pdu appendTLVString:opc1 withTag:SMPP_TLV_VENDOR_SPECIFIC_OPC1];
            }
        }
    }
    if(options[@"set_dpc1"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(dpc1)])
        {
            NSString *dpc1 = [msg dpc1];
            if(dpc1)
            {
                [pdu appendTLVString:dpc1 withTag:SMPP_TLV_VENDOR_SPECIFIC_DPC1];
            }
        }
    }
    if(options[@"set_opc2"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(opc2)])
        {
            NSString *opc2 = [msg opc2];
            if(opc2)
            {
                [pdu appendTLVString:opc2 withTag:SMPP_TLV_VENDOR_SPECIFIC_OPC2];
            }
        }
    }
    if(options[@"set_dpc2"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(dpc2)])
        {
            NSString *dpc2 = [msg dpc2];
            if(dpc2)
            {
                [pdu appendTLVString:dpc2 withTag:SMPP_TLV_VENDOR_SPECIFIC_DPC2];
            }
        }
    }
    if(options[@"set_userflags"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(userFlags)])
        {
            NSString *userflags = [msg userFlags];
            if(userflags)
            {
                [pdu appendTLVString:userflags withTag:SMPP_TLV_VENDOR_SPECIFIC_USERFLAGS];
            }
        }
    }
    if(options[@"set_msc"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(msc)])
        {
            NSString *msc = [msg msc];
            if(msc)
            {
                UMSigAddr *s = [UMSigAddr sigAddrFromString:msc];
                [pdu appendTLVByte:s.ton withTag:SMPP_TLV_VENDOR_SPECIFIC_MSC_TON];
                [pdu appendTLVByte:s.npi withTag:SMPP_TLV_VENDOR_SPECIFIC_MSC_NPI];
                [pdu appendTLVString:s.addr withTag:SMPP_TLV_VENDOR_SPECIFIC_MSC_ADDR];
            }
        }
    }
    if(options[@"set_hlr"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(hlr)])
        {
            NSString *hlr = [msg hlr];
            if(hlr)
            {
                UMSigAddr *s = [UMSigAddr sigAddrFromString:hlr];
                [pdu appendTLVByte:s.ton withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR_TON];
                [pdu appendTLVByte:s.npi withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR_NPI];
                [pdu appendTLVString:s.addr withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR_ADDR];
            }
            
        }
    }
    if(options[@"set_imsi"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(imsi)])
        {
            NSString *imsi = [msg imsi];
            if(imsi)
            {
                [pdu appendTLVString:imsi withTag:SMPP_TLV_VENDOR_SPECIFIC_IMSI];
            }
        }
    }
    if(options[@"set_mcc"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(mcc)])
        {
            NSString *mcc = [msg mcc];
            if(mcc)
            {
                [pdu appendTLVString:mcc withTag:SMPP_TLV_VENDOR_SPECIFIC_MCC];
            }
        }
    }
    if(options[@"set_mnc"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(mnc)])
        {
            NSString *mnc = [msg mnc];
            if(mnc)
            {
                [pdu appendTLVString:mnc withTag:SMPP_TLV_VENDOR_SPECIFIC_MNC];
            }
        }
    }
    if(options[@"set_method"] || options[@"messagemover"])
    {
        if([msg respondsToSelector:@selector(method)])
        {
             NSString *method = [msg method];
            if(method)
            {
                [pdu appendTLVString:method withTag:SMPP_TLV_VENDOR_SPECIFIC_DELIVERY_METHOD];
            }
            else
            {
                [pdu appendTLVString:@"mt" withTag:SMPP_TLV_VENDOR_SPECIFIC_DELIVERY_METHOD];
            }
        }
        else
        {
            [pdu appendTLVString:@"mt" withTag:SMPP_TLV_VENDOR_SPECIFIC_DELIVERY_METHOD];
        }
    }
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitSmRespOK:(id<SmscConnectionMessageProtocol>)msg
							 withId:(NSString *)msgId
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_RESP err:ESME_ROK];
	// TODO: verify if id is better a NSData
	[pdu appendNSStringMax:msgId maxLength: 65];
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitSmRespErr:(SmppErrorCode) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_RESP err:err];
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitMulti:(id<SmscConnectionMessageProtocol>)msg distributionList:(NSString *) distributionListName
{
	SmppPdu *pdu;
	int	esmclass = 0;
	NSData *data;
	NSUInteger len;
	int use_message_payload;
    
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_MULTI err:ESME_ROK];
    
	esmclass = SMPP_PDU_ESM_CLASS_SUBMIT_STORE_AND_FORWARD_MODE;
	if ( [msg pduUdhi] )
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
	if( [msg pduRp] )
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
	
	
    [pdu appendNSStringMax:@"" maxLength: 6]; // service type default
	[pdu appendInt8: [[msg from] ton]];
	[pdu appendInt8:  [[msg from] npi]];
	[pdu appendNSStringMax: [[msg from] addr]  maxLength:21];
	[pdu appendInt8: 1]; /* number of destination addresses */
	[pdu appendInt8: 2]; /* 2 = distribution list name, 1 = SME destination */
	[pdu appendNSStringMax: distributionListName   maxLength:21];
	[pdu appendInt8:  esmclass]; //5.2.12
	[pdu appendInt8:  [msg pduPid]]; //5.2.13
	[pdu appendInt8:  [msg priority]]; //5.2.13
	[pdu appendDate:  [msg deferred]]; //scheduled time
	[pdu appendDate:  [msg validity]];
	[pdu appendInt8:  [msg reportMask] ? 1 : 0];
	[pdu appendInt8:  [msg replaceIfPresentFlag]];
	[pdu appendInt8:  [msg pduDcs]];
	[pdu appendInt8:  0];	/* predefined message text */
	data = [msg pduContentIncludingUdh];
	
	len = [data length];
	if(len > 254)
	{
		use_message_payload = 1;
		[pdu appendInt8:  0];
	}
	else
	{
		use_message_payload = 0;
		[pdu appendInt8:  len];
		[pdu appendBytes:[data bytes] length:len];
	}
	
	if([msg routerReference])
    {
		[pdu appendTLVString:[msg routerReference] withTag:SMPP_TLV_USER_MESSAGE_REFERENCE];
    }
	if(use_message_payload)
    {
		[pdu appendTLVData:data withTag:SMPP_TLV_MESSAGE_PAYLOAD];
	}
    /*
	 ADDITIONAL TLV'S POSSIBLE HERE:
	 
	 SMPP_TLV_SOURCE_PORT					= 0x020A,
	 SMPP_TLV_SOURCE_ADDR_SUBUNIT			= 0x000D,
	 SMPP_TLV_DESTINATION_PORT				= 0x020B,
	 SMPP_TLV_DEST_ADDR_SUBUNIT				= 0x0005,
	 SMPP_TLV_SAR_MSG_REF_NUM				= 0x020C,
	 SMPP_TLV_SAR_TOTAL_SEGMENTS				= 0x020E,
	 SMPP_TLV_SAR_SEGMENT_SEQNUM				= 0x020F,
	 SMPP_TLV_MORE_MESSAGES_TO_SEND			= 0x0426,
	 SMPP_TLV_PAYLOAD_TYPE					= 0x0019,
	 SMPP_TLV_PRIVACY_INDICATOR				= 0x0201,
	 SMPP_TLV_CALLBACK_NUM					= 0x0381,
	 SMPP_TLV_CALLBACK_NUM_PRES_IND			= 0x0302,
	 SMPP_TLV_CALLBACK_NUM_ATAG				= 0x0303,
	 SMPP_TLV_SOURCE_SUBADDRESS				= 0x0202,
	 SMPP_TLV_DEST_SUBADDRESS				= 0x0203,
	 SMPP_TLV_USER_RESPONSE_CODE				= 0x0205,
	 SMPP_TLV_DISPLAY_TIME					= 0x1201,
	 SMPP_TLV_SMS_SIGNAL						= 0x1203,
	 SMPP_TLV_MS_VALIDITY					= 0x1204,
	 SMPP_TLV_MS_MSG_WAIT_FACILITIES			= 0x0030,
	 SMPP_TLV_NUMBER_OF_MESSAGES				= 0x0304,
	 SMPP_TLV_ALERT_ON_MESSAGE_DELIVERY		= 0x130C,
	 SMPP_TLV_LANGUAGE_INDICATOR				= 0x020D,
	 SMPP_TLV_ITS_REPLY_TYPE					= 0x1380,
	 SMPP_TLV_ITS_SESSION_INFO				= 0x1383,
	 SMPP_TLV_USSD_SERVICE_OP				= 0x0501,
	 */
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitMultiRespOK:(NSArray *)unsuccessfulDeliveries /* array of  SmppMultiResult */
								withId:(NSString *)msgid
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_MULTI err:ESME_ROK];
	// TODO: what about message ID?
	[pdu appendNSStringMax: msgid  maxLength:65];
	[pdu appendInt8: [unsuccessfulDeliveries count]];
	for ( SmppMultiResult *result in unsuccessfulDeliveries)
	{
		[pdu appendInt8: [[result dst] ton]];
		[pdu appendInt8: [[result dst] npi]];
		[pdu appendNSStringMax: [[result dst] addr]  maxLength:21];
		[pdu appendInt32: [result err]];
	}
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitMultiRespErr:(SmppErrorCode) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] init];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg
{
	return [SmppPdu OutgoingDeliverSm:msg esmClass:SMPP_PDU_ESM_CLASS_DELIVER_DEFAULT_TYPE serviceType:NULL];
}

+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg options:(NSDictionary *)options
{
    return [SmppPdu OutgoingDeliverSm:msg esmClass:SMPP_PDU_ESM_CLASS_DELIVER_DEFAULT_TYPE serviceType:NULL options:options];
}

+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype
{
    return [SmppPdu OutgoingDeliverSm:msg
                             esmClass:esmclass
                          serviceType:servicetype
                              options:@{}];
}

+ (SmppPdu *)OutgoingDeliverSm:(id<SmscConnectionMessageProtocol>)msg
                      esmClass:(int)esmclass
                   serviceType:(NSString *)servicetype
                       options:(NSDictionary *)options;
{
	SmppPdu *pdu;
	NSData *data;
	NSUInteger len;
	int use_message_payload;
	int	we_are_delivery_report;
    
	if(esmclass & (SMPP_PDU_ESM_CLASS_DELIVER_SMSC_DELIVER_ACK |  SMPP_PDU_ESM_CLASS_DELIVER_SME_DELIVER_ACK | SMPP_PDU_ESM_CLASS_DELIVER_SME_MANULAL_ACK))
    {
		we_are_delivery_report = 1;
    }
    else
    {
        we_are_delivery_report = 0;
    }
	if ( [msg pduUdhi])
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
    }
    if( [msg pduRp])
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
    }
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM err:ESME_ROK];
	
	[pdu appendNSStringMax:servicetype maxLength: 6];
	if(we_are_delivery_report)
	{ /* the generator of the deliver report is in charge of swappign sender/receiver */
		[pdu appendInt8: [[msg from] ton]];
        [pdu appendInt8:  [[msg from] npi]];
        [pdu appendNSStringMax: [[msg from] addr]  maxLength:21];
        [pdu appendInt8: [[msg to] ton]];
        [pdu appendInt8:  [[msg to] npi]];
        [pdu appendNSStringMax: [[msg to] addr]  maxLength:21];
    }
	else
	{
		[pdu appendInt8: [[msg from] ton]];
		[pdu appendInt8:  [[msg from] npi]];
		[pdu appendNSStringMax: [[msg from] addr]  maxLength:21];
		[pdu appendInt8: [[msg to] ton]];
		[pdu appendInt8:  [[msg to] npi]];
		[pdu appendNSStringMax: [[msg to] addr]  maxLength:21];
	}
	[pdu appendInt8:  esmclass];
	[pdu appendInt8:  [msg pduPid]];
	[pdu appendInt8:  [msg priority]];
	[pdu appendDate:  [msg deferred]];
	[pdu appendDate:  [msg validity]];
	[pdu appendInt8:  [msg reportMask] ? 1 : 0];
	[pdu appendInt8:  [msg replaceIfPresentFlag]];
	[pdu appendInt8:  [msg pduDcs]];
	[pdu appendInt8:  0];	/* predefined message text must be NULL for deliver SM */
	if(we_are_delivery_report)
	{
		NSString *ms;
		NSString *reportText;
        NSInteger type = [msg messageStateCode];
		switch(type)
		{
			case MESSAGE_STATE_ENROUTE:
                ms = @"ENROUTE";
				break;
			case MESSAGE_STATE_ACCEPTED:
				ms = @"ACCEPTD";
				break;
			case MESSAGE_STATE_DELIVERED:
				ms = @"DELIVRD";
				break;
			case MESSAGE_STATE_EXPIRED:
                ms = @"EXPIRED";
				break;
			case MESSAGE_STATE_DELETED:
                ms = @"DELETED";
				break;
			case MESSAGE_STATE_UNDELIVERABLE:
                ms = @"UNDELIV";
				break;
			case MESSAGE_STATE_REJECTED:
				ms = @"REJECTD";
				break;
			case MESSAGE_STATE_UNKNOWN:
			default:
				ms = @"UNKNOWN";
		}
        
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMddHHmmss"];
        
		reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:%@ err:%d text:Report",
					  [msg routerReference],
					  [msg submitDate] ? [formatter stringFromDate:[msg submitDate]]:[formatter stringFromDate:[NSDate date]],
					  [msg attemptedDate] ? [formatter stringFromDate:[msg attemptedDate]]:[formatter stringFromDate:[NSDate date]],
					  ms,
					  [msg networkErrorCode]];
		data = [reportText dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
	}
	else
	{
		data = [msg pduContentIncludingUdh];
	}
	len = [data length];
	if(len > 254)
	{
		use_message_payload = 1;
		[pdu appendInt8:  0];
	}
	else
	{
		use_message_payload = 0;
		[pdu appendInt8:  len];
		[pdu appendBytes:[data bytes] length:len];
	}
	
	if(use_message_payload)
    {
		[pdu appendTLVData:data withTag:SMPP_TLV_MESSAGE_PAYLOAD];
	}
	if(we_are_delivery_report)
	{
		/* we are a delivery report */
		if([[msg userMessageReference]length]==2)
        {
			[pdu appendTLVData:[msg userMessageReference] withTag:SMPP_TLV_USER_MESSAGE_REFERENCE];
        }
		[pdu appendTLVStringNullTerminated:[msg routerReference] withTag:SMPP_TLV_RECEIPTED_MESSAGE_ID];
        [pdu appendTLVNetworkErrorCode:[msg networkErrorCode] networkType:SMPP_NETWORK_TYPE_GSM  withTag:SMPP_TLV_NETWORK_ERROR_CODE];
		[pdu appendTLVByte: [SmppPdu messageState:[msg messageStateCode]] withTag: SMPP_TLV_MESSAGE_STATE];
	}
	/*
	 ADDITIONAL TLV'S POSSIBLE HERE:
	 
	 SMPP_TLV_SOURCE_PORT					= 0x020A,
	 SMPP_TLV_SOURCE_ADDR_SUBUNIT			= 0x000D,
	 SMPP_TLV_DESTINATION_PORT				= 0x020B,
	 SMPP_TLV_DEST_ADDR_SUBUNIT				= 0x0005,
	 SMPP_TLV_SAR_MSG_REF_NUM				= 0x020C,
	 SMPP_TLV_SAR_TOTAL_SEGMENTS			= 0x020E,
	 SMPP_TLV_SAR_SEGMENT_SEQNUM			= 0x020F,
	 SMPP_TLV_MORE_MESSAGES_TO_SEND			= 0x0426,
	 SMPP_TLV_PRIVACY_INDICATOR				= 0x0201,
	 SMPP_TLV_PAYLOAD_TYPE					= 0x0019,
	 SMPP_TLV_CALLBACK_NUM					= 0x0381,
	 SMPP_TLV_SOURCE_SUBADDRESS				= 0x0202,
	 SMPP_TLV_DEST_SUBADDRESS				= 0x0203,
	 SMPP_TLV_USER_RESPONSE_CODE				= 0x0205,
	 SMPP_TLV_DISPLAY_TIME					= 0x1201,
	 SMPP_TLV_SMS_SIGNAL						= 0x1203,
	 SMPP_TLV_MS_VALIDITY					= 0x1204,
	 SMPP_TLV_MS_MSG_WAIT_FACILITIES			= 0x0030,
	 SMPP_TLV_NUMBER_OF_MESSAGES				= 0x0304,
	 SMPP_TLV_ALERT_ON_MESSAGE_DELIVERY		= 0x130C,
	 SMPP_TLV_LANGUAGE_INDICATOR				= 0x020D,
	 SMPP_TLV_ITS_REPLY_TYPE					= 0x1380,
	 SMPP_TLV_ITS_SESSION_INFO				= 0x1383,
	 SMPP_TLV_USSD_SERVICE_OP				= 0x0501,
	 */
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitSmReport:(id<SmscConnectionMessageProtocol>)msg
                    reportingEntity:(SmppReportingEntity)re
{
    int esmclass;
    switch(re)
    {
        case SMPP_REPORTING_ENTITY_SMSC:
            esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SMSC_DELIVER_ACK;
            break;
        case SMPP_REPORTING_ENTITY_HANDSET:
            esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SME_DELIVER_ACK;
            break;
        case SMPP_REPORTING_ENTITY_MANUAL:
            esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SME_MANULAL_ACK;
            break;
        default:
            esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SMSC_DELIVER_ACK;
    }
    return [SmppPdu OutgoingSubmitSm:msg
                            esmClass:esmclass
                         serviceType:@""];
}

+ (SmppPdu *)OutgoingDeliverSmReport:(id<SmscConnectionMessageProtocol>)msg
                     reportingEntity:(SmppReportingEntity)re
{
	int esmclass;
	switch(re)
	{
		case SMPP_REPORTING_ENTITY_SMSC:
			esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SMSC_DELIVER_ACK;
			break;
		case SMPP_REPORTING_ENTITY_HANDSET:
			esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SME_DELIVER_ACK;
			break;
		case SMPP_REPORTING_ENTITY_MANUAL:
			esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SME_MANULAL_ACK;
			break;
		default:
			esmclass = SMPP_PDU_ESM_CLASS_DELIVER_SMSC_DELIVER_ACK;
	}
	return [SmppPdu OutgoingDeliverSm:msg
                             esmClass:esmclass
                          serviceType:@""];
}

+ (SmppPdu *)OutgoingDeliverSmRespOK:(id<SmscConnectionMessageProtocol>)msg
							  withId:(NSString *)msg_id
{
	SmppPdu *pdu;
    
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM_RESP err:ESME_ROK];
//    [pdu appendNSStringMax: msg_id maxLength:65];
    [pdu appendNSStringMax: @"" maxLength:65];
	return pdu;
}

+ (SmppPdu *)OutgoingDeliverSmRespErr:(SmppErrorCode) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM_RESP err:err];
	[pdu appendNSStringMax: @"" maxLength:1];
	return pdu;
}

+ (SmppPdu *)OutgoingDeliverSmReportRespOK:(id<SmscConnectionReportProtocol>)report
                                    withId:(NSString *)submit_id
{
	SmppPdu *pdu;
    
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM_RESP err:ESME_ROK];
    //    [pdu appendNSStringMax: submit_id maxLength:65];
    [pdu appendNSStringMax: @"" maxLength:65];
	return pdu;
}


+ (SmppPdu *)OutgoingDataSm:(id<SmscConnectionMessageProtocol>)msg
{
	return [SmppPdu OutgoingDataSm:msg esmClass:SMPP_PDU_ESM_CLASS_SUBMIT_DEFAULT_SMSC_MODE serviceType:@""];
}

+ (SmppPdu *)OutgoingDataSm:(id<SmscConnectionMessageProtocol>)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype
{
	SmppPdu *pdu;
	NSData *data;
	NSUInteger len;
	int use_message_payload;
	
	if ( [msg pduUdhi])
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
	if( [msg pduRp])
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
	
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DATA_SM err:ESME_ROK];
	
	[pdu appendNSStringMax:servicetype maxLength: 6];
	[pdu appendInt8: [[msg from] ton]];
	[pdu appendInt8:  [[msg from] npi]];
	[pdu appendNSStringMax: [[msg from] addr]  maxLength:65];
	
	[pdu appendInt8: [[msg to] ton]];
	[pdu appendInt8:  [[msg to] npi]];
	[pdu appendNSStringMax: [[msg to] addr]  maxLength:65];
	[pdu appendInt8:  esmclass]; //5.2.12
	[pdu appendInt8:  [msg reportMask] ? 1 : 0];
	[pdu appendInt8:  [msg pduDcs]];
    
	data = [msg pduContentIncludingUdh];
	
	len = [data length];
	if(len > 254)
	{
		use_message_payload = 1;
		[pdu appendInt8:  0];
	}
	else
	{
		use_message_payload = 0;
		[pdu appendInt8:  len];
		[pdu appendBytes:[data bytes] length:len];
	}
	
	if([msg routerReference])
    {
		[pdu appendTLVString:[msg routerReference] withTag:SMPP_TLV_USER_MESSAGE_REFERENCE];
    }
	if(use_message_payload)
    {
		[pdu appendTLVData:data withTag:SMPP_TLV_MESSAGE_PAYLOAD];
    }
	/*
	 ADDITIONAL TLV'S POSSIBLE HERE:
	 
	 SMPP_TLV_SOURCE_PORT					= 0x020A,
	 SMPP_TLV_SOURCE_ADDR_SUBUNIT			= 0x000D,
	 SMPP_TLV_SOURCE_NETWORK_TYPE			= 0x000E,
	 SMPP_TLV_SOURCE_BEARER_TYPE				= 0x000F,
	 SMPP_TLV_SOURCE_TELEMATICS_ID			= 0x0010,
     
	 SMPP_TLV_DESTINATION_PORT				= 0x020B,
	 SMPP_TLV_DEST_ADDR_SUBUNIT				= 0x0005,
	 SMPP_TLV_DEST_NETWORK_TYPE				= 0x0006,
	 SMPP_TLV_DEST_BEARER_TYPE				= 0x0007,
	 SMPP_TLV_DEST_TELEMATICS_ID				= 0x0008,
	 SMPP_TLV_SAR_TOTAL_SEGMENTS				= 0x020E,
	 SMPP_TLV_SAR_SEGMENT_SEQNUM				= 0x020F,
	 SMPP_TLV_SAR_MSG_REF_NUM				= 0x020C,
	 SMPP_TLV_QOS_TIME_TO_LIVE				= 0x0017,
	 SMPP_TLV_PAYLOAD_TYPE					= 0x0019,
	 SMPP_TLV_SET_DPF						= 0x0421,
     
	 SMPP_TLV_USER_MESSAGE_REFERENCE			= 0x0204,
     
	 */
	return pdu;
}


+ (SmppPdu *)OutgoingDataSmRespOK:(id<SmscConnectionMessageProtocol>)msg
                           withId:(NSString *)msgId
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DATA_SM_RESP err:ESME_ROK];
	// TODO: verify if id is better a NSData
	[pdu appendNSStringMax:msgId maxLength: 65];
	return pdu;
}

+ (SmppPdu *)OutgoingDataSmRespErr:(SmppErrorCode) err messageId:(NSString *)msgid networkType:(SmppNetworkType)nt
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DATA_SM_RESP err:ESME_ROK];
	// TODO: verify if id is better a NSData
	[pdu appendNSStringMax:msgid maxLength: 65];
	[pdu appendTLVNetworkErrorCode:err networkType:nt withTag:SMPP_TLV_NETWORK_ERROR_CODE];
	return pdu;
}

+ (SmppPdu *)OutgoingQuerySm
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_QUERY_SM err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingQueryRespOK:(id<SmscConnectionMessageProtocol>)msg
						  withId:(NSString *)msg_id
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_QUERY_SM_RESP err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingQuerySmRespErr:(SmppErrorCode) err
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_QUERY_SM_RESP err:err];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingCancelSm
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_CANCEL_SM err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingCancelSmRespOK
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_CANCEL_SM_RESP err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingCancelSmRespErr:(SmppErrorCode) err
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_CANCEL_SM_RESP err:err];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingReplaceSm
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_REPLACE_SM err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingReplaceSmRespOK
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_REPLACE_SM_RESP err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingReplaceSmRespErr:(SmppErrorCode) err
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_REPLACE_SM_RESP err:err];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingEnquireLink
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_ENQUIRE_LINK err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingEnquireLinkResp
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_ENQUIRE_LINK_RESP err:ESME_ROK];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingAlertNotification:(UMSigAddr *)source
								  esme:(UMSigAddr *)esme
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] init];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppMessageState) messageState:(int)ms
{
	switch(ms)
	{
		case MESSAGE_STATE_ENROUTE:
			return SMPP_MESSAGE_STATE_ENROUTE;
		case MESSAGE_STATE_DELIVERED:
			return SMPP_MESSAGE_STATE_DELIVERED;
		case MESSAGE_STATE_EXPIRED:
			return SMPP_MESSAGE_STATE_EXPIRED;
		case MESSAGE_STATE_DELETED:
			return SMPP_MESSAGE_STATE_DELETED;
		case MESSAGE_STATE_UNDELIVERABLE:
			return SMPP_MESSAGE_STATE_UNDELIVERABLE;
		case MESSAGE_STATE_ACCEPTED:
			return SMPP_MESSAGE_STATE_ACCEPTED;
		case MESSAGE_STATE_REJECTED:
			return SMPP_MESSAGE_STATE_REJECTED;
	}
	return SMPP_MESSAGE_STATE_UNKNOWN;
}


+(uint8_t)	grabInt8:(NSData *)data position:(int *)pos
{
	int i;
	unsigned const char *d;
	
	d = [data bytes];
	
	if( (*pos+sizeof(uint8_t)) > [data length])
		return 0;
	
	i = d[*pos];
	(*pos)++;
	return i;
}


-(NSInteger)	grabInt8
{
	uint32_t i;
	
	unsigned const char *d;
	
	d = [payload bytes];
	
	if( (cursor+sizeof(uint8_t)) > [payload length])
		return 0;
	
	i = d[cursor++];
	return i;
}

-(NSInteger)	grabInt16
{
	uint32_t i;
	uint32_t i1;
	uint32_t i2;
	
	unsigned const char *d;
	
	d = [payload bytes];
	
	if( (cursor+sizeof(uint16_t)) > [payload length])
		return 0;
	
	i1 = d[cursor++];
	i2 = d[cursor++];
	i = (i1 << 8) | i2;
	return i;
}

-(NSInteger)	grabInt24
{
	uint32_t i;
	uint32_t i1;
	uint32_t i2;
    uint32_t i3;
	
	unsigned const char *d;
	
	d = [payload bytes];
	
	if( (cursor+sizeof(uint16_t) + 8) > [payload length])
		return 0;
	
	i1 = d[cursor++];
	i2 = d[cursor++];
    i3 = d[cursor++];
	i = (i1 << 16) | (i2 << 8) | i3;
	return i;
}


-(NSInteger)	grabInt32
{
	uint32_t i;
	uint32_t i1;
	uint32_t i2;
	uint32_t i3;
	uint32_t i4;
	
	unsigned const char *d;
	
	d = [payload bytes];
	
	if( (cursor+sizeof(uint32_t)) > [payload length])
		return 0;
    
	i1 = d[cursor++];
	i2 = d[cursor++];
	i3 = d[cursor++];
	i4 = d[cursor++];
	i = (i1 << 24) | (i2 << 16) | (i3 << 8) | i4;
	return i;
}

-(NSInteger)	grabInt:(long)len
{
    long i;
    
    if (len == 1)
        i = [self grabInt8];
    else if (len == 2)
        i = [self grabInt16];
    else if (len == 3)
        i = [self grabInt24];
    else if (len == 4)
        i = [self grabInt32];
    else
        i = -1;
    
    return i;
}

-(NSString *)grabStringWithEncoding:(NSStringEncoding)enc maxLength:(int)max
{
	NSString *s;
	unsigned const char *in_string;
	int len;
    
    if(payload==NULL)
	{
        return @"";
	}
	if(cursor >= [payload length])
    {
        return @"";
    }
	in_string = & ((unsigned char *)[payload bytes])[cursor];
	for(len=0;len<max;len++)
    {
		if(in_string[len] == '\0')
		{
			break;
		}
        ++cursor;
    }
    ++cursor;        /* \0 */
	s = [[NSString alloc] initWithBytes:in_string length:len encoding:enc];
	return s;
}

-(NSData *)grabOctetStringWithLength:(int)len
{
    unsigned const char *in_string;
    NSData *d;
    
    in_string = & ((unsigned char *)[payload bytes])[cursor];
    cursor += len;
    d = [[NSData alloc] initWithBytes:in_string length:len];
    
    return d;
}

- (void) resetCursor
{
	cursor = 0;
}

- (int)unpackDeliverSm
{
    return [self unpackDeliverSmUsingTlvDefinition:nil];
}

- (int)unpackDeliverSmUsingTlvDefinition:(NSDictionary *)tlvDefs;
{
    service_type = [self grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:255];
	source_addr_ton  = [self grabInt8];
	source_addr_npi  = [self grabInt8];
	source_addr = [self grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:40];
	dest_addr_ton  = [self grabInt8];
	dest_addr_npi  = [self grabInt8];
	destination_addr = [self grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:31];
	esm_class = (int)[self grabInt8];
    protocol_id = [self grabInt8];
    priority_flag = [self grabInt8];
    schedule_delivery_time = [self grabStringWithEncoding:NSUTF8StringEncoding maxLength:17];
    validity_period = [self grabStringWithEncoding:NSUTF8StringEncoding maxLength:17];
    registered_delivery = [self grabInt8];
    replace_if_present_flag = [self grabInt8];
    data_coding = [self grabInt8];
    sm_default_msg_id = [self grabInt8];;
    sm_length = [self grabInt8];
    short_message = [self grabOctetStringWithLength:(int)sm_length];
    
    if (sm_length != [short_message length])
    {
        return -1;
    }
    [self grabTlvsWithDefinitions:tlvDefs];
    return 0;
}

- (void) grabTlvsWithDefinitions:(NSDictionary *)tlvDefs
{
    if(tlv == NULL)
    {
        tlv = [[NSMutableDictionary alloc]init];
    }
    int len = (int)[payload length];
    id  val;
    
    while (cursor + 4 < len)
    {
        unsigned long opt_len;
        SMPP_TLV_Tag opt_tag;
        opt_tag = (SMPP_TLV_Tag)[self grabInt16];
        opt_len = [self grabInt16];
        
        if (opt_tag == SMPP_TLV_USER_MESSAGE_REFERENCE)
        {
            if (opt_len > 2)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            user_message_reference = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", user_message_reference];
            tlv[@"user message reference"] = val;
        }
        else if (opt_tag == SMPP_TLV_SOURCE_PORT)
        {
            if (opt_len > 2)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            source_port = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", source_port];
            tlv[@"source port"] = val;
        }
        else if (opt_tag == SMPP_TLV_DESTINATION_PORT)
        {
            if (opt_len > 2)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            destination_port = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", destination_port];
            tlv[@"destination port"] = val;
        }
        else if (opt_tag == SMPP_TLV_SAR_MSG_REF_NUM)
        {
            if (opt_len > 2)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            sar_msg_ref_num = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", sar_msg_ref_num];
            tlv[@"sar msg ref num"] = val;
        }
        else if (opt_tag == SMPP_TLV_SAR_TOTAL_SEGMENTS)
        {
            if (opt_len > 1)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            sar_total_segments = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", sar_total_segments];
            tlv[@"sar total segments"] = val;
        }
        else if (opt_tag == SMPP_TLV_SAR_SEGMENT_SEQNUM)
        {
            if (opt_len > 1)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            sar_segment_seqnum = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", sar_segment_seqnum];
            tlv[@"sar segement seqnum"] = val;
        }
        else if (opt_tag == SMPP_TLV_USER_RESPONSE_CODE)
        {
            if (opt_len > 1)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            user_response_code = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", user_response_code];
            tlv[@"user response code"] = val;
        }
        else if (opt_tag == SMPP_TLV_PRIVACY_INDICATOR)
        {
            if (opt_len > 1)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            privacy_indicator = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", privacy_indicator];
            tlv[@"privacy indicator"] = val;
        }
        else if (opt_tag == SMPP_TLV_PAYLOAD_TYPE)
        {
            if (opt_len > 1)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            payload_type = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", payload_type];
            tlv[@"payload type"] = val;
        }
        else if (opt_tag == SMPP_TLV_MESSAGE_PAYLOAD)
        {
            if (opt_len > 65536 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            message_payload = [self grabOctetStringWithLength:(int)opt_len];
            tlv[@"message payload"] = message_payload;
        }
        else if (opt_tag == SMPP_TLV_CALLBACK_NUM)
        {
            if (opt_len < 4 || opt_len > 19 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            callback_num = [self grabOctetStringWithLength:(int)opt_len];
            tlv[@"callback num"] = callback_num;
        }
        else if (opt_tag == SMPP_TLV_SOURCE_SUBADDRESS)
        {
            if (opt_len < 2 || opt_len > 23 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            source_subaddress = [self grabOctetStringWithLength:(int)opt_len];
            tlv[@"source subaddress"] = source_subaddress;
        }
        else if (opt_tag == SMPP_TLV_DEST_SUBADDRESS)
        {
            if (opt_len < 2 || opt_len > 23 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            dest_subaddress = [self grabOctetStringWithLength:(int)opt_len];
            tlv[@"dest subaddress"] = dest_subaddress;
        }
        else if (opt_tag == SMPP_TLV_SOURCE_ADDR_SUBUNIT)
        {
            if (opt_len < 1 || opt_len > 1 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            source_addr_subunit = [self grabInt:(int)opt_len];
            tlv[@"source subunit"] = @(source_addr_subunit);
        }

        else if (opt_tag == SMPP_TLV_DEST_ADDR_SUBUNIT)
        {
            if (opt_len < 1 || opt_len > 1 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            dest_addr_subunit = [self grabInt:(int)opt_len];
            tlv[@"dest subunit"] = @(dest_addr_subunit);
        }

        else if (opt_tag == SMPP_TLV_LANGUAGE_INDICATOR)
        {
            if (opt_len > 1)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            language_indicator = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", language_indicator];
            tlv[@"language indicator"] = val;
        }
        else if (opt_tag == SMPP_TLV_ITS_SESSION_INFO)
        {
            if (opt_len < 2 || opt_len > 2 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            its_session_info = [self grabOctetStringWithLength:(int)opt_len];
            if (tlv)
                tlv[@"its session info"] = its_session_info;
        }
        else if (opt_tag == SMPP_TLV_NETWORK_ERROR_CODE)
        {
            if (opt_len < 3 || opt_len > 3 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            network_error_code = [self grabOctetStringWithLength:(int)opt_len];
            if (tlv)
                tlv[@"network error code"] = network_error_code;
        }
        else if (opt_tag == SMPP_TLV_MESSAGE_STATE)
        {
            if (opt_len > 1)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            message_state = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", message_state];
            if (tlv)
                tlv[@"message state"] = val;
        }
        else if (opt_tag == SMPP_TLV_RECEIPTED_MESSAGE_ID)
        {
            if (opt_len > 65 || cursor + opt_len > len)
            {
                [self setCursor:[self cursor] + (int)opt_len];
                continue;
            }
            receipted_message_id = [self grabStringWithEncoding:NSUTF8StringEncoding maxLength:(int)opt_len];
            if (tlv)
            {
                tlv[@"receipted message id"] = receipted_message_id;
            }
        }
        else
        {
            
            NSNumber *optNumber = @((int)opt_tag);
            SmppTlv *t = tlvDefs[optNumber];
            if(t)
            {
                if(t.type==SMPP_TLV_NULLTERMINATED)
                {
                    NSData *data = [self grabOctetStringWithLength:(int)opt_len];
                    NSString *stringValue =[NSString stringWithFormat:@"%s",[data bytes]];
                    tlv[t.name] = stringValue;
                }
                else if(t.type==SMPP_TLV_INTEGER)
                {
                    NSNumber *num = @([self grabInt:opt_len]);
                    tlv[t.name] = num;
                }
                else// if(t.type==SMPP_TLV_OCTETS)
                {
                    NSData *data = [self grabOctetStringWithLength:(int)opt_len];
                    tlv[t.name] = data;
                }
            }
            else
            {
                NSString *optKey = [NSString stringWithFormat:@"0x%04X", (unsigned int)opt_tag];
                NSData *data = [self grabOctetStringWithLength:(int)opt_len];
                tlv[optKey] = data;
            }
        }
    }
}

+ (NSString *)errorToString:(SmppErrorCode)err
{
    return [SmscConnectionSMPP smppErrorToString:err];
}

+ (NSString *)pduTypeToString:(SmppPduType)type
{
    switch(type)
    {
        case SMPP_PDU_GENERIC_NACK:
            return @"generic nack";
            
        case SMPP_PDU_BIND_RECEIVER:
            return @"bind receiver";
            
	    case SMPP_PDU_BIND_RECEIVER_RESP:
            return @"bind receiver resp";
            
	    case SMPP_PDU_BIND_TRANSMITTER:
            return @"bind transmitter";
            
	    case SMPP_PDU_BIND_TRANSMITTER_RESP:
            return @"bind transmitter resp";
            
	    case SMPP_PDU_QUERY_SM:
            return @"query sm";
            
        case SMPP_PDU_QUERY_SM_RESP:
            return @"query sm resp";
            
	    case SMPP_PDU_SUBMIT_SM:
            return @"submit sm";
            
	    case SMPP_PDU_SUBMIT_SM_RESP:
            return @"submit sm resp";
            
	    case SMPP_PDU_DELIVER_SM:
            return @"deliver sm";
            
	    case SMPP_PDU_DELIVER_SM_RESP:
            return @"deliver sm resp";
            
	    case SMPP_PDU_UNBIND:
            return @"unbind";
            
	    case SMPP_PDU_UNBIND_RESP:
            return @"unbind resp";
            
	    case SMPP_PDU_REPLACE_SM:
            return @"replace sm";
            
	    case SMPP_PDU_REPLACE_SM_RESP:
            return @"replace sm resp";
            
	    case SMPP_PDU_CANCEL_SM:
            return @"cancel sm";
            
	    case SMPP_PDU_CANCEL_SM_RESP:
            return @"cancel sm resp";
            
	    case SMPP_PDU_BIND_TRANSCEIVER:
            return @"bind transceiver";
            
	    case SMPP_PDU_BIND_TRANSCEIVER_RESP:
            return @"bind transceiver resp";
            
	    case SMPP_PDU_OUTBIND:
            return @"outbind";
            
	    case SMPP_PDU_ENQUIRE_LINK:
            return @"enquire link";
            
	    case SMPP_PDU_ENQUIRE_LINK_RESP:
            return @"enquire link resp";
            
	    case SMPP_PDU_SUBMIT_SM_MULTI:
            return @"submit sm multi";
            
	    case SMPP_PDU_SUBMIT_SM_MULTI_RESP:
            return @"submit sm multi resp";
            
	    case SMPP_PDU_ALERT_NOTIFICATION:
            return @"alert notification";
            
	    case SMPP_PDU_DATA_SM:
            return @"data sm";
            
	    case SMPP_PDU_DATA_SM_RESP:
            return @"data sm resp";

        case SMPP_PDU_EXEC:
            return @"exec";
            
        case SMPP_PDU_EXEC_RESP:
            return @"exec resp";
    }
    return @"unknown pdu";
}

- (NSString *)description
{
    NSMutableString *desc;
    
    desc = [[NSMutableString alloc] initWithString:@"SMPP PDU\n"];
    
    [desc appendFormat:@" len:     %08lX\n", (unsigned long)pdulen];
    [desc appendFormat:@" type:    %08lX %@\n", (unsigned long)type,[SmppPdu pduTypeToString:type]];
	[desc appendFormat:@" error:   %08lX %@\n", (unsigned long)err, [SmppPdu errorToString:err]];
	[desc appendFormat:@" seq:     %08lX\n", (unsigned long)seq];
	[desc appendFormat:@" payload: %@\n", payload];
    
    if (type == SMPP_PDU_BIND_TRANSMITTER || type == SMPP_PDU_BIND_RECEIVER || type == SMPP_PDU_BIND_TRANSCEIVER)
    {
        [desc appendFormat:@"system id is %@\n", system_id];
        [desc appendFormat:@"password %@\n", password ? @"exists" : @"does not exist"];
        [desc appendFormat:@"system type is %@\n", system_type];
        [desc appendFormat:@"interface version is %ld\n", interface_version];
        [desc appendFormat:@"addr npi is %ld\n", addr_npi];
        [desc appendFormat:@"addr ton is %ld\n", addr_ton];
        [desc appendFormat:@"system type is %@\n", address_range];
    }
    else if (type == SMPP_PDU_BIND_TRANSMITTER_RESP || type == SMPP_PDU_BIND_RECEIVER_RESP || type == SMPP_PDU_BIND_TRANSCEIVER_RESP)
    {
        [desc appendFormat:@"system id is %@\n", system_id];
        [desc appendFormat:@"sc interface version is %ld\n", sc_interface_version];
    }
    else if (type == SMPP_PDU_OUTBIND)
    {
        [desc appendFormat:@"system id is %@\n", system_id];
        [desc appendFormat:@"password %@\n", password ? @"exists" : @"does not exist"];
    }
    else if (type == SMPP_PDU_SUBMIT_SM)
    {
        [desc appendFormat:@"service type is %@\n", service_type];
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", destination_addr];
        [desc appendFormat:@"esm class is %ld\n", esm_class];
        [desc appendFormat:@"source protocol id is %ld\n", protocol_id];
        [desc appendFormat:@"priority flag is %ld\n", priority_flag];
        [desc appendFormat:@"scheduled delivery time is %@\n", schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", registered_delivery];
        [desc appendFormat:@"replace if present is %ld\n", replace_if_present_flag];
        [desc appendFormat:@"data coding is %ld\n", data_coding];
        [desc appendFormat:@"sm default sm id is %ld\n", sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", sm_length];
        [desc appendFormat:@"short message is %@\n", short_message];
        [desc appendFormat:@"user message reference is %ld\n", user_message_reference];
        [desc appendFormat:@"source port is %ld\n", source_port];
        [desc appendFormat:@"source address subunit is is %ld\n", source_addr_subunit];
        [desc appendFormat:@"destination port is %ld\n", destination_port];
        [desc appendFormat:@"destination address subunit is %ld\n", dest_addr_subunit];
        [desc appendFormat:@"SAR message reference number is %ld\n", sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", sar_segment_seqnum];
        [desc appendFormat:@"more messages to send is %ld\n", more_messages_to_send];
        [desc appendFormat:@"payload type is %ld\n", payload_type];
        [desc appendFormat:@"message payload is %@\n",message_payload];
        [desc appendFormat:@"privacy indicator is %ld\n", privacy_indicator];
        [desc appendFormat:@"callbacl number is %@\n", callback_num];
        [desc appendFormat:@"callback number presence indicator is %ld\n", callback_num_pres_ind];
        [desc appendFormat:@"callbacl number atag %@\n", callback_num_atag];
        [desc appendFormat:@"source subaddress is %@\n", source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", dest_subaddress];
        [desc appendFormat:@"user response code is %ld\n", user_response_code];
        [desc appendFormat:@"display time is %ld\n", display_time];
        [desc appendFormat:@"sms signal is %ld\n", sms_signal];
        [desc appendFormat:@"ms validity is %ld\n", ms_validity];
        [desc appendFormat:@"ms msg wait facilities is %ld\n", ms_msg_wait_facilities];
        [desc appendFormat:@"number of messages is %ld\n", number_of_messages];
        [desc appendFormat:@"alert on message delivery is %ld\n", alert_on_message_delivery];
        [desc appendFormat:@"language indicator is %ld\n", language_indicator];
        [desc appendFormat:@"its reply type is %ld\n", its_reply_type];
        [desc appendFormat:@"source subaddress is %@\n", its_session_info];
        [desc appendFormat:@"ussd service op is %@\n", ussd_service_op];
    }
    else if (type == SMPP_PDU_SUBMIT_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", message_id];
    }
    else if (type == SMPP_PDU_SUBMIT_SM_MULTI)
    {
        [desc appendFormat:@"service type is %@\n", service_type];
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
        [desc appendFormat:@"number of dests is %ld\n", number_of_dests];
        [desc appendFormat:@"dest address es is %@\n", dest_address_es];
        [desc appendFormat:@"esm class is %ld\n", esm_class];
        [desc appendFormat:@"source protocol id is %ld\n", protocol_id];
        [desc appendFormat:@"priority flag is %ld\n", priority_flag];
        [desc appendFormat:@"scheduled delivery time is %@\n", schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", registered_delivery];
        [desc appendFormat:@"replace if present is %ld\n", replace_if_present_flag];
        [desc appendFormat:@"data coding is %ld\n", data_coding];
        [desc appendFormat:@"sm default sm id is %ld\n", sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", sm_length];
        [desc appendFormat:@"short message is %@\n", short_message];
        [desc appendFormat:@"user message reference is %ld\n", user_message_reference];
        [desc appendFormat:@"source port is %ld\n", source_port];
        [desc appendFormat:@"source address subunit is is %ld\n", source_addr_subunit];
        [desc appendFormat:@"destination port is %ld\n", destination_port];
        [desc appendFormat:@"destination address subunit is %ld\n", dest_addr_subunit];
        [desc appendFormat:@"SAR message reference number is %ld\n", sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", sar_segment_seqnum];
        [desc appendFormat:@"payload type is %ld\n", payload_type];
        [desc appendFormat:@"message payload is %@\n",message_payload];
        [desc appendFormat:@"privacy indicator is %ld\n", privacy_indicator];
        [desc appendFormat:@"callbacl number is %@\n", callback_num];
        [desc appendFormat:@"callback number presence indicator is %ld\n", callback_num_pres_ind];
        [desc appendFormat:@"callbacl number atag %@\n", callback_num_atag];
        [desc appendFormat:@"source subaddress is %@\n", source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", dest_subaddress];
        [desc appendFormat:@"user response code is %ld\n", user_response_code];
        [desc appendFormat:@"display time is %ld\n", display_time];
        [desc appendFormat:@"sms signal is %ld\n", sms_signal];
        [desc appendFormat:@"ms validity is %ld\n", ms_validity];
        [desc appendFormat:@"ms msg wait facilities is %ld\n", ms_msg_wait_facilities];
        [desc appendFormat:@"alert on message delivery is %ld\n", alert_on_message_delivery];
        [desc appendFormat:@"language indicator is %ld\n", language_indicator];
    }
    else if (type == SMPP_PDU_SUBMIT_SM_MULTI_RESP)
    {
        [desc appendFormat:@"message id is %@\n", message_id];
        [desc appendFormat:@"no unsuccess is %ld\n", no_unsuccess];
    }
    else if (type == SMPP_PDU_DELIVER_SM)
    {
        [desc appendFormat:@"service type is %@\n", service_type];
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", destination_addr];
        [desc appendFormat:@"esm class is %ld\n", esm_class];
        [desc appendFormat:@"source protocol id is %ld\n", protocol_id];
        [desc appendFormat:@"priority flag is %ld\n", priority_flag];
        [desc appendFormat:@"scheduled delivery time is %@\n", schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", registered_delivery];
        [desc appendFormat:@"replace if present is %ld\n", replace_if_present_flag];
        [desc appendFormat:@"data coding is %ld\n", data_coding];
        [desc appendFormat:@"sm default sm id is %ld\n", sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", sm_length];
        [desc appendFormat:@"short message is %@\n", short_message];
        [desc appendFormat:@"user message reference is %ld\n", user_message_reference];
        [desc appendFormat:@"source port is %ld\n", source_port];
        [desc appendFormat:@"destination port is %ld\n", destination_port];
        [desc appendFormat:@"SAR message reference number is %ld\n", sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", sar_segment_seqnum];
        [desc appendFormat:@"user response code is %ld\n", user_response_code];
        [desc appendFormat:@"privacy indicator is %ld\n", privacy_indicator];
        [desc appendFormat:@"payload type is %ld\n", payload_type];
        [desc appendFormat:@"message payload is %@\n",message_payload];
        [desc appendFormat:@"callbacl number is %@\n", callback_num];
        [desc appendFormat:@"source subaddress is %@\n", source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", dest_subaddress];
        [desc appendFormat:@"language indicator is %ld\n", language_indicator];
        [desc appendFormat:@"source subaddress is %@\n", its_session_info];
        [desc appendFormat:@"network error code is %@\n", network_error_code];
        [desc appendFormat:@"message state is %ld\n", message_state];
        [desc appendFormat:@"receipted message id is %@\n", receipted_message_id];
    }
    else if (type == SMPP_PDU_DELIVER_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", message_id];
    }
    else if (type == SMPP_PDU_DATA_SM)
    {
        [desc appendFormat:@"service type is %@\n", service_type];
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", destination_addr];
        [desc appendFormat:@"esm class is %ld\n", esm_class];
        [desc appendFormat:@"registered delivery is %ld\n", registered_delivery];
        [desc appendFormat:@"data coding is %ld\n", data_coding];
        [desc appendFormat:@"source port is %ld\n", source_port];
        [desc appendFormat:@"source address subunit is is %ld\n", source_addr_subunit];
        [desc appendFormat:@"source network type is %ld\n", source_network_type];
        [desc appendFormat:@"source bearer type is %ld\n", source_bearer_type];
        [desc appendFormat:@"source telematics id is %ld\n", source_telematics_id];
        [desc appendFormat:@"destination network type is %ld\n", dest_network_type];
        [desc appendFormat:@"destination bearer type is %ld\n", dest_bearer_type];
        [desc appendFormat:@"destination telematics id is %ld\n", dest_telematics_id];
        [desc appendFormat:@"SAR message reference number is %ld\n", sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", sar_segment_seqnum];
        [desc appendFormat:@"more messages to send is %ld\n", more_messages_to_send];
        [desc appendFormat:@"quality of service, time to live is %ld\n", qos_time_to_live];
        [desc appendFormat:@"payload type is %ld\n", payload_type];
        [desc appendFormat:@"message payload is %@\n",message_payload];
        [desc appendFormat:@"set pdf is %ld\n", set_dpf];
        [desc appendFormat:@"receipted message id is %@\n", receipted_message_id];
        [desc appendFormat:@"message state is %ld\n", message_state];
        [desc appendFormat:@"network error code is %@\n", network_error_code];
        [desc appendFormat:@"user message reference is %ld\n", user_message_reference];
        [desc appendFormat:@"privacy indicator is %ld\n", privacy_indicator];
        [desc appendFormat:@"callbacl number is %@\n", callback_num];
        [desc appendFormat:@"callback number presence indicator is %ld\n", callback_num_pres_ind];
        [desc appendFormat:@"callbacl number atag %@\n", callback_num_atag];
        [desc appendFormat:@"source subaddress is %@\n", source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", dest_subaddress];
        [desc appendFormat:@"user response code is %ld\n", user_response_code];
        [desc appendFormat:@"display time is %ld\n", display_time];
        [desc appendFormat:@"sms signal is %ld\n", sms_signal];
        [desc appendFormat:@"ms validity is %ld\n", ms_validity];
        [desc appendFormat:@"ms msg wait facilities is %ld\n", ms_msg_wait_facilities];
        [desc appendFormat:@"alert on message delivery is %ld\n", alert_on_message_delivery];
        [desc appendFormat:@"language indicator is %ld\n", language_indicator];
        [desc appendFormat:@"its reply type is %ld\n", its_reply_type];
        [desc appendFormat:@"source subaddress is %@\n", its_session_info];
    }
    else if (type == SMPP_PDU_DATA_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", message_id];
        [desc appendFormat:@"delivery failure reason is %ld\n", delivery_failure_reason];
        [desc appendFormat:@"network error code is %@\n", network_error_code];
        [desc appendFormat:@"additional satus info text is %@\n", additional_status_info_text];
        [desc appendFormat:@"dpf result is %ld\n", dpf_result];
    }
    else if (type == SMPP_PDU_QUERY_SM)
    {
        [desc appendFormat:@"message id is %@\n", message_id];
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
    }
    else if (type == SMPP_PDU_QUERY_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", message_id];
        [desc appendFormat:@"final date is info text is %@\n", final_date];
        [desc appendFormat:@"message state is %ld\n", message_state];
        [desc appendFormat:@"error code is %ld\n", error_code];
    }
    else if (type == SMPP_PDU_CANCEL_SM)
    {
        [desc appendFormat:@"service type is %@\n", service_type];
        [desc appendFormat:@"message id is %@\n", message_id];
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", destination_addr];
    }
    else if (type == SMPP_PDU_REPLACE_SM)
    {
        [desc appendFormat:@"service type is %@\n", service_type];
        [desc appendFormat:@"message id is %@\n", message_id];
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
        [desc appendFormat:@"scheduled delivery time is %@\n", schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", registered_delivery];
        [desc appendFormat:@"sm default sm id is %ld\n", sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", sm_length];
        [desc appendFormat:@"short message is %@\n", short_message];
    }
    else if (type == SMPP_PDU_ALERT_NOTIFICATION)
    {
        [desc appendFormat:@"source addr ton is %ld\n", source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", source_addr_npi];
        [desc appendFormat:@"system type is %@\n", source_addr];
        [desc appendFormat:@"esme addr ton is %ld\n", esme_addr_ton];
        [desc appendFormat:@"esme addr npi is %ld\n", esme_addr_npi];
        [desc appendFormat:@"esme addr is %@\n", esme_addr];
        [desc appendFormat:@"ms avability status is %ld\n", ms_availability_status];
    }
    
    [desc appendFormat:@"tlvs dictionary for custom tlvs is %@\n", tlv];
    
    [desc appendString:@"SMPP PDU dump ends"];
    
    return desc;
}

- (NSString *)sequenceString
{
    return [NSString stringWithFormat:@"%08lx",(unsigned long)[self seq]];
}

- (void)setSequenceString:(NSString *)s
{
    unsigned long ul;
    sscanf([s UTF8String],"%08lx",&ul);
    [self setSeq:ul];
}

+ (NSDate *)smppTimestampFromString:(NSString *)str
{
    @autoreleasepool
    {
        const char *ts = str.UTF8String;
        int microsec = 0;
        time_t theTime;
        
        if(strlen(ts) != 16)
        {
            return NULL;
        }
        int Y = 0;
        int M = 0;
        int D = 0;
        int h = 0;
        int m = 0;
        int s = 0;
        int t = 0;
        int n = 0;
        char p = 0;

        sscanf(ts,"%02d%02d%02d%02d%02d%02d%01d%02d%1c",&Y,&M,&D,&h,&m,&s,&t,&n,&p);
        
        struct tm   trec;
        trec.tm_year = 100 + Y;
        trec.tm_mon = M - 1;
        trec.tm_mday = D;
        trec.tm_hour = h;
        trec.tm_min = m;
        trec.tm_sec = s;
        if(p == '-')
        {
            trec.tm_gmtoff = -(15 * 60 * n);
            theTime = timegm(&trec);
        }
        else if (p == '+')
        {
            trec.tm_gmtoff = -(15 * 60 * n);
            microsec = t * 100000;
            theTime = timegm(&trec);
        }
        else if (p == 'R')
        {
            /* relative timestamp */
            theTime = timegm(&trec);
            time_t now;
            struct tm nowTm;
            time(&now);
            gmtime_r(&now,&nowTm);
            trec.tm_gmtoff = 0;
            trec.tm_year   = trec.tm_year - 100  + nowTm.tm_year;
            trec.tm_mon    = trec.tm_mon +  1 + nowTm.tm_mon;
            trec.tm_mday   = trec.tm_mday + nowTm.tm_mday;
            trec.tm_hour   = trec.tm_hour + nowTm.tm_hour;
            trec.tm_min    = trec.tm_min + nowTm.tm_min;
            trec.tm_sec    = trec.tm_sec + nowTm.tm_sec;
            theTime = timegm(&trec);
        }
        else
        {
            return NULL;
        }
        return [NSDate dateWithTimeIntervalSince1970:theTime];
    }
}


@end
