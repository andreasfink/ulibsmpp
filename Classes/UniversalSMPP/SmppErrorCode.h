//
//  SmppErrorCode.h
//  ulibsmpp
//
//  Created by Andreas Fink on 28/03/14.
//
//

typedef enum SmppErrorCode
{
    ESME_ROK                                                               = 0x00000000,
    ESME_RINVMSGLEN                                                        = 0x00000001,
    ESME_RINVCMDLEN                                                        = 0x00000002,
    ESME_RINVCMDID                                                         = 0x00000003,
    ESME_RINVBNDSTS                                                        = 0x00000004,
    ESME_RALYBND                                                           = 0x00000005,
    ESME_RINVPRTFLG                                                        = 0x00000006,
    ESME_RINVREGDLVFLG                                                     = 0x00000007,
    ESME_RSYSERR                                                           = 0x00000008,
    ESME_RINVSRCADR                                                        = 0x0000000A,
    ESME_RINVDSTADR                                                        = 0x0000000B,
    ESME_RINVMSGID                                                         = 0x0000000C,
    ESME_RBINDFAIL                                                         = 0x0000000D,
    ESME_RINVPASWD                                                         = 0x0000000E,
    ESME_RINVSYSID                                                         = 0x0000000F,
    ESME_RCANCELFAIL                                                       = 0x00000011,
    ESME_RREPLACEFAIL                                                      = 0x00000013,
    ESME_RMSGQFUL                                                          = 0x00000014,
    ESME_RINVSERTYP                                                        = 0x00000015,
    ESME_RINVNUMDESTS                                                      = 0x00000033,
    ESME_RINVDLNAME                                                        = 0x00000034,
    ESME_RINVDESTFLAG                                                      = 0x00000040,
    ESME_RINVSUBREP                                                        = 0x00000042,
    ESME_RINVESMCLASS                                                      = 0x00000043,
    ESME_RCNTSUBDL                                                         = 0x00000044,
    ESME_RSUBMITFAIL                                                       = 0x00000045,
    ESME_RINVSRCTON                                                        = 0x00000048,
    ESME_RINVSRCNPI                                                        = 0x00000049,
    ESME_RINVDSTTON                                                        = 0x00000050,
    ESME_RINVDSTNPI                                                        = 0x00000051,
    ESME_RINVSYSTYP                                                        = 0x00000053,
    ESME_RINVREPFLAG                                                       = 0x00000054,
    ESME_RINVNUMMSGS                                                       = 0x00000055,
    ESME_RTHROTTLED                                                        = 0x00000058,
    ESME_RINVSCHED                                                         = 0x00000061,
    ESME_RINVEXPIRY                                                        = 0x00000062,
    ESME_RINVDFTMSGID                                                      = 0x00000063,
    ESME_RX_T_APPN                                                         = 0x00000064,
    ESME_RX_P_APPN                                                         = 0x00000065,
    ESME_RX_R_APPN                                                         = 0x00000066,
    ESME_RQUERYFAIL                                                        = 0x00000067,
    ESME_RINVOPTPARSTREAM                                                  = 0x000000C0,
    ESME_ROPTPARNOTALLWD                                                   = 0x000000C1,
    ESME_RINVPARLEN                                                        = 0x000000C2,
    ESME_RMISSINGOPTPARAM                                                  = 0x000000C3,
    ESME_RINVOPTPARAMVAL                                                   = 0x000000C4,
    ESME_RDELIVERYFAILURE                                                  = 0x000000FE,
    ESME_RUNKNOWNERR                                                       = 0x000000FF,
    ESME_RINVUDH                                                           = 0x00000401,
    ESME_VENDOR_SPECIFIC_INVALID_INTERNAL_CONFIG                           = 0x10000048,
    ESME_VENDOR_SPECIFIC_NO_PROVIDER_FOUND                                 = 0x10000049,
    ESME_VENDOR_SPECIFIC_NO_PROFITABLE_ROUTE_FOUND                         = 0x10000050,
    ESME_VENDOR_SPECIFIC_NO_PRICING_TABLE_FOUND                            = 0x10000051,
    ESME_VENDOR_SPECIFIC_NO_DELIVERER                                      = 0x10000052,
    ESME_VENDOR_SPECIFIC_NO_SUCH_COUNTRY                                   = 0x10000053,
    ESME_VENDOR_SPECIFIC_NO_SUCH_USER                                      = 0x10000054,
    ESME_VENDOR_SPECIFIC_USER_OUT_OF_CREDIT                                = 0x10000055,
    ESME_VENDOR_SPECIFIC_NO_PROVIDER                                       = 0x10000056,
    ESME_VENDOR_SPECIFIC_NO_USER                                           = 0x10000057,
    ESME_VENDOR_SPECIFIC_NUMBER_PREFIX_NOT_FOUND                           = 0x10000058,
    ESME_VENDOR_SPECIFIC_HLR_ROUTING_TABLE_NOT_FOUND	                   = 0x10000059,
    ESME_VENDOR_SPECIFIC_NUMBER_PREFIX_TABLE_NOT_FOUND	                   = 0x10000060,
    ESME_VENDOR_SPECIFIC_COUNTRY_NOT_FOUND                                 = 0x10000061,
    ESME_VENDOR_SPECIFIC_NO_PRICE_FOUND                                    = 0x10000062,
    ESME_VENDOR_SPECIFIC_OFFLINE                                           = 0x10000063,
    ESME_VENDOR_SPECIFIC_NO_ROUTING_TABLE                                  = 0x10000064,
    ESME_VENDOR_SPECIFIC_NO_ROUTING_TABLE_ENTRY                            = 0x10000065,
    ESME_VENDOR_SPECIFIC_NO_ROUTE                                          = 0x10000066,
    ESME_VENDOR_SPECIFIC_NO_PROVIDER_NAME                                  = 0x10000067,
    ESME_VENDOR_SPECIFIC_UNKNOWN_SUB                                       = 0x10000068,
    ESME_VENDOR_SPECIFIC_UNKNOWN_MSC                                       = 0x10000069,
    ESME_VENDOR_SPECIFIC_UNIDENTIFIED_SUB                                  = 0x10000070,
    ESME_VENDOR_SPECIFIC_ABSENT_SUB_SM                                     = 0x10000071,
    ESME_VENDOR_SPECIFIC_UNKNOWN_EQUIPMENT                                 = 0x10000072,
    ESME_VENDOR_SPECIFIC_NOROAM                                            = 0x10000073,
    ESME_VENDOR_SPECIFIC_ILLEGAL_SUB                                       = 0x10000074,
    ESME_VENDOR_SPECIFIC_BEARER_SERVICE_NOT_PROVISIONED	                   = 0x10000075,
    ESME_VENDOR_SPECIFIC_NOT_PROV                                          = 0x10000076,
    ESME_VENDOR_SPECIFIC_ILLEGAL_EQUIPMENT                                 = 0x10000077,
    ESME_VENDOR_SPECIFIC_BARRED                                            = 0x10000078,
    ESME_VENDOR_SPECIFIC_FORWARDING_VIOLATION                              = 0x10000079,
    ESME_VENDOR_SPECIFIC_CUG_REJECT                                        = 0x10000080,
    ESME_VENDOR_SPECIFIC_ILLEGAL_SS                                        = 0x10000081,
    ESME_VENDOR_SPECIFIC_SS_ERR_STATUS                                     = 0x10000082,
    ESME_VENDOR_SPECIFIC_SS_NOTAVAIL                                       = 0x10000083,
    ESME_VENDOR_SPECIFIC_SS_SUBVIOL                                        = 0x10000084,
    ESME_VENDOR_SPECIFIC_SS_INCOMPAT                                       = 0x10000085,
    ESME_VENDOR_SPECIFIC_NOT_SUPPORTED                                     = 0x10000086,
    ESME_VENDOR_SPECIFIC_MEMORY_CAP_EXCEED                                 = 0x10000087,
    ESME_VENDOR_SPECIFIC_NO_HANDOVER_NUMBER_AVAILABLE	                   = 0x10000088,
    ESME_VENDOR_SPECIFIC_SUBSEQUENT_HANDOVER_FAILURE	                   = 0x10000089,
    ESME_VENDOR_SPECIFIC_ABSENT_SUB                                        = 0x10000090,
    ESME_VENDOR_SPECIFIC_INCOMPATIBLE_TERMINAL                             = 0x10000091,
    ESME_VENDOR_SPECIFIC_SHORT_TERM_DENIAL                                 = 0x10000092,
    ESME_VENDOR_SPECIFIC_LONG_TERM_DENIAL                                  = 0x10000093,
    ESME_VENDOR_SPECIFIC_SM_SUBSCRIBER_BUSY                                = 0x10000094,
    ESME_VENDOR_SPECIFIC_SM_DELIVERY_FAILURE                               = 0x10000095,
    ESME_VENDOR_SPECIFIC_MESSAGE_WAITING_LIST_FULL                         = 0x10000096,
    ESME_VENDOR_SPECIFIC_SYSTEM_FAILURE                                    = 0x10000097,
    ESME_VENDOR_SPECIFIC_DATA_MISSING                                      = 0x10000098,
    ESME_VENDOR_SPECIFIC_UNEXP_VAL                                         = 0x10000099,
    ESME_VENDOR_SPECIFIC_PW_REGISTRATION_FAILURE                           = 0x10000100,
    ESME_VENDOR_SPECIFIC_NEGATIVE_PW_CHECK                                 = 0x10000101,
    ESME_VENDOR_SPECIFIC_NO_ROAMING_NUMBER_AVAILABLE	                   = 0x10000102,
    ESME_VENDOR_SPECIFIC_TRACING_BUFFER_FULL                               = 0x10000103,
    ESME_VENDOR_SPECIFIC_TARGET_CELL_OUTSIDE_GROUP_CALL_AREA               = 0x10000104,
    ESME_VENDOR_SPECIFIC_NUMBER_OF_PW_ATTEMPS_VIOLATION	                   = 0x10000105,
    ESME_VENDOR_SPECIFIC_NUMBER_CHANGED                                    = 0x10000106,
    ESME_VENDOR_SPECIFIC_BUSY_SUBSCRIBER                                   = 0x10000107,
    ESME_VENDOR_SPECIFIC_NO_SUBSCRIBER_REPLY                               = 0x10000108,
    ESME_VENDOR_SPECIFIC_FORWARDING_FAILED                                 = 0x10000109,
    ESME_VENDOR_SPECIFIC_OR_NOT_ALLOWED                                    = 0x10000110,
    ESME_VENDOR_SPECIFIC_ATI_NOT_ALLOWED                                   = 0x10000111,
    ESME_VENDOR_SPECIFIC_NO_ERROR_CODE_PROVIDED                            = 0x10000112,
    ESME_VENDOR_SPECIFIC_NO_ROUTE_TO_DESTINATION                           = 0x10000113,
    ESME_VENDOR_SPECIFIC_UNKNOWN_ALPHABETH                                 = 0x10000114,
    ESME_VENDOR_SPECIFIC_USSD_BUSY                                         = 0x10000115,
    ESME_VENDOR_SPECIFIC_SCCP_NO_TRANSLATION_FOR_AN_ADDRESS_OF_SUCH_NATURE = 0x10000116,
    ESME_VENDOR_SPECIFIC_SCCP_NO_TRANSLATION_FOR_THIS_SPECIFIC_ADDRESS     = 0x10000117,
    ESME_VENDOR_SPECIFIC_SCCP_SUBSYSTEM_CONGESTION                         = 0x10000118,
    ESME_VENDOR_SPECIFIC_SCCP_SUBSYSTEM_FAILURE                            = 0x10000119,
    ESME_VENDOR_SPECIFIC_SCCP_UNEQUIPPED_FAILURE                           = 0x10000120,
    ESME_VENDOR_SPECIFIC_SCCP_MTP_FAILURE                                  = 0x10000121,
    ESME_VENDOR_SPECIFIC_SCCP_NETWORK_CONGESTION                           = 0x10000122,
    ESME_VENDOR_SPECIFIC_SCCP_UNQUALIFIED                                  = 0x10000123,
    ESME_VENDOR_SPECIFIC_SCCP_ERROR_IN_MESSAGE_TRANSPORT                   = 0x10000124,
    ESME_VENDOR_SPECIFIC_SCCP_ERROR_IN_LOCAL_PROCESSING                    = 0x10000125,
    ESME_VENDOR_SPECIFIC_SCCP_DESTINATION_CANNOT_PERFORM_REASSEMBLY	       = 0x10000126,
    ESME_VENDOR_SPECIFIC_SCCP_FAILURE                                      = 0x10000127,
    ESME_VENDOR_SPECIFIC_SCCP_HOP_COUNTER_VIOLATION                        = 0x10000128,
    ESME_VENDOR_SPECIFIC_SCCP_SEGMENTATION_NOT_SUPPORTED	               = 0x10000129,
    ESME_VENDOR_SPECIFIC_SCCP_SEGMENTATION_FAILURE                         = 0x10000130,
    ESME_VENDOR_SPECIFIC_FAILED_TO_DELIVER                                 = 0x10000131,
    ESME_VENDOR_SPECIFIC_UNEXP_TCAP_MSG                                    = 0x10000132,
    ESME_VENDOR_SPECIFIC_FAILED_TO_REQ_ROUTING_INFO                        = 0x10000133,
    ESME_VENDOR_SPECIFIC_TIMER_EXP                                         = 0x10000134,
    ESME_VENDOR_SPECIFIC_TCAP_ABORT1                                       = 0x10000135,
    ESME_VENDOR_SPECIFIC_TCAP_ABORT2                                       = 0x10000136,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_SMSC                                  = 0x10000137,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_DPC                                   = 0x10000138,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_OPC                                   = 0x10000139,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_DESTINATION                           = 0x10000140,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_PREFIX                                = 0x10000141,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_TEXT                                  = 0x10000142,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_IMSI_PREFIX                           = 0x10000143,
    ESME_VENDOR_SPECIFIC_CHARGING_NOT_DEFINED                              = 0x10000144,
    ESME_VENDOR_SPECIFIC_QUOTA_REACHED                                     = 0x10000145,
    ESME_VENDOR_SPECIFIC_CHARGING_BLOCKED                                  = 0x10000146,
    ESME_VENDOR_SPECIFIC_BLACKLISTED_MSC                                   = 0x10000147,
    ESME_VENDOR_SPECIFIC_UNKNOWN_USER                                      = 0x10000148,
    ESME_VENDOR_SPECIFIC_UNKNOWN_METHOD                                    = 0x10000149,
    ESME_VENDOR_SPECIFIC_NOT_IMPLEMENTED                                   = 0x10000150,
    ESME_VENDOR_SPECIFIC_PDU_CAN_NOT_BE_ENCODED                            = 0x10000151,
    ESME_VENDOR_SPECIFIC_TCAP_USER_ABORT                                   = 0x10000152,
    ESME_VENDOR_SPECIFIC_ABORT_BY_SCRIPT                                   = 0x10000153,
    ESME_VENDOR_SPECIFIC_MAX_ATTEMPTS_REACHED                              = 0x10000154,
    ESME_VENDOR_SPECIFIC_ALL_OUTGOING_CONNECTION_UNAVAILABLE               = 0x10000200,
    ESME_VENDOR_SPECIFIC_THIS_OUTGOING_CONNECTION_UNAVAILABLE              = 0x10000201,

} SmppErrorCode;

