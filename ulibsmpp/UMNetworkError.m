//
//  UMNetworkError.m
//  ulibsmpp
//
//  Created by Andreas Fink on 27.03.2025.
//

#import "UMNetworkError.h"



NSString *UMNetworkErrorAsString(UMNetworkError e)
{
    switch(e)
    {
        case UM_GSM_ERROR_NONE:
            return @"GSM_ERROR_NONE";
        case UM_GSM_ERROR_UNKNOWN_SUB:
            return @"GSM_ERROR_UNKNOWN_SUB";
        case UM_GSM_ERROR_UNKNOWN_MSC:
            return @"GSM_ERROR_UNKNOWN_MSC";
        case UM_GSM_ERROR_UNIDENTIFIED_SUB:
            return @"GSM_ERROR_UNIDENTIFIED_SUB";
        case UM_GSM_ERROR_ABSENT_SUB_SM:
            return @"GSM_ERROR_ABSENT_SUB_SM";
        case UM_GSM_ERROR_UNKNOWN_EQUIPMENT:
            return @"GSM_ERROR_UNKNOWN_EQUIPMENT";
        case UM_GSM_ERROR_NOROAM:
            return @"GSM_ERROR_NOROAM";
        case UM_GSM_ERROR_ILLEGAL_SUB:
            return @"GSM_ERROR_ILLEGAL_SUB";
        case UM_GSM_ERROR_BEARER_SERVICE_NOT_PROVISIONED:
            return @"GSM_ERROR_BEARER_SERVICE_NOT_PROVISIONED";
        case UM_GSM_ERROR_NOT_PROV:
            return @"GSM_ERROR_NOT_PROV";
        case UM_GSM_ERROR_ILLEGAL_EQUIPMENT:
            return @"GSM_ERROR_ILLEGAL_EQUIPMENT";
        case UM_GSM_ERROR_BARRED:
            return @"GSM_ERROR_BARRED";
        case UM_GSM_ERROR_FORWARDING_VIOLATION:
            return @"GSM_ERROR_FORWARDING_VIOLATION";
        case UM_GSM_ERROR_CUG_REJECT:
            return @"GSM_ERROR_CUG_REJECT";
        case UM_GSM_ERROR_ILLEGAL_SS:
            return @"GSM_ERROR_ILLEGAL_SS";
        case UM_GSM_ERROR_SS_ERR_STATUS:
            return @"GSM_ERROR_SS_ERR_STATUS";
        case UM_GSM_ERROR_SS_NOTAVAIL:
            return @"GSM_ERROR_SS_NOTAVAIL";
        case UM_GSM_ERROR_SS_SUBVIOL:
            return @"GSM_ERROR_SS_SUBVIOL";
        case UM_GSM_ERROR_SS_INCOMPAT:
            return @"GSM_ERROR_SS_INCOMPAT";
        case UM_GSM_ERROR_NOT_SUPPORTED:
            return @"GSM_ERROR_NOT_SUPPORTED";
        case UM_GSM_ERROR_MEMORY_CAP_EXCEED:
            return @"GSM_ERROR_MEMORY_CAP_EXCEED";
        case UM_GSM_ERROR_NO_HANDOVER_NUMBER_AVAILABLE:
            return @"GSM_ERROR_NO_HANDOVER_NUMBER_AVAILABLE";
        case UM_GSM_ERROR_SUBSEQUENT_HANDOVER_FAILURE:
            return @"GSM_ERROR_SUBSEQUENT_HANDOVER_FAILURE";
        case UM_GSM_ERROR_ABSENT_SUB:
            return @"GSM_ERROR_ABSENT_SUB";
        case UM_GSM_ERROR_INCOMPATIBLE_TERMINAL:
            return @"GSM_ERROR_INCOMPATIBLE_TERMINAL";
        case UM_GSM_ERROR_SHORT_TERM_DENIAL:
            return @"GSM_ERROR_SHORT_TERM_DENIAL";
        case UM_GSM_ERROR_LONG_TERM_DENIAL:
            return @"GSM_ERROR_LONG_TERM_DENIAL";
        case UM_GSM_ERROR_SM_SUBSCRIBER_BUSY:
            return @"GSM_ERROR_SM_SUBSCRIBER_BUSY";
        case UM_GSM_ERROR_SM_DELIVERY_FAILURE:
            return @"GSM_ERROR_SM_DELIVERY_FAILURE";
        case UM_GSM_ERROR_MESSAGE_WAITING_LIST_FULL:
            return @"GSM_ERROR_MESSAGE_WAITING_LIST_FULL";
        case UM_GSM_ERROR_SYSTEM_FAILURE:
            return @"GSM_ERROR_SYSTEM_FAILURE";
        case UM_GSM_ERROR_DATA_MISSING:
            return @"GSM_ERROR_DATA_MISSING";
        case UM_GSM_ERROR_UNEXP_VAL:
            return @"GSM_ERROR_UNEXP_VAL";
        case UM_GSM_ERROR_PW_REGISTRATION_FAILURE:
            return @"GSM_ERROR_PW_REGISTRATION_FAILURE";
        case UM_GSM_ERROR_NEGATIVE_PW_CHECK:
            return @"GSM_ERROR_NEGATIVE_PW_CHECK";
        case UM_GSM_ERROR_NO_ROAMING_NUMBER_AVAILABLE:
            return @"GSM_ERROR_NO_ROAMING_NUMBER_AVAILABLE";
        case UM_GSM_ERROR_TRACING_BUFFER_FULL:
            return @"GSM_ERROR_TRACING_BUFFER_FULL";
        case UM_GSM_ERROR_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA:
            return @"GSM_ERROR_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA";
        case UM_GSM_ERROR_NUMBER_OF_PW_ATTEMPS_VIOLATION:
            return @"GSM_ERROR_NUMBER_OF_PW_ATTEMPS_VIOLATION";
        case UM_GSM_ERROR_NUMBER_CHANGED:
            return @"GSM_ERROR_NUMBER_CHANGED";
        case UM_GSM_ERROR_BUSY_SUBSCRIBER:
            return @"GSM_ERROR_BUSY_SUBSCRIBER";
        case UM_GSM_ERROR_NO_SUBSCRIBER_REPLY:
            return @"GSM_ERROR_NO_SUBSCRIBER_REPLY";
        case UM_GSM_ERROR_FORWARDING_FAILED:
            return @"GSM_ERROR_FORWARDING_FAILED";
        case UM_GSM_ERROR_OR_NOT_ALLOWED:
            return @"GSM_ERROR_OR_NOT_ALLOWED";
        case UM_GSM_ERROR_ATI_NOT_ALLOWED:
            return @"GSM_ERROR_ATI_NOT_ALLOWED";
        case UM_GSM_ERROR_NO_ERROR_CODE_PROVIDED:
            return @"GSM_ERROR_NO_ERROR_CODE_PROVIDED";
        case UM_GSM_ERROR_NO_ROUTE_TO_DESTINATION:
            return @"GSM_ERROR_NO_ROUTE_TO_DESTINATION";
        case UM_GSM_ERROR_UNKNOWN_ALPHABETH:
            return @"GSM_ERROR_UNKNOWN_ALPHABETH";
        case UM_GSM_ERROR_USSD_BUSY:
            return @"GSM_ERROR_USSD_BUSY";
        default:
            [NSString stringWithFormat:@"GSM_ERROR_%ld",(long)e];
    }
}
