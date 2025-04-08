//
//  DeliveryReportErrorCode.h
//  ulibsmpp
//
//  Created by Andreas Fink on 06/05/15.
//
//

#import <ulib/ulib.h>

/* DLR Error codes. Mostly same ones as GSM Map error codes */

typedef enum DeliveryReportErrorCode
{
    DLR_ERROR_NONE                                  = 0,
    DLR_ERROR_UNKNOWN_SUB                           = 1,
    DLR_ERROR_UNKNOWN_MSC                           = 3,
    DLR_ERROR_UNIDENTIFIED_SUB                      = 5,
    DLR_ERROR_ABSENT_SUB_SM                         = 6,
    DLR_ERROR_UNKNOWN_EQUIPMENT                     = 7,
    DLR_ERROR_NOROAM                                = 8,
    DLR_ERROR_ILLEGAL_SUB                           = 9,
    DLR_ERROR_BEARER_SERVICE_NOT_PROVISIONED        = 10,
    DLR_ERROR_NOT_PROV                              = 11,
    DLR_ERROR_ILLEGAL_EQUIPMENT                     = 12,
    DLR_ERROR_BARRED                                = 13,
    DLR_ERROR_FORWARDING_VIOLATION                  = 14,
    DLR_ERROR_CUG_REJECT                            = 15,
    DLR_ERROR_ILLEGAL_SS                            = 16,
    DLR_ERROR_SS_ERR_STATUS                         = 17,
    DLR_ERROR_SS_NOTAVAIL                           = 18,
    DLR_ERROR_SS_SUBVIOL                            = 19,
    DLR_ERROR_SS_INCOMPAT                           = 20,
    DLR_ERROR_NOT_SUPPORTED                         = 21,
    DLR_ERROR_MEMORY_CAP_EXCEED                     = 22,
    DLR_ERROR_NO_HANDOVER_NUMBER_AVAILABLE          = 25,
    DLR_ERROR_SUBSEQUENT_HANDOVER_FAILURE           = 26,
    DLR_ERROR_ABSENT_SUB                            = 27,
    DLR_ERROR_INCOMPATIBLE_TERMINAL                 = 28,
    DLR_ERROR_SHORT_TERM_DENIAL                     = 29,
    DLR_ERROR_LONG_TERM_DENIAL                      = 30,
    DLR_ERROR_SM_SUBSCRIBER_BUSY                    = 31,
    DLR_ERROR_SM_DELIVERY_FAILURE                   = 32,
    DLR_ERROR_MESSAGE_WAITING_LIST_FULL             = 33,
    DLR_ERROR_SYSTEM_FAILURE                        = 34,
    DLR_ERROR_DATA_MISSING                          = 35,
    DLR_ERROR_UNEXP_VAL                             = 36,
    DLR_ERROR_PW_REGISTRATION_FAILURE               = 37,
    DLR_ERROR_NEGATIVE_PW_CHECK                     = 38,
    DLR_ERROR_NO_ROAMING_NUMBER_AVAILABLE           = 39,
    DLR_ERROR_TRACING_BUFFER_FULL                   = 40,
    DLR_ERROR_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA   = 42,
    DLR_ERROR_NUMBER_OF_PW_ATTEMPS_VIOLATION        = 43,
    DLR_ERROR_NUMBER_CHANGED                        = 44,
    DLR_ERROR_BUSY_SUBSCRIBER                       = 45,
    DLR_ERROR_NO_SUBSCRIBER_REPLY                   = 46,
    DLR_ERROR_FORWARDING_FAILED                     = 47,
    DLR_ERROR_OR_NOT_ALLOWED                        = 48,
    DLR_ERROR_ATI_NOT_ALLOWED                       = 49,
    DLR_ERROR_NO_ERROR_CODE_PROVIDED                = 62,
    DLR_ERROR_NO_ROUTE_TO_DESTINATION               = 63,
    DLR_ERROR_UNKNOWN_ALPHABETH                     = 71,
    DLR_ERROR_USSD_BUSY                             = 72,
} DeliveryReportErrorCode;
