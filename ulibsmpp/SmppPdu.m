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
#import "UMSmppError.h"

static UMSmppError SMPP_outgoingErrorCodeMapping(UMSmppError e);

@implementation SmppPdu

- (SmppPdu *)init
{
    self = [super init];
    if(self)
    {
    }
    return self;
}

- (SmppPdu *)initWithType:(SmppPduType)t err:(UMSmppError)e
{
    self = [super init];
    if(self)
    {
        _pdulen     = 0;
        _type	    = t;
        _err		= SMPP_outgoingErrorCodeMapping(e);
        _seq		= 0;
        _cursor 	= 0;
        _payload    = [[NSMutableData alloc] init];
    }
	return self;
}

- (SmppPdu *)initFromData:(NSData *)d
{
	unsigned char header[16];
	unsigned char *ptr;
    
    self = [super init];
    if(self)
    {
        [d getBytes: header length:16];
        _pdulen	= ((header[0] << 24) | (header[1] << 16) | (header[2] << 8) | (header[3]));
        _type	= ((header[4] << 24) | (header[5] << 16) | (header[6] << 8) | (header[7]));
        _err		= ((header[8] << 24) | (header[9] << 16) | (header[10] << 8) | (header[11]));
        _seq		= ((header[12] << 24) | (header[13] << 16) | (header[14] << 8) | (header[15]));
        ptr = (unsigned char *) [d bytes];
        
        if(_pdulen > 0)
        {
            _payload = [[NSMutableData alloc] initWithBytes: &ptr[16] length:_pdulen-16];
        }
        else
        {
            _payload = [[NSMutableData alloc] init];
        }
        _cursor	= 0;
        _tlvs = [[NSMutableDictionary alloc] init];
    }
	return self;
}



- (size_t)_pdulen
{
    _pdulen = 16 + [_payload length];
    return _pdulen;
}

- (SmppPdu *)initWithType:(SmppPduType)t
{
	return [self initWithType:t err:UM_NO_ERROR];
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
	[_payload appendBytes: (const void *) bytes length: len];
}

- (void) appendByte:(unsigned char)byte
{
	[_payload appendBytes: (const void *) &byte length: 1];
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

+ (SmppPdu *)OutgoingBindRespError:(UMSmppError) err rx:(BOOL)rx tx:(BOOL)tx
{
    return [SmppPdu OutgoingBindRespError:err rx:rx tx:tx status:NULL];
}

+ (SmppPdu *)OutgoingBindRespError:(UMSmppError) err rx:(BOOL)rx tx:(BOOL)tx status:(NSString *)status_text
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

+ (SmppPdu *)OutgoingBindTransmitterRespError:(UMSmppError) err
{
    return [SmppPdu OutgoingBindTransmitterRespError:err status:NULL];
}

+ (SmppPdu *)OutgoingBindTransmitterRespError:(UMSmppError) err status:(NSString *)status
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
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSMITTER_RESP err:UM_NO_ERROR];
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
	SmppPdu *pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_RECEIVER err:UM_NO_ERROR];
	[pdu appendNSStringMax:systemId maxLength:16];
	[pdu appendNSStringMax:password maxLength:9];
	[pdu appendNSStringMax:stype    maxLength:13];
	[pdu appendInt8: version                  ];
	[pdu appendInt8: ton                      ];
	[pdu appendInt8: npi                      ];
	[pdu appendNSStringMax: range   maxLength:41];
	return pdu;
}


+ (SmppPdu *)OutgoingBindReceiverRespError:(UMSmppError) err
{
    return [SmppPdu OutgoingBindReceiverRespError:err status:NULL];
}

+ (SmppPdu *)OutgoingBindReceiverRespError:(UMSmppError) err status:(NSString *)status
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
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_RECEIVER_RESP err:UM_NO_ERROR];
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

+ (SmppPdu *)OutgoingBindTransceiverRespError:(UMSmppError) err
{
    return [SmppPdu OutgoingBindTransceiverRespError:err status:NULL];
}
            
+ (SmppPdu *)OutgoingBindTransceiverRespError:(UMSmppError) err status:(NSString *)status
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
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_BIND_TRANSCEIVER_RESP err:UM_NO_ERROR];
	[pdu appendNSStringMax:systemId maxLength: 16];
	[pdu appendTLVByte:0x34 withTag: SMPP_TLV_SC_INTERFACE_VERSION];
	return pdu;
}

+ (SmppPdu *)OutgoingOutbind:(NSString *)systemId
					password:(NSString *)password
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_OUTBIND err:UM_NO_ERROR];
	[pdu appendNSStringMax:systemId maxLength:16];
	[pdu appendNSStringMax:password maxLength:9];
	return pdu;
}

+ (SmppPdu *)OutgoingUnbind
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_UNBIND err:UM_NO_ERROR];
	return pdu;
}

+ (SmppPdu *)OutgoingUnbindRespOK
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_UNBIND_RESP err:UM_NO_ERROR];
	return pdu;
}

+ (SmppPdu *)OutgoingUnbindRespErr:(UMSmppError) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_UNBIND_RESP err:err];
	return pdu;
}

+ (SmppPdu *)OutgoingGenericNack:(UMSmppError) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_GENERIC_NACK err:err];
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitSm:(UMMessage *)msg
{
    return [SmppPdu OutgoingSubmitSm:msg
                            esmClass:SMPP_PDU_ESM_CLASS_SUBMIT_DEFAULT_SMSC_MODE
                         serviceType:NULL
                             options:@{}];
}

+ (SmppPdu *)OutgoingSubmitSm:(UMMessage *)msg
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

+ (SmppPdu *)OutgoingSubmitSm:(UMMessage *)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype
{
    return [SmppPdu OutgoingSubmitSm:msg esmClass:esmclass serviceType:servicetype options:@{}];
}
        
+ (SmppPdu *)OutgoingSubmitSm:(UMMessage *)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype options:(NSDictionary *)options
{
	SmppPdu *pdu;
	NSData *data;
	NSUInteger len;
	int use_message_payload;
	
    if(msg.pduUdhIndicator.integerValue)
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
    }
    if(msg.pduReplyPathIndicator.integerValue)
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
    }
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM err:UM_NO_ERROR];
    
	[pdu appendNSStringMax:servicetype maxLength: 6];
    UMSigAddr *from = [[UMSigAddr alloc]initWithString:msg.fromNumber.stringValue];
	[pdu appendInt8:from.ton];
	[pdu appendInt8:from.npi];
	[pdu appendNSStringMax:from.addr  maxLength:21];
    
    UMSigAddr *to = [[UMSigAddr alloc]initWithString:msg.toNumber.stringValue];
	[pdu appendInt8:to.ton];
	[pdu appendInt8:to.npi];
    [pdu appendNSStringMax:to.addr  maxLength:21];
	[pdu appendInt8: esmclass]; //5.2.12
    [pdu appendInt8: msg.pduPid.integerValue]; //5.2.13
    [pdu appendInt8: msg.messagePriority.integerValue]; //5.2.13
    [pdu appendDate: msg.deferred.dateValue]; //scheduled time
    [pdu appendDate: msg.validity.dateValue];
    //[pdu appendInt8:  [msg reportMask] ? 1 : 0];
    
    UMReportMaskValue reportMask = (UMReportMaskValue)msg.deliveryReportMask.integerValue;
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
	[pdu appendInt8:msg.replaceIfPresentFlag.integerValue];
	[pdu appendInt8:msg.pduDcs.integerValue];
	[pdu appendInt8:0];	/* predefined message text */
    if(msg.pduUdhIndicator.integerValue)
    {
        NSMutableData *d = [NSMutableData dataWithData:msg.pduUdh.data];
        [d appendData:msg.pduContent.data];
        data = d;
    }
    else
    {
        data = msg.pduContent.data;
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
            NSInteger uf = [msg userFlags];
            if(uf)
            {
                NSString *s = [@(uf) stringValue];
                [pdu appendTLVString:s withTag:SMPP_TLV_VENDOR_SPECIFIC_USERFLAGS];
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


+ (void)appendMessageMoverTlvsFromMsg:(UMMessage *)msg toPdu:(SmppPdu *)pdu
{
    if([msg respondsToSelector:@selector(smsc_srism_gt)])
    {
        NSString *gt = msg.smsc_srism_gt.stringValue;
        if(gt)
        {
            [pdu appendTLVString:gt withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC_SRISM_GT];
            [pdu appendTLVString:gt withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC1];
        }
    }
    if([msg respondsToSelector:@selector(smsc_srism_map)])
    {
        NSString *map = msg.smsc_srism_map.stringValue;
        if(map)
        {
            [pdu appendTLVString:map withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC_SRISM_MAP];
            [pdu appendTLVString:map withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC4];
        }
    }
    if([msg respondsToSelector:@selector(smsc_fsm_gt)])
    {
        NSString *gt = msg.smsc_fsm_gt.stringValue;
        if(gt)
        {
            [pdu appendTLVString:gt withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC_FSM_GT];
            [pdu appendTLVString:gt withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC2];
        }
    }
    if([msg respondsToSelector:@selector(smsc_fsm_map)])
    {
        NSString *map = msg.smsc_fsm_map.stringValue;
        if(map)
        {
            [pdu appendTLVString:map withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC_FSM_MAP];
            [pdu appendTLVString:map withTag:SMPP_TLV_VENDOR_SPECIFIC_SMSC3];
        }
    }


    if([msg respondsToSelector:@selector(opc_srism)])
    {
        NSString *opc = msg.opc_srism.stringValue;
        if(opc)
        {
            [pdu appendTLVString:opc withTag:SMPP_TLV_VENDOR_SPECIFIC_OPC1];
        }
    }
    if([msg respondsToSelector:@selector(dpc_srism)])
    {
        NSString *dpc = msg.dpc_srism.stringValue;
        if(dpc)
        {
            [pdu appendTLVString:dpc withTag:SMPP_TLV_VENDOR_SPECIFIC_DPC1];
        }
    }
    if([msg respondsToSelector:@selector(opc_fsm)])
    {
        NSString *opc = msg.opc_fsm.stringValue;
        if(opc)
        {
            [pdu appendTLVString:opc withTag:SMPP_TLV_VENDOR_SPECIFIC_OPC2];
        }
    }
    if([msg respondsToSelector:@selector(dpc_srism)])
    {
        NSString *dpc = msg.dpc_fsm.stringValue;
        if(dpc)
        {
            [pdu appendTLVString:dpc withTag:SMPP_TLV_VENDOR_SPECIFIC_DPC2];
        }
    }
    if([msg respondsToSelector:@selector(userFlags)])
    {
        NSNumber *uf = msg.userFlags.number;
        if(uf)
        {
            NSString *s = [uf stringValue];
            [pdu appendTLVString:s withTag:SMPP_TLV_VENDOR_SPECIFIC_USERFLAGS];
        }
    }
    if([msg respondsToSelector:@selector(toMsc)])
    {
        NSString *msc = msg.toMsc.stringValue;
        if(msc)
        {
            UMSigAddr *s = [UMSigAddr sigAddrFromString:msc];
            [pdu appendTLVByte:s.ton withTag:SMPP_TLV_VENDOR_SPECIFIC_MSC_TON];
            [pdu appendTLVByte:s.npi withTag:SMPP_TLV_VENDOR_SPECIFIC_MSC_NPI];
            [pdu appendTLVString:s.addr withTag:SMPP_TLV_VENDOR_SPECIFIC_MSC_ADDR];
            [pdu appendTLVString:msc withTag:SMPP_TLV_VENDOR_SPECIFIC_TO_MSC];
        }
    }
    if([msg respondsToSelector:@selector(fromMsc)])
    {
        NSString *msc = msg.toMsc.stringValue;
        if(msc)
        {
            [pdu appendTLVString:msc withTag:SMPP_TLV_VENDOR_SPECIFIC_FROM_MSC];
        }
    }

    if([msg respondsToSelector:@selector(hlr)])
    {
        NSString *hlr = msg.hlr.stringValue;
        if(hlr)
        {
            UMSigAddr *s = [UMSigAddr sigAddrFromString:hlr];
            [pdu appendTLVByte:s.ton withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR_TON];
            [pdu appendTLVByte:s.npi withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR_NPI];
            [pdu appendTLVString:s.addr withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR_ADDR];
            [pdu appendTLVString:hlr withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR];
        }
        
    }
    if([msg respondsToSelector:@selector(hlrOverride)])
    {
        NSString *hlr = msg.hlrOverride.stringValue;
        if(hlr)
        {
            [pdu appendTLVString:hlr withTag:SMPP_TLV_VENDOR_SPECIFIC_HLR_OVERRIDE];
        }
    }

    if([msg respondsToSelector:@selector(toImsi)])
    {
        NSString *imsi = msg.toImsi.stringValue;
        if(imsi)
        {
            [pdu appendTLVString:imsi withTag:SMPP_TLV_VENDOR_SPECIFIC_IMSI];
            [pdu appendTLVString:imsi withTag:SMPP_TLV_VENDOR_SPECIFIC_TO_IMSI];
        }
    }
    if([msg respondsToSelector:@selector(fromImsi)])
    {
        NSString *imsi = msg.fromImsi.stringValue;
        if(imsi)
        {
            [pdu appendTLVString:imsi withTag:SMPP_TLV_VENDOR_SPECIFIC_FROM_IMSI];
        }
    }
    if([msg respondsToSelector:@selector(mcc)])
    {
        NSString *mcc = msg.mcc.stringValue;
        if(mcc)
        {
            [pdu appendTLVString:mcc withTag:SMPP_TLV_VENDOR_SPECIFIC_MCC];
        }
    }
    if([msg respondsToSelector:@selector(deliveryMethod)])
    {
        NSString *method = msg.deliveryMethod.stringValue;
        if(method)
        {
            [pdu appendTLVString:method withTag:SMPP_TLV_VENDOR_SPECIFIC_DELIVERY_METHOD];
        }
    }
}
    
+ (SmppPdu *)OutgoingSubmitSmRespOK:(UMMessage *)msg
							 withId:(NSString *)msgId
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_RESP err:UM_NO_ERROR];
	// TODO: verify if id is better a NSData
	[pdu appendNSStringMax:msgId maxLength: 65];
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitSmRespErr:(UMSmppError) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_RESP err:err];
	return pdu;
}

+ (SmppPdu *)OutgoingSubmitMulti:(UMMessage *)msg distributionList:(NSString *) distributionListName
{
	SmppPdu *pdu;
	int	esmclass = 0;
	NSData *data;
	NSUInteger len;
	int use_message_payload;
    
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_MULTI err:UM_NO_ERROR];
    
	esmclass = SMPP_PDU_ESM_CLASS_SUBMIT_STORE_AND_FORWARD_MODE;
    if (msg.pduUdhIndicator.integerValue )
    {
        esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
    }
    if(msg.pduReplyPathIndicator.integerValue)
    {
        esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
    }
	
    [pdu appendNSStringMax:@"" maxLength: 6]; // service type default
    UMSigAddr *from = [[UMSigAddr alloc]initWithString:msg.fromNumber.stringValue];
    [pdu appendInt8:from.ton];
    [pdu appendInt8:from.npi];
    [pdu appendNSStringMax:from.addr  maxLength:21];
	[pdu appendInt8: 1]; /* number of destination addresses */
	[pdu appendInt8: 2]; /* 2 = distribution list name, 1 = SME destination */
	[pdu appendNSStringMax: distributionListName   maxLength:21];
	[pdu appendInt8:  esmclass]; //5.2.12
    [pdu appendInt8:  msg.pduPid.integerValue]; //5.2.13
    [pdu appendInt8:  msg.messagePriority.integerValue]; //5.2.13
    [pdu appendDate:  msg.deferred.dateValue]; //scheduled time
    [pdu appendDate:  msg.validity.dateValue];
    [pdu appendInt8:  msg.deliveryReportMask.integerValue ? 1 : 0];
    [pdu appendInt8:  (msg.replaceIfPresentFlag.integerValue ? 1 : 0)];
    [pdu appendInt8:  msg.pduDcs.integerValue];
	[pdu appendInt8:  0];	/* predefined message text */
    if(msg.pduUdhIndicator.integerValue)
    {
        NSMutableData *d = [NSMutableData dataWithData:msg.pduUdh.data];
        [d appendData:msg.pduContent.data];
        data = d;
    }
    else
    {
        data = msg.pduContent.data;
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
	
	if([msg routerReference])
    {
		[pdu appendTLVString:msg.routerReference.stringValue withTag:SMPP_TLV_USER_MESSAGE_REFERENCE];
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
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM_MULTI err:UM_NO_ERROR];
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

+ (SmppPdu *)OutgoingSubmitMultiRespErr:(UMSmppError) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] init];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingDeliverSm:(UMMessage *)msg
{
	return [SmppPdu OutgoingDeliverSm:msg esmClass:SMPP_PDU_ESM_CLASS_DELIVER_DEFAULT_TYPE serviceType:NULL];
}

+ (SmppPdu *)OutgoingDeliverSm:(UMMessage *)msg options:(NSDictionary *)options
{
    return [SmppPdu OutgoingDeliverSm:msg esmClass:SMPP_PDU_ESM_CLASS_DELIVER_DEFAULT_TYPE serviceType:NULL options:options];
}

+ (SmppPdu *)OutgoingDeliverSm:(UMMessage *)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype
{
    return [SmppPdu OutgoingDeliverSm:msg
                             esmClass:esmclass
                          serviceType:servicetype
                              options:@{}];
}

+ (SmppPdu *)OutgoingDeliverSm:(UMMessage *)msg
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
    if (msg.pduUdhIndicator.integerValue)
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
    }
    if(msg.pduReplyPathIndicator.integerValue)
    {
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
    }
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM err:UM_NO_ERROR];
	
	[pdu appendNSStringMax:servicetype maxLength: 6];
	if(we_are_delivery_report)
	{ /* the generator of the deliver report is in charge of swappign sender/receiver */
        UMSigAddr *from = [[UMSigAddr alloc]initWithString:msg.fromNumber.stringValue];
        [pdu appendInt8:from.ton];
        [pdu appendInt8:from.npi];
        [pdu appendNSStringMax:from.addr  maxLength:21];

        UMSigAddr *to = [[UMSigAddr alloc]initWithString:msg.toNumber.stringValue];
        [pdu appendInt8:to.ton];
        [pdu appendInt8:to.npi];
        [pdu appendNSStringMax:to.addr  maxLength:21];
    }
	else
	{
        UMSigAddr *from = [[UMSigAddr alloc]initWithString:msg.fromNumber.stringValue];
        [pdu appendInt8:from.ton];
        [pdu appendInt8:from.npi];
        [pdu appendNSStringMax:from.addr  maxLength:21];

        UMSigAddr *to = [[UMSigAddr alloc]initWithString:msg.toNumber.stringValue];
        [pdu appendInt8:to.ton];
        [pdu appendInt8:to.npi];
        [pdu appendNSStringMax:to.addr  maxLength:21];
    }
    
	[pdu appendInt8:  esmclass];
    [pdu appendInt8:  msg.pduPid.integerValue];
    [pdu appendInt8:  msg.messagePriority.integerValue];
    [pdu appendDate:  msg.deferred.dateValue];
    [pdu appendDate:  msg.validity.dateValue];
	[pdu appendInt8:  msg.deliveryReportMask.integerValue ? 1 : 0];
    [pdu appendInt8:  msg.replaceIfPresentFlag.integerValue ? 1 : 0];
	[pdu appendInt8:  msg.pduDcs.integerValue];
	[pdu appendInt8:  0];	/* predefined message text must be NULL for deliver SM */
	if(we_are_delivery_report)
	{
		NSString *ms;
		NSString *reportText;
        NSInteger type = msg.smppStateCode;
		switch(type)
		{
			case UMMESSAGE_STATUS_ENROUTE:
                ms = @"ENROUTE";
				break;
			case UMMESSAGE_STATUS_ACCEPTED:
				ms = @"ACCEPTD";
				break;
			case UMMESSAGE_STATUS_DELIVERED:
				ms = @"DELIVRD";
				break;
			case UMMESSAGE_STATUS_EXPIRED:
                ms = @"EXPIRED";
				break;
			case UMMESSAGE_STATUS_DELETED:
                ms = @"DELETED";
				break;
			case UMMESSAGE_STATUS_UNDELIVERABLE:
                ms = @"UNDELIV";
				break;
			case UMMESSAGE_STATUS_REJECTED:
				ms = @"REJECTD";
				break;
			default:
				ms = @"UNKNOWN";
		}
        
		NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMddHHmmss"];
        
		reportText = [NSString stringWithFormat:@"id:%@ sub:001 dlvrd:001 submit date:%@ done date:%@ stat:%@ err:%d text:Report",
					  msg.routerReference,
                      msg.submitTimestamp ? [formatter stringFromDate:msg.submitTimestamp.dateValue]:[formatter stringFromDate:[NSDate date]],
                      msg.messageAttempted ? [formatter stringFromDate:msg.messageAttempted.dateValue]:[formatter stringFromDate:[NSDate date]],
					  ms,
                      msg.networkErrorCode ? [NSString stringWithFormat:@"%03ld",msg.networkErrorCode.integerValue] : @"000"];
		data = [reportText dataUsingEncoding:NSISOLatin1StringEncoding allowLossyConversion:YES];
	}
	else
	{
        if(msg.pduUdhIndicator.integerValue)
        {
            NSMutableData *d = [NSMutableData dataWithData:msg.pduUdh.data];
            [d appendData:msg.pduContent.data];
            data = d;
        }
        else
        {
            data = msg.pduContent.data;
        }
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
		if(msg.userMessageReference.data.length==2)
        {
			[pdu appendTLVData:msg.userMessageReference.data withTag:SMPP_TLV_USER_MESSAGE_REFERENCE];
        }
        [pdu appendTLVStringNullTerminated:msg.routerReference.stringValue withTag:SMPP_TLV_RECEIPTED_MESSAGE_ID];
        [pdu appendTLVNetworkErrorCode:msg.networkErrorCode.integerValue networkType:SMPP_NETWORK_TYPE_GSM  withTag:SMPP_TLV_NETWORK_ERROR_CODE];
		[pdu appendTLVByte: [SmppPdu messageState:msg.smppStateCode] withTag: SMPP_TLV_MESSAGE_STATE];
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

+ (SmppPdu *)OutgoingSubmitSmReport:(UMMessage *)msg
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

+ (SmppPdu *)OutgoingDeliverSmReport:(UMMessage *)msg
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

+ (SmppPdu *)OutgoingDeliverSmRespOK:(UMMessage *)msg
							  withId:(NSString *)msg_id
{
	SmppPdu *pdu;
    
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM_RESP err:UM_NO_ERROR];
//    [pdu appendNSStringMax: msg_id maxLength:65];
    [pdu appendNSStringMax: @"" maxLength:65];
	return pdu;
}

+ (SmppPdu *)OutgoingDeliverSmRespErr:(UMSmppError) err
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM_RESP err:err];
	[pdu appendNSStringMax: @"" maxLength:1];
	return pdu;
}

+ (SmppPdu *)OutgoingDeliverSmReportRespOK:(UMMessageReport *)report
                                    withId:(NSString *)submit_id
{
	SmppPdu *pdu;
    
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DELIVER_SM_RESP err:UM_NO_ERROR];
    //    [pdu appendNSStringMax: submit_id maxLength:65];
    [pdu appendNSStringMax: @"" maxLength:65];
	return pdu;
}


+ (SmppPdu *)OutgoingDataSm:(UMMessage *)msg
{
	return [SmppPdu OutgoingDataSm:msg esmClass:SMPP_PDU_ESM_CLASS_SUBMIT_DEFAULT_SMSC_MODE serviceType:@""];
}

+ (SmppPdu *)OutgoingDataSm:(UMMessage *)msg esmClass:(int)esmclass serviceType:(NSString *)servicetype
{
	SmppPdu *pdu;
	NSData *data;
	NSUInteger len;
	int use_message_payload;
	
    if(msg.pduUdhIndicator.integerValue)
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR;
    if(msg.pduReplyPathIndicator.integerValue)
		esmclass |= SMPP_PDU_ESM_CLASS_SUBMIT_RPI;
	
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DATA_SM err:UM_NO_ERROR];
	
	[pdu appendNSStringMax:servicetype maxLength: 6];
    
    UMSigAddr *from = [[UMSigAddr alloc]initWithString:msg.fromNumber.stringValue];
    [pdu appendInt8:from.ton];
    [pdu appendInt8:from.npi];
    [pdu appendNSStringMax:from.addr  maxLength:21];
    
    UMSigAddr *to = [[UMSigAddr alloc]initWithString:msg.toNumber.stringValue];
    [pdu appendInt8:to.ton];
    [pdu appendInt8:to.npi];
    [pdu appendNSStringMax:to.addr  maxLength:21];
	[pdu appendInt8:  esmclass]; //5.2.12
    [pdu appendInt8:  msg.deliveryReportMask.integerValue ? 1 : 0];
    [pdu appendInt8:  msg.pduDcs.integerValue];
    
    if(msg.pduUdhIndicator.integerValue)
    {
        NSMutableData *d = [NSMutableData dataWithData:msg.pduUdh.data];
        [d appendData:msg.pduContent.data];
        data = d;
    }
    else
    {
        data = msg.pduContent.data;
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
	
	if([msg routerReference])
    {
        [pdu appendTLVString:msg.routerReference.stringValue withTag:SMPP_TLV_USER_MESSAGE_REFERENCE];
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


+ (SmppPdu *)OutgoingDataSmRespOK:(UMMessage *)msg
                           withId:(NSString *)msgId
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DATA_SM_RESP err:UM_NO_ERROR];
	// TODO: verify if id is better a NSData
	[pdu appendNSStringMax:msgId maxLength: 65];
	return pdu;
}

+ (SmppPdu *)OutgoingDataSmRespErr:(UMSmppError) err messageId:(NSString *)msgid networkType:(SmppNetworkType)nt
{
	SmppPdu *pdu;
	pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_DATA_SM_RESP err:UM_NO_ERROR];
	// TODO: verify if id is better a NSData
	[pdu appendNSStringMax:msgid maxLength: 65];
	[pdu appendTLVNetworkErrorCode:err networkType:nt withTag:SMPP_TLV_NETWORK_ERROR_CODE];
	return pdu;
}

+ (SmppPdu *)OutgoingQuerySm
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_QUERY_SM err:UM_NO_ERROR];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingQueryRespOK:(UMMessage *)msg
						  withId:(NSString *)msg_id
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_QUERY_SM_RESP err:UM_NO_ERROR];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingQuerySmRespErr:(UMSmppError) err
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
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_CANCEL_SM err:UM_NO_ERROR];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingCancelSmRespOK
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_CANCEL_SM_RESP err:UM_NO_ERROR];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingCancelSmRespErr:(UMSmppError) err
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
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_REPLACE_SM err:UM_NO_ERROR];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingReplaceSmRespOK
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_REPLACE_SM_RESP err:UM_NO_ERROR];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingReplaceSmRespErr:(UMSmppError) err
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
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_ENQUIRE_LINK err:UM_NO_ERROR];
	if(pdu)
	{
	}
	return pdu;
}

+ (SmppPdu *)OutgoingEnquireLinkResp
{
	SmppPdu *pdu;
    pdu = [[SmppPdu alloc] initWithType:SMPP_PDU_ENQUIRE_LINK_RESP err:UM_NO_ERROR];
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
		case UMMESSAGE_STATUS_ENROUTE:
			return SMPP_MESSAGE_STATE_ENROUTE;
		case UMMESSAGE_STATUS_DELIVERED:
			return SMPP_MESSAGE_STATE_DELIVERED;
		case UMMESSAGE_STATUS_EXPIRED:
			return SMPP_MESSAGE_STATE_EXPIRED;
		case UMMESSAGE_STATUS_DELETED:
			return SMPP_MESSAGE_STATE_DELETED;
		case UMMESSAGE_STATUS_UNDELIVERABLE:
			return SMPP_MESSAGE_STATE_UNDELIVERABLE;
		case UMMESSAGE_STATUS_ACCEPTED:
			return SMPP_MESSAGE_STATE_ACCEPTED;
		case UMMESSAGE_STATUS_REJECTED:
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
	
	d = [_payload bytes];
	
	if( (_cursor+sizeof(uint8_t)) > [_payload length])
		return 0;
	
	i = d[_cursor++];
	return i;
}

-(NSInteger)	grabInt16
{
	uint32_t i;
	uint32_t i1;
	uint32_t i2;
	
	unsigned const char *d;
	
	d = [_payload bytes];
	
	if( (_cursor+sizeof(uint16_t)) > [_payload length])
		return 0;
	
	i1 = d[_cursor++];
	i2 = d[_cursor++];
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
	
	d = [_payload bytes];
	
	if( (_cursor+sizeof(uint16_t) + 8) > [_payload length])
		return 0;
	
	i1 = d[_cursor++];
	i2 = d[_cursor++];
    i3 = d[_cursor++];
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
	
	d = [_payload bytes];
	
	if( (_cursor+sizeof(uint32_t)) > [_payload length])
		return 0;
    
	i1 = d[_cursor++];
	i2 = d[_cursor++];
	i3 = d[_cursor++];
	i4 = d[_cursor++];
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
    
    if(_payload==NULL)
	{
        return @"";
	}
	if(_cursor >= [_payload length])
    {
        return @"";
    }
	in_string = & ((unsigned char *)[_payload bytes])[_cursor];
	for(len=0;len<max;len++)
    {
		if(in_string[len] == '\0')
		{
			break;
		}
        ++_cursor;
    }
    ++_cursor;        /* \0 */
	s = [[NSString alloc] initWithBytes:in_string length:len encoding:enc];
	return s;
}

-(NSData *)grabOctetStringWithLength:(int)len
{
    unsigned const char *in_string;
    NSData *d;
    
    in_string = & ((unsigned char *)[_payload bytes])[_cursor];
    _cursor += len;
    d = [[NSData alloc] initWithBytes:in_string length:len];
    
    return d;
}

- (void) resetCursor
{
	_cursor = 0;
}

- (int)unpackDeliverSm
{
    return [self unpackDeliverSmUsingTlvDefinition:nil];
}

- (int)unpackDeliverSmUsingTlvDefinition:(NSDictionary *)tlvDefs;
{
    _service_type = [self grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:255];
	_source_addr_ton  = [self grabInt8];
	_source_addr_npi  = [self grabInt8];
	_source_addr = [self grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:40];
	_dest_addr_ton  = [self grabInt8];
	_dest_addr_npi  = [self grabInt8];
	_destination_addr = [self grabStringWithEncoding:NSISOLatin1StringEncoding	maxLength:31];
	_esm_class = (int)[self grabInt8];
    _protocol_id = [self grabInt8];
    _priority_flag = [self grabInt8];
    _schedule_delivery_time = [self grabStringWithEncoding:NSUTF8StringEncoding maxLength:17];
    _validity_period = [self grabStringWithEncoding:NSUTF8StringEncoding maxLength:17];
    _registered_delivery = [self grabInt8];
    _replace_if_present_flag = [self grabInt8];
    _data_coding = [self grabInt8];
    _sm_default_msg_id = [self grabInt8];;
    _sm_length = [self grabInt8];
    _short_message = [self grabOctetStringWithLength:(int)_sm_length];
    
    if (_sm_length != [_short_message length])
    {
        return -1;
    }
    [self grabTlvsWithDefinitions:tlvDefs];
    return 0;
}

- (void) grabTlvsWithDefinitions:(NSDictionary *)tlvDefs
{
    if(_tlvs == NULL)
    {
        _tlvs = [[NSMutableDictionary alloc]init];
    }
    int len = (int)[_payload length];
    id  val;
    
    while (_cursor + 4 < len)
    {
        unsigned long opt_len;
        SMPP_TLV_Tag opt_tag;
        opt_tag = (SMPP_TLV_Tag)[self grabInt16];
        opt_len = [self grabInt16];
        
        if (opt_tag == SMPP_TLV_USER_MESSAGE_REFERENCE)
        {
            if (opt_len > 2)
            {
                _cursor  += opt_len;
                continue;
            }
            _user_message_reference = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _user_message_reference];
            _tlvs[@"user message reference"] = val;
        }
        else if (opt_tag == SMPP_TLV_SOURCE_PORT)
        {
            if (opt_len > 2)
            {
                _cursor  += opt_len;
                continue;
            }
            _source_port = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _source_port];
            _tlvs[@"source port"] = val;
        }
        else if (opt_tag == SMPP_TLV_DESTINATION_PORT)
        {
            if (opt_len > 2)
            {
                _cursor  += opt_len;
                continue;
            }
            _destination_port = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _destination_port];
            _tlvs[@"destination port"] = val;
        }
        else if (opt_tag == SMPP_TLV_SAR_MSG_REF_NUM)
        {
            if (opt_len > 2)
            {
                _cursor  += opt_len;
                continue;
            }
            _sar_msg_ref_num = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _sar_msg_ref_num];
            _tlvs[@"sar msg ref num"] = val;
        }
        else if (opt_tag == SMPP_TLV_SAR_TOTAL_SEGMENTS)
        {
            if (opt_len > 1)
            {
                _cursor  += opt_len;
                continue;
            }
            _sar_total_segments = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _sar_total_segments];
            _tlvs[@"sar total segments"] = val;
        }
        else if (opt_tag == SMPP_TLV_SAR_SEGMENT_SEQNUM)
        {
            if (opt_len > 1)
            {
                _cursor  += opt_len;
                continue;
            }
            _sar_segment_seqnum = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _sar_segment_seqnum];
            _tlvs[@"sar segement seqnum"] = val;
        }
        else if (opt_tag == SMPP_TLV_USER_RESPONSE_CODE)
        {
            if (opt_len > 1)
            {
                _cursor  += opt_len;
                continue;
            }
            _user_response_code = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _user_response_code];
            _tlvs[@"user response code"] = val;
        }
        else if (opt_tag == SMPP_TLV_PRIVACY_INDICATOR)
        {
            if (opt_len > 1)
            {
                _cursor  += opt_len;
                continue;
            }
            _privacy_indicator = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _privacy_indicator];
            _tlvs[@"privacy indicator"] = val;
        }
        else if (opt_tag == SMPP_TLV_PAYLOAD_TYPE)
        {
            if (opt_len > 1)
            {
                _cursor  += opt_len;
                continue;
            }
            _payload_type = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _payload_type];
            _tlvs[@"payload type"] = val;
        }
        else if (opt_tag == SMPP_TLV_MESSAGE_PAYLOAD)
        {
            if (opt_len > 65536 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _message_payload = [self grabOctetStringWithLength:(int)opt_len];
            _tlvs[@"message payload"] = _message_payload;
        }
        else if (opt_tag == SMPP_TLV_CALLBACK_NUM)
        {
            if (opt_len < 4 || opt_len > 19 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _callback_num = [self grabOctetStringWithLength:(int)opt_len];
            _tlvs[@"callback num"] = _callback_num;
        }
        else if (opt_tag == SMPP_TLV_SOURCE_SUBADDRESS)
        {
            if (opt_len < 2 || opt_len > 23 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _source_subaddress = [self grabOctetStringWithLength:(int)opt_len];
            _tlvs[@"source subaddress"] = _source_subaddress;
        }
        else if (opt_tag == SMPP_TLV_DEST_SUBADDRESS)
        {
            if (opt_len < 2 || opt_len > 23 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _dest_subaddress = [self grabOctetStringWithLength:(int)opt_len];
            _tlvs[@"dest subaddress"] = _dest_subaddress;
        }
        else if (opt_tag == SMPP_TLV_SOURCE_ADDR_SUBUNIT)
        {
            if (opt_len < 1 || opt_len > 1 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _source_addr_subunit = [self grabInt:(int)opt_len];
            _tlvs[@"source subunit"] = @(_source_addr_subunit);
        }

        else if (opt_tag == SMPP_TLV_DEST_ADDR_SUBUNIT)
        {
            if (opt_len < 1 || opt_len > 1 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _dest_addr_subunit = [self grabInt:(int)opt_len];
            _tlvs[@"dest subunit"] = @(_dest_addr_subunit);
        }

        else if (opt_tag == SMPP_TLV_LANGUAGE_INDICATOR)
        {
            if (opt_len > 1)
            {
                _cursor  += opt_len;
                continue;
            }
            _language_indicator = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _language_indicator];
            _tlvs[@"language indicator"] = val;
        }
        else if (opt_tag == SMPP_TLV_ITS_SESSION_INFO)
        {
            if (opt_len < 2 || opt_len > 2 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _its_session_info = [self grabOctetStringWithLength:(int)opt_len];
            _tlvs[@"its session info"] = _its_session_info;
        }
        else if (opt_tag == SMPP_TLV_NETWORK_ERROR_CODE)
        {
            if (opt_len < 3 || opt_len > 3 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _network_error_code = [self grabOctetStringWithLength:(int)opt_len];
            _tlvs[@"network error code"] = _network_error_code;
        }
        else if (opt_tag == SMPP_TLV_MESSAGE_STATE)
        {
            if (opt_len > 1)
            {
                _cursor  += opt_len;
                continue;
            }
            _message_state = [self grabInt:opt_len];
            val = [NSString stringWithFormat:@"%ld", _message_state];
            _tlvs[@"message state"] = val;
        }
        else if (opt_tag == SMPP_TLV_RECEIPTED_MESSAGE_ID)
        {
            if (opt_len > 65 || _cursor + opt_len > len)
            {
                _cursor  += opt_len;
                continue;
            }
            _receipted_message_id = [self grabStringWithEncoding:NSUTF8StringEncoding maxLength:(int)opt_len];
            _tlvs[@"receipted message id"] = _receipted_message_id;
        }
        else
        {
            
            NSNumber *optNumber = @((int)opt_tag);
            SmppTlv *t = tlvDefs[optNumber];
            if(t)
            {
                if(t.type==SMPP_TLV_NULLTERMINATED)
                {
                    NSMutableData *data = [[self grabOctetStringWithLength:(int)opt_len] mutableCopy];
                    [data appendByte:0]; /* failsafe */
                    NSString *stringValue =[NSString stringWithFormat:@"%s",(const char *)[data bytes]];
                    _tlvs[t.name] = stringValue;
                }
                else if(t.type==SMPP_TLV_INTEGER)
                {
                    NSNumber *num = @([self grabInt:opt_len]);
                    _tlvs[t.name] = num;
                }
                else// if(t.type==SMPP_TLV_OCTETS)
                {
                    NSData *data = [self grabOctetStringWithLength:(int)opt_len];
                    _tlvs[t.name] = data;
                }
            }
            else
            {
                NSString *optKey = [NSString stringWithFormat:@"0x%04X", (unsigned int)opt_tag];
                NSData *data = [self grabOctetStringWithLength:(int)opt_len];
                _tlvs[optKey] = data;
            }
        }
    }
}

+ (NSString *)errorToString:(UMSmppError)err
{
    return UMSmppErrorAsString(err);
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
    
    [desc appendFormat:@" len:     %08lX\n", (unsigned long)_pdulen];
    [desc appendFormat:@" type:    %08lX %@\n", (unsigned long)_type,[SmppPdu pduTypeToString:_type]];
	[desc appendFormat:@" error:   %08lX %@\n", (unsigned long)_err, [SmppPdu errorToString:_err]];
	[desc appendFormat:@" seq:     %08lX\n", (unsigned long)_seq];
	[desc appendFormat:@" payload: %@\n", _payload];
    
    if (_type == SMPP_PDU_BIND_TRANSMITTER || _type == SMPP_PDU_BIND_RECEIVER || _type == SMPP_PDU_BIND_TRANSCEIVER)
    {
        [desc appendFormat:@"system id is %@\n", _system_id];
        [desc appendFormat:@"password %@\n", _password ? @"exists" : @"does not exist"];
        [desc appendFormat:@"system type is %@\n", _system_type];
        [desc appendFormat:@"interface version is %ld\n", _interface_version];
        [desc appendFormat:@"addr npi is %ld\n", _addr_npi];
        [desc appendFormat:@"addr ton is %ld\n", _addr_ton];
        [desc appendFormat:@"system type is %@\n", _address_range];
    }
    else if (_type == SMPP_PDU_BIND_TRANSMITTER_RESP || _type == SMPP_PDU_BIND_RECEIVER_RESP || _type == SMPP_PDU_BIND_TRANSCEIVER_RESP)
    {
        [desc appendFormat:@"system id is %@\n", _system_id];
        [desc appendFormat:@"sc interface version is %ld\n", _sc_interface_version];
    }
    else if (_type == SMPP_PDU_OUTBIND)
    {
        [desc appendFormat:@"system id is %@\n", _system_id];
        [desc appendFormat:@"password %@\n", _password ? @"exists" : @"does not exist"];
    }
    else if (_type == SMPP_PDU_SUBMIT_SM)
    {
        [desc appendFormat:@"service type is %@\n", _service_type];
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", _dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", _dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", _destination_addr];
        [desc appendFormat:@"esm class is %ld\n", _esm_class];
        [desc appendFormat:@"source protocol id is %ld\n", _protocol_id];
        [desc appendFormat:@"priority flag is %ld\n", _priority_flag];
        [desc appendFormat:@"scheduled delivery time is %@\n", _schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", _validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", _registered_delivery];
        [desc appendFormat:@"replace if present is %ld\n", _replace_if_present_flag];
        [desc appendFormat:@"data coding is %ld\n", _data_coding];
        [desc appendFormat:@"sm default sm id is %ld\n", _sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", _sm_length];
        [desc appendFormat:@"short message is %@\n", _short_message];
        [desc appendFormat:@"user message reference is %ld\n", _user_message_reference];
        [desc appendFormat:@"source port is %ld\n", _source_port];
        [desc appendFormat:@"source address subunit is is %ld\n", _source_addr_subunit];
        [desc appendFormat:@"destination port is %ld\n", _destination_port];
        [desc appendFormat:@"destination address subunit is %ld\n", _dest_addr_subunit];
        [desc appendFormat:@"SAR message reference number is %ld\n", _sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", _sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", _sar_segment_seqnum];
        [desc appendFormat:@"more messages to send is %ld\n", _more_messages_to_send];
        [desc appendFormat:@"payload type is %ld\n", _payload_type];
        [desc appendFormat:@"message payload is %@\n",_message_payload];
        [desc appendFormat:@"privacy indicator is %ld\n", _privacy_indicator];
        [desc appendFormat:@"callbacl number is %@\n", _callback_num];
        [desc appendFormat:@"callback number presence indicator is %ld\n", _callback_num_pres_ind];
        [desc appendFormat:@"callbacl number atag %@\n", _callback_num_atag];
        [desc appendFormat:@"source subaddress is %@\n", _source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", _dest_subaddress];
        [desc appendFormat:@"user response code is %ld\n", _user_response_code];
        [desc appendFormat:@"display time is %ld\n", _display_time];
        [desc appendFormat:@"sms signal is %ld\n", _sms_signal];
        [desc appendFormat:@"ms validity is %ld\n", _ms_validity];
        [desc appendFormat:@"ms msg wait facilities is %ld\n", _ms_msg_wait_facilities];
        [desc appendFormat:@"number of messages is %ld\n", _number_of_messages];
        [desc appendFormat:@"alert on message delivery is %ld\n", _alert_on_message_delivery];
        [desc appendFormat:@"language indicator is %ld\n", _language_indicator];
        [desc appendFormat:@"its reply type is %ld\n", _its_reply_type];
        [desc appendFormat:@"source subaddress is %@\n", _its_session_info];
        [desc appendFormat:@"ussd service op is %@\n", _ussd_service_op];
    }
    else if (_type == SMPP_PDU_SUBMIT_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", _message_id];
    }
    else if (_type == SMPP_PDU_SUBMIT_SM_MULTI)
    {
        [desc appendFormat:@"service type is %@\n", _service_type];
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
        [desc appendFormat:@"number of dests is %ld\n", _number_of_dests];
        [desc appendFormat:@"dest address es is %@\n", _dest_address_es];
        [desc appendFormat:@"esm class is %ld\n", _esm_class];
        [desc appendFormat:@"source protocol id is %ld\n", _protocol_id];
        [desc appendFormat:@"priority flag is %ld\n", _priority_flag];
        [desc appendFormat:@"scheduled delivery time is %@\n", _schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", _validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", _registered_delivery];
        [desc appendFormat:@"replace if present is %ld\n", _replace_if_present_flag];
        [desc appendFormat:@"data coding is %ld\n", _data_coding];
        [desc appendFormat:@"sm default sm id is %ld\n", _sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", _sm_length];
        [desc appendFormat:@"short message is %@\n", _short_message];
        [desc appendFormat:@"user message reference is %ld\n", _user_message_reference];
        [desc appendFormat:@"source port is %ld\n", _source_port];
        [desc appendFormat:@"source address subunit is is %ld\n", _source_addr_subunit];
        [desc appendFormat:@"destination port is %ld\n", _destination_port];
        [desc appendFormat:@"destination address subunit is %ld\n", _dest_addr_subunit];
        [desc appendFormat:@"SAR message reference number is %ld\n", _sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", _sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", _sar_segment_seqnum];
        [desc appendFormat:@"payload type is %ld\n", _payload_type];
        [desc appendFormat:@"message payload is %@\n",_message_payload];
        [desc appendFormat:@"privacy indicator is %ld\n", _privacy_indicator];
        [desc appendFormat:@"callbacl number is %@\n", _callback_num];
        [desc appendFormat:@"callback number presence indicator is %ld\n", _callback_num_pres_ind];
        [desc appendFormat:@"callbacl number atag %@\n", _callback_num_atag];
        [desc appendFormat:@"source subaddress is %@\n", _source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", _dest_subaddress];
        [desc appendFormat:@"user response code is %ld\n", _user_response_code];
        [desc appendFormat:@"display time is %ld\n", _display_time];
        [desc appendFormat:@"sms signal is %ld\n", _sms_signal];
        [desc appendFormat:@"ms validity is %ld\n", _ms_validity];
        [desc appendFormat:@"ms msg wait facilities is %ld\n", _ms_msg_wait_facilities];
        [desc appendFormat:@"alert on message delivery is %ld\n", _alert_on_message_delivery];
        [desc appendFormat:@"language indicator is %ld\n", _language_indicator];
    }
    else if (_type == SMPP_PDU_SUBMIT_SM_MULTI_RESP)
    {
        [desc appendFormat:@"message id is %@\n", _message_id];
        [desc appendFormat:@"no unsuccess is %ld\n", _no_unsuccess];
    }
    else if (_type == SMPP_PDU_DELIVER_SM)
    {
        [desc appendFormat:@"service type is %@\n", _service_type];
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", _dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", _dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", _destination_addr];
        [desc appendFormat:@"esm class is %ld\n", _esm_class];
        [desc appendFormat:@"source protocol id is %ld\n", _protocol_id];
        [desc appendFormat:@"priority flag is %ld\n", _priority_flag];
        [desc appendFormat:@"scheduled delivery time is %@\n", _schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", _validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", _registered_delivery];
        [desc appendFormat:@"replace if present is %ld\n", _replace_if_present_flag];
        [desc appendFormat:@"data coding is %ld\n", _data_coding];
        [desc appendFormat:@"sm default sm id is %ld\n", _sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", _sm_length];
        [desc appendFormat:@"short message is %@\n", _short_message];
        [desc appendFormat:@"user message reference is %ld\n", _user_message_reference];
        [desc appendFormat:@"source port is %ld\n", _source_port];
        [desc appendFormat:@"destination port is %ld\n", _destination_port];
        [desc appendFormat:@"SAR message reference number is %ld\n", _sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", _sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", _sar_segment_seqnum];
        [desc appendFormat:@"user response code is %ld\n", _user_response_code];
        [desc appendFormat:@"privacy indicator is %ld\n", _privacy_indicator];
        [desc appendFormat:@"payload type is %ld\n", _payload_type];
        [desc appendFormat:@"message payload is %@\n",_message_payload];
        [desc appendFormat:@"callbacl number is %@\n", _callback_num];
        [desc appendFormat:@"source subaddress is %@\n", _source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", _dest_subaddress];
        [desc appendFormat:@"language indicator is %ld\n", _language_indicator];
        [desc appendFormat:@"source subaddress is %@\n", _its_session_info];
        [desc appendFormat:@"network error code is %@\n", _network_error_code];
        [desc appendFormat:@"message state is %ld\n", _message_state];
        [desc appendFormat:@"receipted message id is %@\n", _receipted_message_id];
    }
    else if (_type == SMPP_PDU_DELIVER_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", _message_id];
    }
    else if (_type == SMPP_PDU_DATA_SM)
    {
        [desc appendFormat:@"service type is %@\n", _service_type];
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", _dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", _dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", _destination_addr];
        [desc appendFormat:@"esm class is %ld\n", _esm_class];
        [desc appendFormat:@"registered delivery is %ld\n", _registered_delivery];
        [desc appendFormat:@"data coding is %ld\n", _data_coding];
        [desc appendFormat:@"source port is %ld\n", _source_port];
        [desc appendFormat:@"source address subunit is is %ld\n", _source_addr_subunit];
        [desc appendFormat:@"source network type is %ld\n", _source_network_type];
        [desc appendFormat:@"source bearer type is %ld\n", _source_bearer_type];
        [desc appendFormat:@"source telematics id is %ld\n", _source_telematics_id];
        [desc appendFormat:@"destination network type is %ld\n", _dest_network_type];
        [desc appendFormat:@"destination bearer type is %ld\n", _dest_bearer_type];
        [desc appendFormat:@"destination telematics id is %ld\n", _dest_telematics_id];
        [desc appendFormat:@"SAR message reference number is %ld\n", _sar_msg_ref_num];
        [desc appendFormat:@"SAR total segments is %ld\n", _sar_total_segments];
        [desc appendFormat:@"SAR seqment seqnum is %ld\n", _sar_segment_seqnum];
        [desc appendFormat:@"more messages to send is %ld\n", _more_messages_to_send];
        [desc appendFormat:@"quality of service, time to live is %ld\n", _qos_time_to_live];
        [desc appendFormat:@"payload type is %ld\n", _payload_type];
        [desc appendFormat:@"message payload is %@\n",_message_payload];
        [desc appendFormat:@"set pdf is %ld\n", _set_dpf];
        [desc appendFormat:@"receipted message id is %@\n", _receipted_message_id];
        [desc appendFormat:@"message state is %ld\n", _message_state];
        [desc appendFormat:@"network error code is %@\n", _network_error_code];
        [desc appendFormat:@"user message reference is %ld\n", _user_message_reference];
        [desc appendFormat:@"privacy indicator is %ld\n", _privacy_indicator];
        [desc appendFormat:@"callbacl number is %@\n", _callback_num];
        [desc appendFormat:@"callback number presence indicator is %ld\n", _callback_num_pres_ind];
        [desc appendFormat:@"callbacl number atag %@\n", _callback_num_atag];
        [desc appendFormat:@"source subaddress is %@\n", _source_subaddress];
        [desc appendFormat:@"destination subaddress is %@\n", _dest_subaddress];
        [desc appendFormat:@"user response code is %ld\n", _user_response_code];
        [desc appendFormat:@"display time is %ld\n", _display_time];
        [desc appendFormat:@"sms signal is %ld\n", _sms_signal];
        [desc appendFormat:@"ms validity is %ld\n", _ms_validity];
        [desc appendFormat:@"ms msg wait facilities is %ld\n", _ms_msg_wait_facilities];
        [desc appendFormat:@"alert on message delivery is %ld\n", _alert_on_message_delivery];
        [desc appendFormat:@"language indicator is %ld\n", _language_indicator];
        [desc appendFormat:@"its reply type is %ld\n", _its_reply_type];
        [desc appendFormat:@"source subaddress is %@\n", _its_session_info];
    }
    else if (_type == SMPP_PDU_DATA_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", _message_id];
        [desc appendFormat:@"delivery failure reason is %ld\n", _delivery_failure_reason];
        [desc appendFormat:@"network error code is %@\n", _network_error_code];
        [desc appendFormat:@"additional satus info text is %@\n", _additional_status_info_text];
        [desc appendFormat:@"dpf result is %ld\n", _dpf_result];
    }
    else if (_type == SMPP_PDU_QUERY_SM)
    {
        [desc appendFormat:@"message id is %@\n", _message_id];
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
    }
    else if (_type == SMPP_PDU_QUERY_SM_RESP)
    {
        [desc appendFormat:@"message id is %@\n", _message_id];
        [desc appendFormat:@"final date is info text is %@\n", _final_date];
        [desc appendFormat:@"message state is %ld\n", _message_state];
        [desc appendFormat:@"error code is %ld\n", _error_code];
    }
    else if (_type == SMPP_PDU_CANCEL_SM)
    {
        [desc appendFormat:@"service type is %@\n", _service_type];
        [desc appendFormat:@"message id is %@\n", _message_id];
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
        [desc appendFormat:@"destnation addr ton is %ld\n", _dest_addr_ton];
        [desc appendFormat:@"destination addr npi is %ld\n", _dest_addr_npi];
        [desc appendFormat:@"destination addr is %@\n", _destination_addr];
    }
    else if (_type == SMPP_PDU_REPLACE_SM)
    {
        [desc appendFormat:@"service type is %@\n", _service_type];
        [desc appendFormat:@"message id is %@\n", _message_id];
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
        [desc appendFormat:@"scheduled delivery time is %@\n", _schedule_delivery_time];
        [desc appendFormat:@"validity period is %@\n", _validity_period];
        [desc appendFormat:@"registered delivery is %ld\n", _registered_delivery];
        [desc appendFormat:@"sm default sm id is %ld\n", _sm_default_msg_id];
        [desc appendFormat:@"sm length is %ld\n", _sm_length];
        [desc appendFormat:@"short message is %@\n", _short_message];
    }
    else if (_type == SMPP_PDU_ALERT_NOTIFICATION)
    {
        [desc appendFormat:@"source addr ton is %ld\n", _source_addr_ton];
        [desc appendFormat:@"source addr npi is %ld\n", _source_addr_npi];
        [desc appendFormat:@"system type is %@\n", _source_addr];
        [desc appendFormat:@"esme addr ton is %ld\n", _esme_addr_ton];
        [desc appendFormat:@"esme addr npi is %ld\n", _esme_addr_npi];
        [desc appendFormat:@"esme addr is %@\n", esme_addr];
        [desc appendFormat:@"ms avability status is %ld\n", _ms_availability_status];
    }
    
    [desc appendFormat:@"tlvs dictionary for custom tlvs is %@\n", _tlvs];
    [desc appendString:@"SMPP PDU dump ends"];
    
    return desc;
}

- (NSString *)sequenceString
{
    return [NSString stringWithFormat:@"%08lx",(unsigned long)_seq];
}

- (void)setSequenceString:(NSString *)s
{
    unsigned long ul;
    sscanf([s UTF8String],"%08lx",&ul);
    _seq = ul;
}

+ (NSDate *)smppTimestampFromString:(NSString *)str
{
    @autoreleasepool
    {
        const char *ts = str.UTF8String;
        //int microsec;
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
            //microsec = t * 100000;
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


static UMSmppError SMPP_outgoingErrorCodeMapping(UMSmppError e)
{
    return e;
}
