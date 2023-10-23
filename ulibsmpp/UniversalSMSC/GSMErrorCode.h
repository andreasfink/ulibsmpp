//
//  GSMErrorCodes.h
//  ulibsmpp
//
//  Created by Andreas Fink on 06/05/15.
//
//


/* GSM Map error codes */

typedef enum GSMErrorCode
{
    GSM_ERROR_NONE                                  = 0,
    GSM_ERROR_UNKNOWN_SUB                           = 1,
    GSM_ERROR_UNKNOWN_MSC                           = 3,
    GSM_ERROR_UNIDENTIFIED_SUB                      = 5,
    GSM_ERROR_ABSENT_SUB_SM                         = 6,
    GSM_ERROR_UNKNOWN_EQUIPMENT                     = 7,
    GSM_ERROR_NOROAM                                = 8,
    GSM_ERROR_ILLEGAL_SUB                           = 9,
    GSM_ERROR_BEARER_SERVICE_NOT_PROVISIONED        = 10,
    GSM_ERROR_NOT_PROV                              = 11,
    GSM_ERROR_ILLEGAL_EQUIPMENT                     = 12,
    GSM_ERROR_BARRED                                = 13,
    GSM_ERROR_FORWARDING_VIOLATION                  = 14,
    GSM_ERROR_CUG_REJECT                            = 15,
    GSM_ERROR_ILLEGAL_SS                            = 16,
    GSM_ERROR_SS_ERR_STATUS                         = 17,
    GSM_ERROR_SS_NOTAVAIL                           = 18,
    GSM_ERROR_SS_SUBVIOL                            = 19,
    GSM_ERROR_SS_INCOMPAT                           = 20,
    GSM_ERROR_NOT_SUPPORTED                         = 21,
    GSM_ERROR_MEMORY_CAP_EXCEED                     = 22,
    GSM_ERROR_NO_HANDOVER_NUMBER_AVAILABLE          = 25,
    GSM_ERROR_SUBSEQUENT_HANDOVER_FAILURE           = 26,
    GSM_ERROR_ABSENT_SUB                            = 27,
    GSM_ERROR_INCOMPATIBLE_TERMINAL                 = 28,
    GSM_ERROR_SHORT_TERM_DENIAL                     = 29,
    GSM_ERROR_LONG_TERM_DENIAL                      = 30,
    GSM_ERROR_SM_SUBSCRIBER_BUSY                    = 31,
    GSM_ERROR_SM_DELIVERY_FAILURE                   = 32,
    GSM_ERROR_MESSAGE_WAITING_LIST_FULL             = 33,
    GSM_ERROR_SYSTEM_FAILURE                        = 34,
    GSM_ERROR_DATA_MISSING                          = 35,
    GSM_ERROR_UNEXP_VAL                             = 36,
    GSM_ERROR_PW_REGISTRATION_FAILURE               = 37,
    GSM_ERROR_NEGATIVE_PW_CHECK                     = 38,
    GSM_ERROR_NO_ROAMING_NUMBER_AVAILABLE           = 39,
    GSM_ERROR_TRACING_BUFFER_FULL                   = 40,
    GSM_ERROR_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA   = 42,
    GSM_ERROR_NUMBER_OF_PW_ATTEMPS_VIOLATION        = 43,
    GSM_ERROR_NUMBER_CHANGED                        = 44,
    GSM_ERROR_BUSY_SUBSCRIBER                       = 45,
    GSM_ERROR_NO_SUBSCRIBER_REPLY                   = 46,
    GSM_ERROR_FORWARDING_FAILED                     = 47,
    GSM_ERROR_OR_NOT_ALLOWED                        = 48,
    GSM_ERROR_ATI_NOT_ALLOWED                       = 49,
    GSM_ERROR_NO_ERROR_CODE_PROVIDED                = 62,
    GSM_ERROR_NO_ROUTE_TO_DESTINATION               = 63,
    GSM_ERROR_UNKNOWN_ALPHABETH                     = 71,
    GSM_ERROR_USSD_BUSY                             = 72,
} GSMErrorCode;


