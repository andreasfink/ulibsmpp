//
//  TestSMPPClient.m
//  MessageMover-3.8
//
//  Created by Aarno Syvänen on 31.08.12.
//
//

#import "TestSMPPClient.h"

#import "UMLogFeed.h"
#import "SmscConnectionSMPP.h"
#import "UMConfig.h"
#import "NSString+TestSMPPAdditions.h"

@implementation Tlvs

- (Tlvs *)initWithConfig:(UMConfig *)cfg
{
    NSDictionary *grp;
    NSArray *a0;
    SmppTlv *tlv;
    
    if (initialized)
        return 0;
    
    if ((self = [self init]))
    {
        [cfg allowMultiGroup:@"smpp-tlv"];
        a0 = [cfg getMultiGroups:@"smpp-tlv"];
        tlvs_by_tag = [[NSMutableDictionary alloc] init];
        tlvs_by_name = [[NSMutableDictionary alloc] init];
        tlvs = [[NSMutableArray alloc] init];
        
        while (a0 && (grp = [a0 objectAtIndex:0]))
        {
            tlv = [[SmppTlv alloc] init];
            NSString *tmp;
            NSString *smsc_id;
            long our_tag, our_length;
            NSMutableArray *a;
            
            NSString *our_name = [grp objectForKey:@"name"];
            if (our_name)
                goto failed;
            [tlv setName:our_name];
            
            if ((our_tag = [[grp objectForKey:@"tag"] integerValue]) == -1)
                goto failed;
            [tlv setTag:our_tag];
            
            if ((our_length = [[grp objectForKey:@"length"] integerValue]) == -1)
                goto failed;
            [tlv setLength:our_length];
            
            if (!(tmp = [grp objectForKey:@"type"]))
                goto failed;
            if ([tmp compare:@"octetstring"] == 0)
                [tlv setType:SMPP_TLV_OCTETS];
            else if ([tmp compare:@"nulterminated"] == 0)
                [tlv setType:SMPP_TLV_NULTERMINATED];
            else if ([tmp compare:@"integer"] == 0)
                [tlv setType:SMPP_TLV_INTEGER];
            else
                goto failed;
            
            [tlvs addObject:tlv];
            
            smsc_id = [grp objectForKey:@"smsc-id"];
            if (smsc_id)
                a = [[smsc_id componentsSeparatedByString:@";"] mutableCopy];
            else
            {
                a = [NSMutableArray array];
                [a addObject:@"default"];
            }
            
            while (a && (smsc_id = [a objectAtIndex:0]))
            {
                NSDictionary *tmp_dict;
                tmp_dict = [tlvs_by_name objectForKey:smsc_id];
                if (!tmp_dict)
                {
                    tmp_dict = [NSDictionary dictionary];
                    [tlvs_by_name setObject:tmp_dict forKey:smsc_id];
                }
                if ([[tmp_dict objectForKey:[tlv name]] equals:tlv])
                    goto failed;
                
                tmp_dict = [tlvs_by_tag objectForKey:smsc_id];
                if (!tmp_dict)
                {
                    tmp_dict = [NSDictionary dictionary];
                    [tlvs_by_name setObject:tmp_dict forKey:smsc_id];
                }
                tmp = [NSString stringWithFormat:@"%ld", [tlv tag]];
                if ([[tmp_dict objectForKey:tmp] equals:tlv])
                    goto failed;
            }
            
        }
    }
    
    initialized = 1;
    
    return self;
    
failed:
    [tlv release];
    [self dealloc];
    return nil;
}

- (int) shutdown
{
    if (initialized == 0)
        return 1;
    
    initialized = 0;
    [tlvs release];
    tlvs = nil;
    [tlvs_by_tag release];
    [tlvs_by_name release];
    tlvs_by_tag = tlvs_by_name = nil;
    [self dealloc];
    
    return 0;
}

- (SmppTlv *)tlvWithSmscId:(NSString *)smsc_id andName:(NSString *)iName
{
    SmppTlv *res;
    NSDictionary *tmp_dict;
    
    if (!tlvs_by_name || !iName)
        return nil;
    
    if (smsc_id)
    {
        tmp_dict = [tlvs_by_name objectForKey:smsc_id];
        if (tmp_dict)
            res = [tmp_dict objectForKey:iName];
    }
    
    if (!res)
    {
        /* try default smsc_id */
        smsc_id = [NSString stringWithCString:DEFAULT_SMSC_ID encoding:NSASCIIStringEncoding];
        tmp_dict = [tlvs_by_name objectForKey:smsc_id];
        if (tmp_dict)
            res = [tmp_dict objectForKey:iName];
    }
    
    return res;
}

- (SmppTlv *)tlvWithSmscId:(NSString *)smsc_id andTag:(long)iTag
{
    SmppTlv *res = NULL;
    NSDictionary *tmp_dict;
    NSString *tmp;
    
    if (!tlvs_by_tag)
        return nil;
    
    tmp = [NSString stringWithFormat:@"%ld", iTag];
    
    if (smsc_id)
    {
        tmp_dict = [tlvs_by_tag objectForKey:smsc_id];
        if (tmp_dict)
            res = [tmp_dict objectForKey:tmp];
    }
    
    if (!res)
    {
        /* try default smsc_id */
        smsc_id = [NSString stringWithCString:DEFAULT_SMSC_ID encoding:NSASCIIStringEncoding];
        tmp_dict = [tlvs_by_tag objectForKey:smsc_id];
        if (tmp_dict)
            res = [tmp_dict objectForKey:tmp];
    }
    
    return res;
}


@end

@interface TestSMPPClient (PRIVATE)

- (void) dumpPDUWithMessage:(NSString *)msg withId:(NSString *)sid withContent:(SmppPdu *)pdu;

- (TestSMPPClient *)initWithConn:(SmscConnectionSMPP *)iconn withHost:(NSString *)ihost withTransmitterPort:(int)itransmit_port withReceiverPort:(int)ireceive_port withSystemType:(NSString *)isystem_type withUsername:(NSString *)iusername withPassword:(NSString *)ipassword withAddressRange:(NSString *) iaddress_range withSourceAddrTon:(int)isource_addr_ton withSourceAddrNpi:(int)isource_addr_npi withDestAddrTon:(int)idest_addr_ton withDestAddrNpi:(int)idest_addr_npi withEnquireLinkInterval:(int)ienquire_link_interval withmaxPendingSubmits:(int)imax_pending_submits withVersion:(int)iversion withPriority:(int)ipriority withValidity:(int)ivalidity withNumber:(NSString *)imy_number withIdType:(int)ismpp_msg_id_type withAutodetectAddr:(int)iautodetect_addr withAltCharset:(NSString *)ialt_charset withAltAddrCharset:(NSString *)ialt_addr_charset withServiceType:(NSString *)iservice_type withTimeout:(long)iconnection_timeout withWaitAck:(long)iwait_ack withWaitAckAction:(int)iwait_ack_action withEsmClass:(int)iesm_class;

- (void) dealloc;

- (int) readPduWithLen:(long *)len withPDU:(SmppPdu **)pdu;
- (long) convertAddr:(NSMutableString *)addr fromSmsc:(NSString *)cid withTon:(long)ton withNpi:(long)npi withAlternateCharset:(NSString *)i_alt_addr_charset;
- (Msg *)convertPDU:(SmppPdu *)pdu toMsgWithResult:(long *)reason;
- (Msg *)convertDataSmPDU:(SmppPdu *)pdu toMsgWithResult:(long *)reason;
- (long) smppStatusToSmscconnFailureReason:(long)status;

@end

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

@implementation TestSMPPClient (PRIVATE)

- (void) dumpPDUWithMessage:(NSString *)msg withId:(NSString *)sid withContent:(SmppPdu *)pdu
{
#if DEBUG
    NSString *dump = [NSString stringWithFormat:@"SMPP[%@]: %@ %@", sid, msg, pdu];
    [logFeed debug:0 inSubsection:@"TeatSMPPClient" withText:dump];
#endif
}


- (TestSMPPClient *)initWithConn:(SmscConnectionSMPP *)iconn withHost:(NSString *)ihost withTransmitterPort:(int)itransmit_port withReceiverPort:(int)ireceive_port withSystemType:(NSString *)isystem_type withUsername:(NSString *)iusername withPassword:(NSString *)ipassword withAddressRange:(NSString *) iaddress_range withSourceAddrTon:(int)isource_addr_ton withSourceAddrNpi:(int)isource_addr_npi withDestAddrTon:(int)idest_addr_ton withDestAddrNpi:(int)idest_addr_npi withEnquireLinkInterval:(int)ienquire_link_interval withmaxPendingSubmits:(int)imax_pending_submits withVersion:(int)iversion withPriority:(int)ipriority withValidity:(int)ivalidity withNumber:(NSString *)imy_number withIdType:(int)ismpp_msg_id_type withAutodetectAddr:(int)iautodetect_addr withAltCharset:(NSString *)ialt_charset withAltAddrCharset:(NSString *)ialt_addr_charset withServiceType:(NSString *)iservice_type withTimeout:(long)iconnection_timeout withWaitAck:(long)iwait_ack withWaitAckAction:(int)iwait_ack_action withEsmClass:(int)iesm_class
{
    if ((self = [super init]))
    {
        transmitter = -1;
        receiver = -1;
        msgs_to_send = [[TestPrioQueue alloc] initWithComparator:sms_priority_compare];
        sent_msgs = [[NSDictionary alloc] init];
        [msgs_to_send addProducer];
        received_msgs = [[NSMutableArray alloc] init];
        message_id_counter = [[TestCounter alloc] init];
        [message_id_counter increase];
        host = [ihost copy];
        system_type = [isystem_type copy];
        username = [iusername copy];
        password = [ipassword copy];
        address_range = [iaddress_range copy];
        source_addr_ton = isource_addr_ton;
        source_addr_npi = isource_addr_npi;
        dest_addr_ton = idest_addr_ton;
        dest_addr_npi = idest_addr_npi;
        my_number = [imy_number copy];
        service_type = [iservice_type copy];
        transmit_port = itransmit_port;
        receive_port = ireceive_port;
        enquire_link_interval = ienquire_link_interval;
        max_pending_submits = imax_pending_submits;
        quitting = 0;
        version = iversion;
        priority = ipriority;
        validityperiod = ivalidity;
        conn = iconn;
        throttling_err_time = 0;
        smpp_msg_id_type = ismpp_msg_id_type;
        autodetect_addr = iautodetect_addr;
        alt_charset = [ialt_charset copy];
        alt_addr_charset = [ialt_addr_charset copy];
        connection_timeout = iconnection_timeout;
        wait_ack = iwait_ack;
        wait_ack_action = iwait_ack_action;
        bind_addr_ton = 0;
        bind_addr_npi = 0;
        use_ssl = 0;
        ssl_client_certkey_file = nil;
        load = [[TestLoad alloc] initWithHeuristics:NO];
        [load addInterval:1];
        esm_class = iesm_class;
    }
    return self;
}

- (void) dealloc
{
    [msgs_to_send release];
    [sent_msgs release];
    [received_msgs release];
    [message_id_counter release];
    [host release];
    [username release];
    [password release];
    [system_type release];
    [service_type release];
    [address_range release];
    [my_number release];
    [alt_charset release];
    [alt_addr_charset release];
    [ssl_client_certkey_file release];
    [load release];
    [super dealloc];
}

/*
 * Try to read an SMPP PDU from a SmscConnectionSMPP. Return -1 for error (caller
 * should close the connection), -2 for malformed PDU , 0 for no PDU to
 * ready yet, or 1 for PDU read and unpacked. 
 * Return a pointer to the PDU in `*pdu'. Use `*len' to store the length 
 * of the PDU to read (it may be possible to read the length, but not 
 * the rest of the PDU - we need to remember the lenght for the next call). 
 * `*len' should be zero at the first call.
 */
- (int) readPduWithLen:(long *)len withPDU:(SmppPdu **)pdu
{
    NSData *data;
    UMSocketError sErr;
    int ret;
    
    if (*len == 0) {
        *len = [conn readLen];
        if (*len == WRONG_SMPP_SIZE)
        {
            NSString *msg = [NSString stringWithFormat:@"TestSMPPClient: readPduWithClient: SMPP[%@]: Server sent garbage, ignored.", [conn cid]];
            [logFeed minorError:0 withText:msg];
            return -2;
        }
        else if (*len < 4) /* SMPP length is 4 bytes*/
        {
            return -1;
        }
    }
    
    data = [conn readDataWithLen:*len withError:&sErr];
    if (!data)
    {
        if (sErr != UMSocketError_no_error)
            return -1;
        return 0;
    }
    
    *len = 0;
    *pdu = [[SmppPdu alloc] initFromData:data];
    ret = [*pdu unpackWithSmscId:[conn cid] andTlvs:tlvs];
    if (ret == -1)
    {
        NSString *msg = [NSString stringWithFormat:@"TestSMPPClient: readPduWithClient: SMPP[%@]: PDU unpacking failed.", [conn cid]];
        [logFeed minorError:0 withText:msg];
        NSString *msg2 = [NSString stringWithFormat:@"SMPP[%@]: Failed PDU: \r\n %@", [conn cid], data];
        [logFeed debug:0 inSubsection:@"TestSMPPClient: readPduWithClient" withText:msg2];
        return -2;
    }
    
    return 1;
}

- (long) convertAddr:(NSMutableString *)addr fromSmsc:(NSString *)cid withTon:(long)ton withNpi:(long)npi withAlternateCharset:(NSString *)i_alt_addr_charset
{
    long reason = ESME_ROK;
    NSRange zeros;
    
    if (!addr)
        return reason;
    
    switch (ton)
    {
        case GSM_ADDR_TON_INTERNATIONAL:
            /*
             * Checks to perform:
             *   1) assume international number has at least 7 chars
             *   2) the whole source addr consist of digits, exception '+' in front
             */
            if ([addr length] < 7)
            {
                /* We consider this as a "non-hard" condition, since there "may"
                 * be international numbers routable that are < 7 digits. Think
                 * of 2 digit country code + 3 digit emergency code. */
                NSString *msg = [NSString stringWithFormat:@"TestSMPPClient: convertAddr: SMPP[%@]: Malformed addr `%@', generally expected at least 7 digits", [conn cid], addr];
                [logFeed warning:0 withText:msg];
            }
            else if ([addr characterAtIndex:0] == '+' && ![addr checkRange:NSMakeRange(1, 256) withFunction:isdigit])
            {
                NSString *msg = [NSString stringWithFormat:@"TestSMPPClient: convertAddr: SMPP[%@]: Mallformed addr `%@', expected all digits.",  [conn cid], addr];
                [logFeed minorError:0 withText:msg];
                reason = ESME_RINVSRCADR;
                goto error;
            }
            else if ([addr characterAtIndex:0] != '+' && ![addr checkRange:NSMakeRange(1, 256) withFunction:isdigit])
            {
                NSString *msg = [NSString stringWithFormat:@"TestSMPPClient: convertAddr: SMPP[%@]: Mallformed addr `%@', expected all digits.", [conn cid], addr];
                [logFeed minorError:0 withText:msg];
                reason = ESME_RINVSRCADR;
                goto error;
            }
            
            /* check if we received leading '00', then remove it*/
            zeros = [addr rangeOfString:@"00"];
            if (zeros.location == 0)
                [addr deleteCharactersInRange:NSMakeRange(0, 2)];
            
            /* international, insert '+' if not already here */
            if ([addr characterAtIndex:0] != '+')
                [addr insertString:@"+" atIndex:0];
            
            break;
            
        case GSM_ADDR_TON_ALPHANUMERIC:
            if ([addr length] > 11)
            {
                /* alphanum sender, max. allowed length is 11 (according to GSM specs) */
                NSString *msg = [NSString stringWithFormat:@"TestSMPPClient: convertAddr: SMPP[%@]: Mallformed addr `%@', alphanum length greater 11 chars.",  [conn cid], addr];
                [logFeed minorError:0 withText:msg];
                reason = ESME_RINVSRCADR;
                goto error;
            }
            if (i_alt_addr_charset)
            {
                if ([i_alt_addr_charset compare:@"gsm"] == NSOrderedSame)
                    [addr convertFromGsmToUTF8];
                else if ([addr convertFrom:(char *)[i_alt_addr_charset UTF8String] to:SMPP_DEFAULT_CHARSET] != 0)
                {
                    NSString *msg = [NSString stringWithFormat:@"TestSMPPClient: convertAddr: Failed to convert address from charset <%@> to <%s>, leave as is.", i_alt_addr_charset, SMPP_DEFAULT_CHARSET];
                    [logFeed minorError:0 withText:msg];
                }
            }
            break;
        default: /* otherwise don't touch addr, user should handle it */
            break;
    }
error:
    return reason;
}

/*
 * Convert SMPP PDU to internal Msgs structure.
 * Return the Msg if all was fine and NULL otherwise, while getting
 * the failing reason delivered back in *reason.
 * XXX semantical check on the incoming values can be extended here.
 */
- (Msg *)convertPDU:(SmppPdu *)pdu toMsgWithResult:(long *)reason
{
    Msg *msg;
    int ton, npi;
    
    if ([pdu type] != SMPP_PDU_DELIVER_SM)
        return nil;
    
    msg = [[[Msg alloc] initWithType:sms] autorelease];
    *reason = ESME_ROK;
    
    /*
     * Reset source addr to have a prefixed '+' in case we have an
     * intl. TON to allow backend boxes (ie. smsbox) to distinguish
     * between national and international numbers.
     */
    ton = (int)[pdu source_addr_ton];
    npi = (int)[pdu source_addr_npi];
    
    /* check source addr */
    if ((*reason = [self convertAddr:[[[pdu source_addr] mutableCopy] autorelease] fromSmsc:[conn cid] withTon:ton withNpi:npi withAlternateCharset:
            [conn altAddrCharset]]) != ESME_ROK)
        goto error;
    [msg setSender:[pdu source_addr]];
    [pdu setSource_addr:nil];
    
    /*
     * Follows SMPP spec. v3.4. issue 1.2
     * it's not allowed to have destination_addr nil
     */
    if (![pdu destination_addr])
    {
        *reason = ESME_RINVDSTADR;
        goto error;
    }
    
    /* Same reset of destination number as for source */
    ton = (int)[pdu dest_addr_ton];
    npi = (int)[pdu dest_addr_npi];
    
    /* check destination addr */
    if ((*reason = [self convertAddr:[[[pdu destination_addr] mutableCopy] autorelease] fromSmsc:[conn cid] withTon:ton withNpi:npi withAlternateCharset:
            [conn altAddrCharset]]) != ESME_ROK)
        goto error;
    [msg setReceiver:[pdu destination_addr]];
    [pdu setDestination_addr:nil];
    
    /* SMSCs use service_type for billing information */
    [msg setBinfo:[pdu service_type]];
    [pdu setService_type:nil];
    
    /* Foreign ID on MO */
    [msg setForeign_id:[pdu receipted_message_id]];
    [pdu setReceipted_message_id:nil];
    
    if ([pdu esm_class] & SMPP_PDU_ESM_CLASS_SUBMIT_RPI )
        [msg setRpi:1];
    
    /*
     * Check for message_payload if version > 0x33 and sm_length == 0
     * Note: SMPP spec. v3.4. doesn't allow to send both: message_payload & short_message!
     */
    if ([[conn version] integerValue] > 0x33 && [pdu sm_length] == 0 && [pdu message_payload])
    {
        [msg setMsgdata:[[[pdu message_payload] mutableCopy] autorelease]];
        [pdu setMessage_payload:nil];
    }
    else
    {
        [msg setMsgdata:[[[pdu short_message] mutableCopy] autorelease]];
        [pdu setShort_message:nil];
    }
    
    /*
     * Encode udh if udhi set
     * for reference see GSM03.40, section 9.2.3.24
     */
    if ([pdu esm_class] & SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR)
    {
        int udhl;
        char *buff = malloc(1);;
        
        [[msg msgdata] getBytes:buff range:NSMakeRange(0, 1)];
        udhl = atoi(buff) + 1;
        if (udhl > [[msg msgdata] length])
        {
            *reason = ESME_RINVESMCLASS;
            goto error;
        }
        [msg setUdhdata:[[msg msgdata] subdataWithRange:NSMakeRange(0, udhl)]];
        [[msg msgdata] replaceBytesInRange:NSMakeRange(0, udhl) withBytes:nil length:0];
    }
    
    [msg dcsToFieldsWithDcs:(int)[pdu data_coding]];
    
    /* handle default data coding */
    switch ([pdu data_coding])
    {
        case 0x00: /* default SMSC alphabet */
            /*
             * try to convert from something interesting if specified so
             * unless it was specified binary, ie. UDH indicator was detected
             */
            if ([conn altCharset] && [msg coding] != DC_8BIT)
            {
                if ([[msg msgdata] convertFrom:(char *)[[conn altCharset] UTF8String] to:SMPP_DEFAULT_CHARSET] != 0)
                {
                    NSString *txt = [NSString stringWithFormat:@"ailed to convert msgdata from charset <%@> to <%s>, will leave as is", [conn altCharset], SMPP_DEFAULT_CHARSET];
                    [logFeed minorError:0 withText:txt];
                }
                [msg setCoding:DC_7BIT];
            }
            else
            { /* assume GSM 03.38 7-bit alphabet */
                [[msg msgdata] convertFromGsmToUTF8];
                [msg setCoding:DC_7BIT];
            }
            break;
            
        case 0x01: /* ASCII or IA5 - not sure if I need to do anything */
            [msg setCoding:DC_7BIT]; break;
            
        case 0x03: /* ISO-8859-1 - I'll convert to unicode */
            if ([[msg msgdata] convertFrom:"ISO-8859-1" to:SMPP_DEFAULT_CHARSET] != 0)
            {
                NSString *txt = [NSString stringWithFormat:@"Failed to convert msgdata from ISO-8859-1 to " SMPP_DEFAULT_CHARSET ", will leave as is"];
                [logFeed minorError:0 withText:txt];
            }
            [msg setCoding:DC_7BIT]; break;
            
        case 0x02: /* 8 bit binary - do nothing */
            
        case 0x04: /* 8 bit binary - do nothing */
            [msg setCoding:DC_8BIT]; break;
            
        case 0x05: /* JIS - what do I do with that ? */
            break;
            
        case 0x06: /* Cyrllic - iso-8859-5, I'll convert to unicode */
            if ([[msg msgdata] convertFrom:"iso-8859-5" to:SMPP_DEFAULT_CHARSET] != 0)
            {
                NSString *txt = [NSString stringWithFormat:@"Failed to convert msgdata from cyrllic to " SMPP_DEFAULT_CHARSET ", will leave as is"];
                [logFeed minorError:0 withText:txt];
            }
            [msg setCoding:DC_7BIT]; break;
            
        case 0x07: /* Hebrew iso-8859-8, I'll convert to unicode */
            if ([[msg msgdata] convertFrom:"iso-8859-8" to:SMPP_DEFAULT_CHARSET] != 0)
            {
                NSString *txt = [NSString stringWithFormat:@"Failed to convert msgdata from hebrew to " SMPP_DEFAULT_CHARSET ", will leave as is"];
                [logFeed minorError:0 withText:txt];
            }
            [msg setCoding:DC_7BIT]; break;
            
        case 0x08: /* unicode UCS-2, yey */
            [msg setCoding:DC_UCS2]; break;
            
            /*
             * don't much care about the others,
             * you implement them if you feel like it
             */
        default:
            /*
             * some of smsc send with dcs from GSM 03.38 , but these are reserved in smpp spec.
             * So we just look decoded values from dcs_to_fields and if none there make our assumptions.
             * if we have an UDH indicator, we assume DC_8BIT.
             */
            if ([msg coding] == DC_UNDEF && [pdu esm_class] & SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR)
                [msg setCoding:DC_8BIT];
            else if ([msg coding] == DC_7BIT || [msg coding] == DC_UNDEF)
            { /* assume GSM 7Bit , reencode */
                [msg setCoding:DC_7BIT];
                [[msg msgdata] convertFromGsmToUTF8];
            }
    }

    [msg setPid:[pdu protocol_id]];
    
    /* set priority flag */
    [msg setPriority:[pdu priority_flag]];
    
    if (![msg meta_data])
        [msg setMeta_data:[NSMutableString string]];
    
    [[msg meta_data] setMetaDataValuesIn:[pdu tlv] fromGroup:"smpp" replaceExisting:YES];
    
    return msg;
    
error:
    return nil;
}

/*
 * Convert SMPP PDU to internal Msgs structure.
 * Return the Msg if all was fine and NULL otherwise, while getting
 * the failing reason delivered back in *reason.
 * XXX semantical check on the incoming values can be extended here.
 */
- (Msg *)convertDataSmPDU:(SmppPdu *)pdu toMsgWithResult:(long *)reason
{
    Msg *msg;
    int ton, npi;
    
    if ([pdu type] != SMPP_PDU_DATA_SM)
        return nil;
    
    msg = [[[Msg alloc] initWithType:sms] autorelease];
    if (!msg)
        return NULL;
    *reason = ESME_ROK;
    
    /*
     * Reset source addr to have a prefixed '+' in case we have an
     * intl. TON to allow backend boxes (ie. smsbox) to distinguish
     * between national and international numbers.
     */
    ton = (int)[pdu source_addr_ton];
    npi = (int)[pdu source_addr_npi];
    
    /* check source addr */
    if ((*reason = [self convertAddr:[[[pdu source_addr] mutableCopy] autorelease] fromSmsc:[conn cid]
            withTon:ton withNpi:npi withAlternateCharset: [conn altAddrCharset]]) != ESME_ROK)
        goto error;
    [msg setSender:[pdu source_addr]];
    [pdu setSource_addr:nil];
    
    /*
     * Follows SMPP spec. v3.4. issue 1.2
     * it's not allowed to have destination_addr NULL
     */
    if (![pdu destination_addr])
    {
        *reason = ESME_RINVDSTADR;
        goto error;
    }
    
    /* Same reset of destination number as for source */
    ton = (int)[pdu dest_addr_ton];
    npi = (int)[pdu dest_addr_npi];
    
    /* check destination addr */
    if ((*reason = [self convertAddr:[[[pdu destination_addr] mutableCopy] autorelease] fromSmsc:[conn cid] withTon:ton withNpi:npi withAlternateCharset:
                    [conn altAddrCharset]]) != ESME_ROK)
        goto error;
    [msg setReceiver:[pdu destination_addr]];
    [pdu setDestination_addr:nil];
    
     /* SMSCs use service_type for billing information */
    [msg setBinfo:[pdu service_type]];
    [pdu setService_type:nil];
    
    /* Foreign ID on MO */
    [msg setForeign_id:[pdu receipted_message_id]];
    [pdu setReceipted_message_id:nil];
    
    if ([pdu esm_class] & SMPP_PDU_ESM_CLASS_SUBMIT_RPI )
        [msg setRpi:1];
    
    [msg setMsgdata:[[[pdu message_payload] mutableCopy] autorelease]];
    [pdu setMessage_payload:nil];
    
    /*
     * Encode udh if udhi set
     * for reference see GSM03.40, section 9.2.3.24
     */
    if ([pdu esm_class] & SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR)
    {
        int udhl;
        char *buff = malloc(1);;
        
        [[msg msgdata] getBytes:buff range:NSMakeRange(0, 1)];
        udhl = atoi(buff) + 1;
        if (udhl > [[msg msgdata] length])
        {
            *reason = ESME_RINVESMCLASS;
            goto error;
        }
        [msg setUdhdata:[[msg msgdata] subdataWithRange:NSMakeRange(0, udhl)]];
        [[msg msgdata] replaceBytesInRange:NSMakeRange(0, udhl) withBytes:nil length:0];
    }

    [msg dcsToFieldsWithDcs:(int)[pdu data_coding]];
    
    /* handle default data coding */
    switch ([pdu data_coding])
    {
        case 0x00: /* default SMSC alphabet */
            /*
             * try to convert from something interesting if specified so
             * unless it was specified binary, ie. UDH indicator was detected
             */
            if ([conn altCharset] && [msg coding] != DC_8BIT)
            {
                if ([[msg msgdata] convertFrom:(char *)[[conn altCharset] UTF8String] to:SMPP_DEFAULT_CHARSET] != 0)
                {
                    NSString *txt = [NSString stringWithFormat:@"ailed to convert msgdata from charset <%@> to <%s>, will leave as is", [conn altCharset], SMPP_DEFAULT_CHARSET];
                    [logFeed minorError:0 withText:txt];
                }
                [msg setCoding:DC_7BIT];
            }
            else
            { /* assume GSM 03.38 7-bit alphabet */
                [[msg msgdata] convertFromGsmToUTF8];
                [msg setCoding:DC_7BIT];
            }
            break;
            
        case 0x01: /* ASCII or IA5 - not sure if I need to do anything */
            [msg setCoding:DC_7BIT]; break;
            
        case 0x03: /* ISO-8859-1 - I'll convert to unicode */
            if ([[msg msgdata] convertFrom:"ISO-8859-1" to:SMPP_DEFAULT_CHARSET] != 0)
            {
                NSString *txt = [NSString stringWithFormat:@"Failed to convert msgdata from ISO-8859-1 to " SMPP_DEFAULT_CHARSET ", will leave as is"];
                [logFeed minorError:0 withText:txt];
            }
            [msg setCoding:DC_7BIT]; break;
            
        case 0x02: /* 8 bit binary - do nothing */
            
        case 0x04: /* 8 bit binary - do nothing */
            [msg setCoding:DC_8BIT]; break;
            
        case 0x05: /* JIS - what do I do with that ? */
            break;
            
        case 0x06: /* Cyrllic - iso-8859-5, I'll convert to unicode */
            if ([[msg msgdata] convertFrom:"iso-8859-5" to:SMPP_DEFAULT_CHARSET] != 0)
            {
                NSString *txt = [NSString stringWithFormat:@"Failed to convert msgdata from cyrllic to " SMPP_DEFAULT_CHARSET ", will leave as is"];
                [logFeed minorError:0 withText:txt];
            }
            [msg setCoding:DC_7BIT]; break;
            
        case 0x07: /* Hebrew iso-8859-8, I'll convert to unicode */
            if ([[msg msgdata] convertFrom:"iso-8859-8" to:SMPP_DEFAULT_CHARSET] != 0)
            {
                NSString *txt = [NSString stringWithFormat:@"Failed to convert msgdata from hebrew to " SMPP_DEFAULT_CHARSET ", will leave as is"];
                [logFeed minorError:0 withText:txt];
            }
            [msg setCoding:DC_7BIT]; break;
            
        case 0x08: /* unicode UCS-2, yey */
            [msg setCoding:DC_UCS2]; break;
            
            /*
             * don't much care about the others,
             * you implement them if you feel like it
             */
        default:
            /*
             * some of smsc send with dcs from GSM 03.38 , but these are reserved in smpp spec.
             * So we just look decoded values from dcs_to_fields and if none there make our assumptions.
             * if we have an UDH indicator, we assume DC_8BIT.
             */
            if ([msg coding] == DC_UNDEF && [pdu esm_class] & SMPP_PDU_ESM_CLASS_SUBMIT_UDH_INDICATOR)
                [msg setCoding:DC_8BIT];
            else if ([msg coding] == DC_7BIT || [msg coding] == DC_UNDEF)
            { /* assume GSM 7Bit , reencode */
                [msg setCoding:DC_7BIT];
                [[msg msgdata] convertFromGsmToUTF8];
            }
    }
    
    [msg setPid:[pdu protocol_id]];
    
    /* set priority flag */
    [msg setPriority:[pdu priority_flag]];
    
    if (![msg meta_data])
        [msg setMeta_data:[NSString string]];
    
    [[msg meta_data] setMetaDataValuesIn:[pdu tlv] fromGroup:"smpp" replaceExisting:YES];
    
    return msg;
    
error:
    return nil;
}

- (long) smppStatusToSmscconnFailureReason:(long)status
{
    switch (status)
    {
        case ESME_RMSGQFUL:
        case ESME_RTHROTTLED:
        case ESME_RX_T_APPN:
        case ESME_RSYSERR:
            return SMSCCONN_FAILED_TEMPORARILY;
            break;
            
        default:
            return SMSCCONN_FAILED_REJECTED;
    }
}

- (SmppPdu *)msgToPDU:(Msg *)msg
{
    SmppPdu *pdu;
    int validity;
    
    pdu = [[[SmppPdu alloc] initWithType:SMPP_PDU_SUBMIT_SM] autorelease];
    
    [pdu setSource_addr:[msg sender]];
    [pdu setDestination_addr:[msg receiver]];
    
    /* Set the service type of the outgoing message. We'll use the config
     * directive as default and 'binfo' as specific parameter. */
    if ([[msg binfo] length] > 0)
        [pdu setService_type:[msg binfo]];
    else
        [pdu setService_type:[self service_type]];
    
    /* Check for manual override of source ton and npi values */
    if ([self source_addr_ton] > -1 && [self source_addr_npi] > -1)
    {
        [pdu setSource_addr_ton:[self source_addr_ton]];
        [pdu setSource_addr_npi:[self source_addr_npi]];
        NSString *text = [NSString stringWithFormat:@"SMPP[%@]: Manually forced source addr ton = %d, source add npi = %d", [conn cid], [self source_addr_ton], [self source_addr_npi]];
        [logFeed debug:0 withText:text];
    }
    else
    {
        /* setup default values */
        [pdu setSource_addr_ton:GSM_ADDR_TON_NATIONAL]; /* national */
        [pdu setSource_addr_npi:NPI_ISDN_E164]; /* ISDN number plan */
    }
}
    
@end

@implementation TestSMPPClient

@synthesize service_type;
@synthesize source_addr_ton;
@synthesize source_addr_npi;



@end
