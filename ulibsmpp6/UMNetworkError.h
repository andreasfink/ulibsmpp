//
//  UMNetworkError.h
//  ulibsmpp
//
//  Created by Andreas Fink on 27.03.2025.
//

#import <ulib/ulib.h>

typedef enum UMNetworkError
{
    UM_GSM_ERROR_NONE                                  = 0,
    UM_GSM_ERROR_UNKNOWN_SUB                           = 1,
    UM_GSM_ERROR_UNKNOWN_MSC                           = 3,
    UM_GSM_ERROR_UNIDENTIFIED_SUB                      = 5,
    UM_GSM_ERROR_ABSENT_SUB_SM                         = 6,
    UM_GSM_ERROR_UNKNOWN_EQUIPMENT                     = 7,
    UM_GSM_ERROR_NOROAM                                = 8,
    UM_GSM_ERROR_ILLEGAL_SUB                           = 9,
    UM_GSM_ERROR_BEARER_SERVICE_NOT_PROVISIONED        = 10,
    UM_GSM_ERROR_NOT_PROV                              = 11,
    UM_GSM_ERROR_ILLEGAL_EQUIPMENT                     = 12,
    UM_GSM_ERROR_BARRED                                = 13,
    UM_GSM_ERROR_FORWARDING_VIOLATION                  = 14,
    UM_GSM_ERROR_CUG_REJECT                            = 15,
    UM_GSM_ERROR_ILLEGAL_SS                            = 16,
    UM_GSM_ERROR_SS_ERR_STATUS                         = 17,
    UM_GSM_ERROR_SS_NOTAVAIL                           = 18,
    UM_GSM_ERROR_SS_SUBVIOL                            = 19,
    UM_GSM_ERROR_SS_INCOMPAT                           = 20,
    UM_GSM_ERROR_NOT_SUPPORTED                         = 21,
    UM_GSM_ERROR_MEMORY_CAP_EXCEED                     = 22,
    UM_GSM_ERROR_NO_HANDOVER_NUMBER_AVAILABLE          = 25,
    UM_GSM_ERROR_SUBSEQUENT_HANDOVER_FAILURE           = 26,
    UM_GSM_ERROR_ABSENT_SUB                            = 27,
    UM_GSM_ERROR_INCOMPATIBLE_TERMINAL                 = 28,
    UM_GSM_ERROR_SHORT_TERM_DENIAL                     = 29,
    UM_GSM_ERROR_LONG_TERM_DENIAL                      = 30,
    UM_GSM_ERROR_SM_SUBSCRIBER_BUSY                    = 31,
    UM_GSM_ERROR_SM_DELIVERY_FAILURE                   = 32,
    UM_GSM_ERROR_MESSAGE_WAITING_LIST_FULL             = 33,
    UM_GSM_ERROR_SYSTEM_FAILURE                        = 34,
    UM_GSM_ERROR_DATA_MISSING                          = 35,
    UM_GSM_ERROR_UNEXP_VAL                             = 36,
    UM_GSM_ERROR_PW_REGISTRATION_FAILURE               = 37,
    UM_GSM_ERROR_NEGATIVE_PW_CHECK                     = 38,
    UM_GSM_ERROR_NO_ROAMING_NUMBER_AVAILABLE           = 39,
    UM_GSM_ERROR_TRACING_BUFFER_FULL                   = 40,
    UM_GSM_ERROR_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA   = 42,
    UM_GSM_ERROR_NUMBER_OF_PW_ATTEMPS_VIOLATION        = 43,
    UM_GSM_ERROR_NUMBER_CHANGED                        = 44,
    UM_GSM_ERROR_BUSY_SUBSCRIBER                       = 45,
    UM_GSM_ERROR_NO_SUBSCRIBER_REPLY                   = 46,
    UM_GSM_ERROR_FORWARDING_FAILED                     = 47,
    UM_GSM_ERROR_OR_NOT_ALLOWED                        = 48,
    UM_GSM_ERROR_ATI_NOT_ALLOWED                       = 49,
    UM_GSM_ERROR_NO_ERROR_CODE_PROVIDED                = 62,
    UM_GSM_ERROR_NO_ROUTE_TO_DESTINATION               = 63,
    UM_GSM_ERROR_UNKNOWN_ALPHABETH                     = 71,
    UM_GSM_ERROR_USSD_BUSY                             = 72,
} UMNetworkError;

NSString *UMNetworkErrorAsString(UMNetworkError e);

