//
//  SmscRouterError.m
//  ulibsmpp
//
//  Created by Andreas Fink on 06/05/15.
//  Copyright (c) 2015 Andreas Fink. All rights reserved.
//

#import "SmscRouterError.h"

@implementation SmscRouterError

-(int)errorTypes
{
    return errorTypes;
}

- (SmscRouterError *)init
{
    self = [super init];
    if(self)
    {
        errorTypes = SmscRouterError_TypeNONE;
    }
    return self;
}


- (SmscRouterError *)initWithGsmErrorCode:(GSMErrorCode)e
{
    return [self initWithGsmErrorCode:e usingOptions:nil];
}

- (SmscRouterError *)initWithGsmErrorCode:(GSMErrorCode)e usingOptions:(NSDictionary *)options
{
    self = [super init];
    if(self)
    {
        [self setGsmErrorCode:e usingOptions:options];
    }
    return self;
}


- (SmscRouterError *)initWithDeliveryReportErrorCode:(DeliveryReportErrorCode)e
{
    return [self initWithDeliveryReportErrorCode:e usingOptions:nil];
}

- (SmscRouterError *)initWithDeliveryReportErrorCode:(DeliveryReportErrorCode)e
                                        usingOptions:(NSDictionary *)options
{
    self = [super init];
    if(self)
    {
        [self setDeliveryReportErrorCode:e usingOptions:options];
    }
    return self;
   
}

- (SmscRouterError *)initWithSmppErrorCode:(SmppErrorCode)e
{
    return [self initWithSmppErrorCode:e usingOptions:nil];
}

- (SmscRouterError *)initWithSmppErrorCode:(SmppErrorCode)e
                              usingOptions:(NSDictionary *)options
{
    self = [super init];
    if(self)
    {
        [self setSmppErrorCode:e usingOptions:options];
    }
    return self;
}

- (SmscRouterError *)initWithInternalErrorCode:(SmscRouterInternalError)e
{
    return [self initWithInternalErrorCode:e usingOptions:nil];
}

- (SmscRouterError *)initWithInternalErrorCode:(SmscRouterInternalError)e
                                  usingOptions:(NSDictionary *)options
{
    self = [super init];
    if(self)
    {
        [self setInternalErrorCode:e usingOptions:options];
    }
    return self;
}

/* -------------------------------------------------------- */
- (void)setGsmErrorCode:(GSMErrorCode)e
{
    [self setGsmErrorCode:e usingOptions:nil];
}

- (void)setGsmErrorCode:(GSMErrorCode)e usingOptions:(NSDictionary *)options
{
    gsmErr = e;
    errorTypes = errorTypes | SmscRouterError_TypeGSM;
    [self convertGsmToInternal:options];
}


- (void)setDeliveryReportErrorCode:(DeliveryReportErrorCode)e
{
    [self setDeliveryReportErrorCode:e usingOptions:nil];
}

- (void)setDeliveryReportErrorCode:(DeliveryReportErrorCode)e
                      usingOptions:(NSDictionary *)options
{
    dlrErr = e;
    errorTypes = errorTypes | SmscRouterError_TypeDLR;
    [self convertDlrToInternal:options];

}

- (void)setSmppErrorCode:(SmppErrorCode)e
{
    [self setSmppErrorCode:e usingOptions:nil];
}

- (void)setSmppErrorCode:(SmppErrorCode)e
            usingOptions:(NSDictionary *)options
{
    smppErr = e;
    errorTypes = errorTypes | SmscRouterError_TypeSMPP;
    [self convertSmppToInternal:options];

}


- (void)setInternalErrorCode:(SmscRouterInternalError)e
{
    [self setInternalErrorCode:e usingOptions:nil];
}

- (void)setInternalErrorCode:(SmscRouterInternalError)e usingOptions:(NSDictionary *)options
{
    internalErr = e;
    errorTypes = errorTypes | SmscRouterError_TypeINTERNAL;
}

/*************************************/

-(GSMErrorCode)gsmError
{
    return [self gsmErrorUsingOptions:nil];
}

-(GSMErrorCode)gsmErrorUsingOptions:(NSDictionary *)options
{
    if(errorTypes & SmscRouterError_TypeGSM)
    {
        return gsmErr;
    }
    [self convertInternalToGsm:options];
    return gsmErr;
}


-(DeliveryReportErrorCode)dlrError
{
    return [self dlrErrorUsingOptions:nil];
}

-(DeliveryReportErrorCode)dlrErrorUsingOptions:(NSDictionary *)options
{
    if(errorTypes & SmscRouterError_TypeDLR)
    {
        return dlrErr;
    }
    [self convertInternalToDlr:options];
    return dlrErr;
}

-(SmppErrorCode)smppError
{
    return [self smppErrorUsingOptions:nil];
}

-(SmppErrorCode)smppErrorUsingOptions:(NSDictionary *)options
{
    if(errorTypes & SmscRouterError_TypeSMPP)
    {
        return smppErr;
    }
    [self convertInternalToSmpp:options];
    return smppErr;
}


-(SmscRouterInternalError)internalError
{
    return [self internalErrorUsingOptions:nil];
}

- (SmscRouterInternalError)internalErrorUsingOptions:(NSDictionary *)options
{
    if(errorTypes & SmscRouterError_TypeINTERNAL)
    {
        return internalErr;
    }
    /* we should do some conversion here */
    return SmscRouterError_UNDEFINED;
}


- (NSString *)description
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc]init];
    
    if(errorTypes & SmscRouterError_TypeINTERNAL)
    {
        dict[@"INTERNAL"] = @{  @"err" : @(internalErr), @"text":[self descriptionInternalError] };
    }
    if(errorTypes & SmscRouterError_TypeGSM)
    {
        dict[@"GSM"] = @{@"err" : @(gsmErr), @"text" : [self descriptionGsmError] };
    }
    if(errorTypes & SmscRouterError_TypeSMPP)
    {
        dict[@"SMPP"] = @{@"err" : @(smppErr), @"text" : [self descriptionSmppError] };
    }
    return [dict jsonString];
}

- (NSString *)descriptionSmppError
{
    switch(smppErr)
    {
        case ESME_ROK:
            return @"ROK";
        case ESME_RINVMSGLEN:
            return @"RINVMSGLEN";
        case ESME_RINVCMDLEN:
            return @"RINVCMDLEN";
        case ESME_RINVCMDID:
            return @"RINVCMDID";
        case ESME_RINVBNDSTS:
            return @"RINVBNDSTS";
        case ESME_RALYBND:
            return @"RALYBND";
        case ESME_RINVPRTFLG:
            return @"RINVPRTFLG";
        case ESME_RINVREGDLVFLG:
            return @"RINVREGDLVFLG";
        case ESME_RSYSERR:
            return @"RSYSERR";
        case ESME_RINVSRCADR:
            return @"RINVSRCADR";
        case ESME_RINVDSTADR:
            return @"RINVDSTADR";
        case ESME_RINVMSGID:
            return @"RINVMSGID";
        case ESME_RBINDFAIL:
            return @"RBINDFAIL";
        case ESME_RINVPASWD:
            return @"RINVPASWD";
        case ESME_RINVSYSID:
            return @"RINVSYSID";
        case ESME_RCANCELFAIL:
            return @"RCANCELFAIL";
        case ESME_RREPLACEFAIL:
            return @"RREPLACEFAIL";
        case ESME_RMSGQFUL:
            return @"RMSGQFUL";
        case ESME_RINVSERTYP:
            return @"RINVSERTYP";
        case ESME_RINVNUMDESTS:
            return @"RINVNUMDESTS";
        case ESME_RINVDLNAME:
            return @"RINVDLNAME";
        case ESME_RINVDESTFLAG:
            return @"RINVDESTFLAG";
        case ESME_RINVSUBREP:
            return @"RINVSUBREP";
        case ESME_RINVESMCLASS:
            return @"RINVESMCLASS";
        case ESME_RCNTSUBDL:
            return @"RCNTSUBDL";
        case ESME_RSUBMITFAIL:
            return @"RSUBMITFAIL";
        case ESME_RINVSRCTON:
            return @"RINVSRCTON";
        case ESME_RINVSRCNPI:
            return @"RINVSRCNPI";
        case ESME_RINVDSTTON:
            return @"RINVDSTTON";
        case ESME_RINVDSTNPI:
            return @"RINVDSTNPI";
        case ESME_RINVSYSTYP:
            return @"RINVSYSTYP";
        case ESME_RINVREPFLAG:
            return @"RINVREPFLAG";
        case ESME_RINVNUMMSGS:
            return @"RINVNUMMSGS";
        case ESME_RTHROTTLED:
            return @"RTHROTTLED";
        case ESME_RINVSCHED:
            return @"RINVSCHED";
        case ESME_RINVEXPIRY:
            return @"RINVEXPIRY";
        case ESME_RINVDFTMSGID:
            return @"RINVDFTMSGID";
        case ESME_RX_T_APPN:
            return @"RX_T_APPN";
        case ESME_RX_P_APPN:
            return @"RX_P_APPN";
        case ESME_RX_R_APPN:
            return @"RX_R_APPN";
        case ESME_RQUERYFAIL:
            return @"RQUERYFAIL";
        case ESME_RINVOPTPARSTREAM:
            return @"RINVOPTPARSTREAM";
        case ESME_ROPTPARNOTALLWD:
            return @"ROPTPARNOTALLWD";
        case ESME_RINVPARLEN:
            return @"RINVPARLEN";
        case ESME_RMISSINGOPTPARAM:
            return @"RMISSINGOPTPARAM";
        case ESME_RINVOPTPARAMVAL:
            return @"RINVOPTPARAMVAL";
        case ESME_RDELIVERYFAILURE:
            return @"RDELIVERYFAILURE";
        case ESME_RUNKNOWNERR:
            return @"RUNKNOWNERR";
        case ESME_VENDOR_SPECIFIC_INVALID_INTERNAL_CONFIG:
            return @"INVALID_INTERNAL_CONFIG";
        case ESME_VENDOR_SPECIFIC_NO_PROVIDER_FOUND:
            return @"NO_PROVIDER_FOUND";
        case ESME_VENDOR_SPECIFIC_NO_PROFITABLE_ROUTE_FOUND:
            return @"NO_PROFITABLE_ROUTE_FOUND";
        case ESME_VENDOR_SPECIFIC_NO_PRICING_TABLE_FOUND:
            return @"NO_PRICING_TABLE_FOUND";
        case ESME_VENDOR_SPECIFIC_NO_DELIVERER:
            return @"NO_DELIVERER";
        case ESME_VENDOR_SPECIFIC_NO_SUCH_COUNTRY:
            return @"NO_SUCH_COUNTRY";
        case ESME_VENDOR_SPECIFIC_NO_SUCH_USER:
            return @"NO_SUCH_USER";
        case ESME_VENDOR_SPECIFIC_USER_OUT_OF_CREDIT:
            return @"USER_OUT_OF_CREDIT";
        case ESME_VENDOR_SPECIFIC_NO_PROVIDER:
            return @"NO_PROVIDER";
        case ESME_VENDOR_SPECIFIC_NO_USER:
            return @"NO_USER";
        case ESME_VENDOR_SPECIFIC_NUMBER_PREFIX_NOT_FOUND:
            return @"NUMBER_PREFIX_NOT_FOUND";
        case ESME_VENDOR_SPECIFIC_HLR_ROUTING_TABLE_NOT_FOUND:
            return @"HLR_ROUTING_TABLE_NOT_FOUND";
        case ESME_VENDOR_SPECIFIC_NUMBER_PREFIX_TABLE_NOT_FOUND:
            return @"NUMBER_PREFIX_TABLE_NOT_FOUND";
        case ESME_VENDOR_SPECIFIC_COUNTRY_NOT_FOUND:
            return @"COUNTRY_NOT_FOUND";
        case ESME_VENDOR_SPECIFIC_NO_PRICE_FOUND:
            return @"NO_PRICE_FOUND";
        case ESME_VENDOR_SPECIFIC_OFFLINE:
            return @"OFFLINE";
        case ESME_VENDOR_SPECIFIC_NO_ROUTING_TABLE:
            return @"NO_ROUTING_TABLE";
        case ESME_VENDOR_SPECIFIC_NO_ROUTING_TABLE_ENTRY:
            return @"NO_ROUTING_TABLE_ENTRY";
        case ESME_VENDOR_SPECIFIC_NO_ROUTE:
            return @"NO_ROUTE";
        case ESME_VENDOR_SPECIFIC_NO_PROVIDER_NAME:
            return @"NO_PROVIDER_NAME";
        case ESME_VENDOR_SPECIFIC_UNKNOWN_SUB:
            return @"UNKNOWN_SUB";
        case ESME_VENDOR_SPECIFIC_UNKNOWN_MSC:
            return @"UNKNOWN_MSC";
        case ESME_VENDOR_SPECIFIC_UNIDENTIFIED_SUB:
            return @"UNIDENTIFIED_SUB";
        case ESME_VENDOR_SPECIFIC_ABSENT_SUB_SM:
            return @"ABSENT_SUB_SM";
        case ESME_VENDOR_SPECIFIC_UNKNOWN_EQUIPMENT:
            return @"UNKNOWN_EQUIPMENT";
        case ESME_VENDOR_SPECIFIC_NOROAM:
            return @"NOROAM";
        case ESME_VENDOR_SPECIFIC_ILLEGAL_SUB:
            return @"ILLEGAL_SUB";
        case ESME_VENDOR_SPECIFIC_BEARER_SERVICE_NOT_PROVISIONED:
            return @"BEARER_SERVICE_NOT_PROVISIONED";
        case ESME_VENDOR_SPECIFIC_NOT_PROV:
            return @"NOT_PROV";
        case ESME_VENDOR_SPECIFIC_ILLEGAL_EQUIPMENT:
            return @"ILLEGAL_EQUIPMENT";
        case ESME_VENDOR_SPECIFIC_BARRED:
            return @"BARRED";
        case ESME_VENDOR_SPECIFIC_FORWARDING_VIOLATION:
            return @"FORWARDING_VIOLATION";
        case ESME_VENDOR_SPECIFIC_CUG_REJECT:
            return @"CUG_REJECT";
        case ESME_VENDOR_SPECIFIC_ILLEGAL_SS:
            return @"ILLEGAL_SS";
        case ESME_VENDOR_SPECIFIC_SS_ERR_STATUS:
            return @"SS_ERR_STATUS";
        case ESME_VENDOR_SPECIFIC_SS_NOTAVAIL:
            return @"SS_NOTAVAIL";
        case ESME_VENDOR_SPECIFIC_SS_SUBVIOL:
            return @"SS_SUBVIOL";
        case ESME_VENDOR_SPECIFIC_SS_INCOMPAT:
            return @"SS_INCOMPAT";
        case ESME_VENDOR_SPECIFIC_NOT_SUPPORTED:
            return @"NOT_SUPPORTED";
        case ESME_VENDOR_SPECIFIC_MEMORY_CAP_EXCEED:
            return @"MEMORY_CAP_EXCEED";
        case ESME_VENDOR_SPECIFIC_NO_HANDOVER_NUMBER_AVAILABLE:
            return @"NO_HANDOVER_NUMBER_AVAILABLE";
        case ESME_VENDOR_SPECIFIC_SUBSEQUENT_HANDOVER_FAILURE:
            return @"SUBSEQUENT_HANDOVER_FAILURE";
        case ESME_VENDOR_SPECIFIC_ABSENT_SUB:
            return @"ABSENT_SUB";
        case ESME_VENDOR_SPECIFIC_INCOMPATIBLE_TERMINAL:
            return @"INCOMPATIBLE_TERMINAL";
        case ESME_VENDOR_SPECIFIC_SHORT_TERM_DENIAL:
            return @"SHORT_TERM_DENIAL";
        case ESME_VENDOR_SPECIFIC_LONG_TERM_DENIAL:
            return @"LONG_TERM_DENIAL";
        case ESME_VENDOR_SPECIFIC_SM_SUBSCRIBER_BUSY:
            return @"SM_SUBSCRIBER_BUSY";
        case ESME_VENDOR_SPECIFIC_SM_DELIVERY_FAILURE:
            return @"SM_DELIVERY_FAILURE";
        case ESME_VENDOR_SPECIFIC_MESSAGE_WAITING_LIST_FULL:
            return @"MESSAGE_WAITING_LIST_FULL";
        case ESME_VENDOR_SPECIFIC_SYSTEM_FAILURE:
            return @"SYSTEM_FAILURE";
        case ESME_VENDOR_SPECIFIC_DATA_MISSING:
            return @"DATA_MISSING";
        case ESME_VENDOR_SPECIFIC_UNEXP_VAL:
            return @"UNEXP_VAL";
        case ESME_VENDOR_SPECIFIC_PW_REGISTRATION_FAILURE:
            return @"PW_REGISTRATION_FAILURE";
        case ESME_VENDOR_SPECIFIC_NEGATIVE_PW_CHECK:
            return @"NEGATIVE_PW_CHECK";
        case ESME_VENDOR_SPECIFIC_NO_ROAMING_NUMBER_AVAILABLE:
            return @"NO_ROAMING_NUMBER_AVAILABLE";
        case ESME_VENDOR_SPECIFIC_TRACING_BUFFER_FULL:
            return @"TRACING_BUFFER_FULL";
        case ESME_VENDOR_SPECIFIC_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA:
            return @"TARGET_CELL_OUTSIDE_GROUP_CALL_AREA";
        case ESME_VENDOR_SPECIFIC_NUMBER_OF_PW_ATTEMPS_VIOLATION:
            return @"NUMBER_OF_PW_ATTEMPS_VIOLATION";
        case ESME_VENDOR_SPECIFIC_NUMBER_CHANGED:
            return @"NUMBER_CHANGED";
        case ESME_VENDOR_SPECIFIC_BUSY_SUBSCRIBER:
            return @"BUSY_SUBSCRIBER";
        case ESME_VENDOR_SPECIFIC_NO_SUBSCRIBER_REPLY:
            return @"NO_SUBSCRIBER_REPLY";
        case ESME_VENDOR_SPECIFIC_FORWARDING_FAILED:
            return @"FORWARDING_FAILED";
        case ESME_VENDOR_SPECIFIC_OR_NOT_ALLOWED:
            return @"OR_NOT_ALLOWED";
        case ESME_VENDOR_SPECIFIC_ATI_NOT_ALLOWED:
            return @"ATI_NOT_ALLOWED";
        case ESME_VENDOR_SPECIFIC_NO_ERROR_CODE_PROVIDED:
            return @"NO_ERROR_CODE_PROVIDED";
        case ESME_VENDOR_SPECIFIC_NO_ROUTE_TO_DESTINATION:
            return @"NO_ROUTE_TO_DESTINATION";
        case ESME_VENDOR_SPECIFIC_UNKNOWN_ALPHABETH:
            return @"UNKNOWN_ALPHABETH";
        case ESME_VENDOR_SPECIFIC_USSD_BUSY:
            return @"USSD_BUSY";
        case ESME_VENDOR_SPECIFIC_SCCP_NO_TRANSLATION_FOR_AN_ADDRESS_OF_SUCH_NATURE:
            return @"SCCP_NO_TRANSLATION_FOR_AN_ADDRESS_OF_SUCH_NATURE";
        case ESME_VENDOR_SPECIFIC_SCCP_NO_TRANSLATION_FOR_THIS_SPECIFIC_ADDRESS:
            return @"SCCP_NO_TRANSLATION_FOR_THIS_SPECIFIC_ADDRESS";
        case ESME_VENDOR_SPECIFIC_SCCP_SUBSYSTEM_CONGESTION:
            return @"SCCP_SUBSYSTEM_CONGESTION";
        case ESME_VENDOR_SPECIFIC_SCCP_SUBSYSTEM_FAILURE:
            return @"SCCP_SUBSYSTEM_FAILURE";
        case ESME_VENDOR_SPECIFIC_SCCP_UNEQUIPPED_FAILURE:
            return @"SCCP_UNEQUIPPED_FAILURE";
        case ESME_VENDOR_SPECIFIC_SCCP_MTP_FAILURE:
            return @"SCCP_MTP_FAILURE";
        case ESME_VENDOR_SPECIFIC_SCCP_NETWORK_CONGESTION:
            return @"SCCP_NETWORK_CONGESTION";
        case ESME_VENDOR_SPECIFIC_SCCP_UNQUALIFIED:
            return @"SCCP_UNQUALIFIED";
        case ESME_VENDOR_SPECIFIC_SCCP_ERROR_IN_MESSAGE_TRANSPORT:
            return @"SCCP_ERROR_IN_MESSAGE_TRANSPORT";
        case ESME_VENDOR_SPECIFIC_SCCP_ERROR_IN_LOCAL_PROCESSING:
            return @"SCCP_ERROR_IN_LOCAL_PROCESSING";
        case ESME_VENDOR_SPECIFIC_SCCP_DESTINATION_CANNOT_PERFORM_REASSEMBLY:
            return @"SCCP_DESTINATION_CANNOT_PERFORM_REASSEMBLY";
        case ESME_VENDOR_SPECIFIC_SCCP_FAILURE:
            return @"SCCP_FAILURE";
        case ESME_VENDOR_SPECIFIC_SCCP_HOP_COUNTER_VIOLATION:
            return @"SCCP_HOP_COUNTER_VIOLATION";
        case ESME_VENDOR_SPECIFIC_SCCP_SEGMENTATION_NOT_SUPPORTED:
            return @"SCCP_SEGMENTATION_NOT_SUPPORTED";
        case ESME_VENDOR_SPECIFIC_SCCP_SEGMENTATION_FAILURE:
            return @"SCCP_SEGMENTATION_FAILURE";
        case ESME_VENDOR_SPECIFIC_FAILED_TO_DELIVER:
            return @"FAILED_TO_DELIVER";
        case ESME_VENDOR_SPECIFIC_UNEXP_TCAP_MSG:
            return @"UNEXP_TCAP_MSG";
        case ESME_VENDOR_SPECIFIC_FAILED_TO_REQ_ROUTING_INFO:
            return @"FAILED_TO_REQ_ROUTING_INFO";
        case ESME_VENDOR_SPECIFIC_TIMER_EXP:
            return @"TIMER_EXP";
        case ESME_VENDOR_SPECIFIC_TCAP_ABORT1:
            return @"TCAP_ABORT1";
        case ESME_VENDOR_SPECIFIC_TCAP_ABORT2:
            return @"TCAP_ABORT2";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_SMSC:
            return @"BLACKLISTED_SMSC";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_DPC:
            return @"BLACKLISTED_DPC";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_OPC:
            return @"BLACKLISTED_OPC";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_DESTINATION:
            return @"BLACKLISTED_DESTINATION";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_PREFIX:
            return @"BLACKLISTED_PREFIX";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_TEXT:
            return @"BLACKLISTED_TEXT";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_IMSI_PREFIX:
            return @"BLACKLISTED_IMSI_PREFIX";
        case ESME_VENDOR_SPECIFIC_CHARGING_NOT_DEFINED:
            return @"CHARGING_NOT_DEFINED";
        case ESME_VENDOR_SPECIFIC_QUOTA_REACHED:
            return @"QUOTA_REACHED";
        case ESME_VENDOR_SPECIFIC_CHARGING_BLOCKED:
            return @"CHARGING_BLOCKED";
        case ESME_VENDOR_SPECIFIC_BLACKLISTED_MSC:
            return @"BLACKLISTED_MSC";
        case ESME_VENDOR_SPECIFIC_UNKNOWN_USER:
            return @"UNKNOWN_USER";
        case ESME_VENDOR_SPECIFIC_UNKNOWN_METHOD:
            return @"UNKNOWN_METHOD";
        case ESME_VENDOR_SPECIFIC_NOT_IMPLEMENTED:
            return @"NOT_IMPLEMENTED";
        case ESME_VENDOR_SPECIFIC_PDU_CAN_NOT_BE_ENCODED:
            return @"PDU_CAN_NOT_BE_ENCODED";
        case ESME_VENDOR_SPECIFIC_TCAP_USER_ABORT:
            return @"TCAP_USER_ABORT";
        case ESME_VENDOR_SPECIFIC_ABORT_BY_SCRIPT:
            return @"ABORT_BY_SCRIPT";
        case ESME_VENDOR_SPECIFIC_MAX_ATTEMPTS_REACHED:
            return @"MAX_ATTEMPTS_REACHED";
        case ESME_VENDOR_SPECIFIC_ALL_OUTGOING_CONNECTION_UNAVAILABLE:
            return @"ALL_OUTGOING_CONNECTION_UNAVAILABLE";
        case ESME_VENDOR_SPECIFIC_THIS_OUTGOING_CONNECTION_UNAVAILABLE:
            return @"THIS_OUTGOING_CONNECTION_UNAVAILABLE";
        default:
            return [NSString stringWithFormat:@"ESME_UNKNOWN_0x%lux",(unsigned long)smppErr];
    }
}

- (NSString *)descriptionGsmError
{
    switch(gsmErr)
    {
            
        case GSM_ERROR_NONE:
            return @"NONE";
        case GSM_ERROR_UNKNOWN_SUB:
            return @"UNKNOWN_SUB";
        case GSM_ERROR_UNKNOWN_MSC:
            return @"UNKNOWN_MSC";
        case GSM_ERROR_UNIDENTIFIED_SUB:
            return @"UNIDENTIFIED_SUB";
        case GSM_ERROR_ABSENT_SUB_SM:
            return @"ABSENT_SUB_SM";
        case GSM_ERROR_UNKNOWN_EQUIPMENT:
            return @"UNKNOWN_EQUIPMENT";
        case GSM_ERROR_NOROAM:
            return @"NOROAM";
        case GSM_ERROR_ILLEGAL_SUB:
            return @"ILLEGAL_SUB";
        case GSM_ERROR_BEARER_SERVICE_NOT_PROVISIONED:
            return @"BEARER_SERVICE_NOT_PROVISIONED";
        case GSM_ERROR_NOT_PROV:
            return @"NOT_PROV";
        case GSM_ERROR_ILLEGAL_EQUIPMENT:
            return @"ILLEGAL_EQUIPMENT";
        case GSM_ERROR_BARRED:
            return @"BARRED";
        case GSM_ERROR_FORWARDING_VIOLATION:
            return @"FORWARDING_VIOLATION";
        case GSM_ERROR_CUG_REJECT:
            return @"CUG_REJECT";
        case GSM_ERROR_ILLEGAL_SS:
            return @"ILLEGAL_SS";
        case GSM_ERROR_SS_ERR_STATUS:
            return @"SS_ERR_STATUS";
        case GSM_ERROR_SS_NOTAVAIL:
            return @"SS_NOTAVAIL";
        case GSM_ERROR_SS_SUBVIOL:
            return @"SS_SUBVIOL";
        case GSM_ERROR_SS_INCOMPAT:
            return @"SS_INCOMPAT";
        case GSM_ERROR_NOT_SUPPORTED:
            return @"NOT_SUPPORTED";
        case GSM_ERROR_MEMORY_CAP_EXCEED:
            return @"MEMORY_CAP_EXCEED";
        case GSM_ERROR_NO_HANDOVER_NUMBER_AVAILABLE:
            return @"NO_HANDOVER_NUMBER_AVAILABLE";
        case GSM_ERROR_SUBSEQUENT_HANDOVER_FAILURE:
            return @"SUBSEQUENT_HANDOVER_FAILURE";
        case GSM_ERROR_ABSENT_SUB:
            return @"ABSENT_SUB";
        case GSM_ERROR_INCOMPATIBLE_TERMINAL:
            return @"INCOMPATIBLE_TERMINAL";
        case GSM_ERROR_SHORT_TERM_DENIAL:
            return @"SHORT_TERM_DENIAL";
        case GSM_ERROR_LONG_TERM_DENIAL:
            return @"LONG_TERM_DENIAL";
        case GSM_ERROR_SM_SUBSCRIBER_BUSY:
            return @"SM_SUBSCRIBER_BUSY";
        case GSM_ERROR_SM_DELIVERY_FAILURE:
            return @"SM_DELIVERY_FAILURE";
        case GSM_ERROR_MESSAGE_WAITING_LIST_FULL:
            return @"MESSAGE_WAITING_LIST_FULL";
        case GSM_ERROR_SYSTEM_FAILURE:
            return @"SYSTEM_FAILURE";
        case GSM_ERROR_DATA_MISSING:
            return @"DATA_MISSING";
        case GSM_ERROR_UNEXP_VAL:
            return @"UNEXP_VAL";
        case GSM_ERROR_PW_REGISTRATION_FAILURE:
            return @"PW_REGISTRATION_FAILURE";
        case GSM_ERROR_NEGATIVE_PW_CHECK:
            return @"NEGATIVE_PW_CHECK";
        case GSM_ERROR_NO_ROAMING_NUMBER_AVAILABLE:
            return @"NO_ROAMING_NUMBER_AVAILABLE";
        case GSM_ERROR_TRACING_BUFFER_FULL:
            return @"TRACING_BUFFER_FULL";
        case GSM_ERROR_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA:
            return @"TARGET_CELL_OUTSIDE_GROUP_CALL_AREA";
        case GSM_ERROR_NUMBER_OF_PW_ATTEMPS_VIOLATION:
            return @"NUMBER_OF_PW_ATTEMPS_VIOLATION";
        case GSM_ERROR_NUMBER_CHANGED:
            return @"NUMBER_CHANGED";
        case GSM_ERROR_BUSY_SUBSCRIBER:
            return @"BUSY_SUBSCRIBER";
        case GSM_ERROR_NO_SUBSCRIBER_REPLY:
            return @"NO_SUBSCRIBER_REPLY";
        case GSM_ERROR_FORWARDING_FAILED:
            return @"FORWARDING_FAILED";
        case GSM_ERROR_OR_NOT_ALLOWED:
            return @"OR_NOT_ALLOWED";
        case GSM_ERROR_ATI_NOT_ALLOWED:
            return @"ATI_NOT_ALLOWED";
        case GSM_ERROR_NO_ERROR_CODE_PROVIDED:
            return @"NO_ERROR_CODE_PROVIDED";
        case GSM_ERROR_NO_ROUTE_TO_DESTINATION:
            return @"NO_ROUTE_TO_DESTINATION";
        case GSM_ERROR_UNKNOWN_ALPHABETH:
            return @"UNKNOWN_ALPHABETH";
        case GSM_ERROR_USSD_BUSY:
            return @"USSD_BUSY";
        default:
            return [NSString stringWithFormat:@"GSM_ERR_%d",gsmErr];
    }
}

- (NSString *)descriptionInternalError
{
    return @"unknown";
}

- (id)copyWithZone:(NSZone *)zone
{
    SmscRouterError *n  = [[SmscRouterError alloc]init];
    n->errorTypes    = errorTypes;
    n->dlrErr        = dlrErr;
    n->smppErr       = smppErr;
    n->gsmErr        = gsmErr;
    n->internalErr   = internalErr;
    return n;
}


-(void)convertGsmToInternal:(NSDictionary *)options
{
    
}

-(void)convertDlrToInternal:(NSDictionary *)options
{
    
}

-(void)convertSmppToInternal:(NSDictionary *)options
{
    
}

-(void)convertInternalToGsm:(NSDictionary *)options
{
    
}
-(void)convertInternalToDlr:(NSDictionary *)options
{
    
}
-(void)convertInternalToSmpp:(NSDictionary *)options
{
    
}

- (BOOL)allowsRerouting
{
     return YES;
}

- (BOOL)allowUpdatingStats
{
    return YES;
}

@end
