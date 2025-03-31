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
/*
 
 typedef struct SmppErrorCodeListEntry
 {
     SmppErrorCode    code;
     const char      *text;
     const char      *description;
 } SmppErrorCodeListEntry;

 const SmppErrorCodeListEntry SmppErrorCodeList[] =
 {
     { ESME_ROK,"ESME_ROK","No Error" },
     { ESME_RINVMSGLEN,"ESME_RINVMSGLEN","Message Length is invalid" },
     { ESME_RINVCMDLEN,"ESME_RINVCMDLEN","Command Length is invalid" },
     { ESME_RINVCMDID,"ESME_RINVCMDID","Invalid Command ID" },
     { ESME_RINVBNDSTS,"ESME_RINVBNDSTS","Incorrect BIND Status for given command" },
     { ESME_RALYBND,"ESME_RALYBND","ESME Already in Bound State" },
     { ESME_RINVPRTFLG,"ESME_RINVPRTFLG","Invalid Priority Flag" },
     { ESME_RINVREGDLVFLG,"ESME_RINVREGDLVFLG","Invalid Registered Delivery Flag" },
     { ESME_RSYSERR,"ESME_RSYSERR","System Error" },
     { ESME_RINVSRCADR,"ESME_RINVSRCADR","Invalid Source Address" },
     { ESME_RINVDSTADR,"ESME_RINVDSTADR","Invalid Dest Addr" },
     { ESME_RINVMSGID,"ESME_RINVMSGID","Message ID is invalid" },
     { ESME_RBINDFAIL,"ESME_RBINDFAIL","Bind Failed" },
     { ESME_RINVPASWD,"ESME_RINVPASWD","Invalid Password" },
     { ESME_RINVSYSID,"ESME_RINVSYSID","Invalid System ID" },
     { ESME_RCANCELFAIL,"ESME_RCANCELFAIL","Cancel SM Failed" },
     { ESME_RREPLACEFAIL,"ESME_RREPLACEFAIL","Replace SM Failed" },
     { ESME_RMSGQFUL,"ESME_RMSGQFUL","Message Queue Full" },
     { ESME_RINVSERTYP,"ESME_RINVSERTYP","Invalid Service Type" },
     { ESME_RINVNUMDESTS,"ESME_RINVNUMDESTS","Invalid number of destinations" },
     { ESME_RINVDLNAME,"ESME_RINVDLNAME","Invalid Distribution List name" },
     { ESME_RINVDESTFLAG,"ESME_RINVDESTFLAG","Destination flag is invalid" },
     { ESME_RINVSUBREP,"ESME_RINVSUBREP","Invalid 'submit with replace' request" },
     { ESME_RINVESMCLASS,"ESME_RINVESMCLASS","Invalid esm_class field data" },
     { ESME_RCNTSUBDL,"ESME_RCNTSUBDL","Cannot Submit to Distribution List" },
     { ESME_RSUBMITFAIL,"ESME_RSUBMITFAIL","submit_sm or submit_multi failed" },
     { ESME_RINVSRCTON,"ESME_RINVSRCTON","Invalid Source address TON" },
     { ESME_RINVSRCNPI,"ESME_RINVSRCNPI","Invalid Source address NPI" },
     { ESME_RINVDSTTON,"ESME_RINVDSTTON","Invalid Destination address TON" },
     { ESME_RINVDSTNPI,"ESME_RINVDSTNPI","Invalid Destination address NPI" },
     { ESME_RINVSYSTYP,"ESME_RINVSYSTYP","Invalid system_type field" },
     { ESME_RINVREPFLAG,"ESME_RINVREPFLAG","Invalid replace_if_present flag" },
     { ESME_RINVNUMMSGS,"ESME_RINVNUMMSGS","Invalid number of messages" },
     { ESME_RTHROTTLED,"ESME_RTHROTTLED","Throttling error (ESME has exceeded" },
     { ESME_RINVSCHED,"ESME_RINVSCHED","Invalid Scheduled Delivery Time" },
     { ESME_RINVEXPIRY,"ESME_RINVEXPIRY","Invalid message validity period" },
     { ESME_RINVDFTMSGID,"ESME_RINVDFTMSGID","Predefined Message Invalid or Not" },
     { ESME_RX_T_APPN,"ESME_RX_T_APPN","ESME Receiver Temporary App" },
     { ESME_RX_P_APPN,"ESME_RX_P_APPN","ESME Receiver Permanent App Error" },
     { ESME_RX_R_APPN,"ESME_RX_R_APPN","ESME Receiver Reject Message Error" },
     { ESME_RQUERYFAIL,"ESME_RQUERYFAIL","query_sm request failed" },
     { ESME_RINVOPTPARSTREAM,"ESME_RINVOPTPARSTREAM","Error in the optional part of the PDU" },
     { ESME_ROPTPARNOTALLWD,"ESME_ROPTPARNOTALLWD","Optional Parameter not allowed" },
     { ESME_RINVPARLEN,"ESME_RINVPARLEN","Invalid Parameter Length." },
     { ESME_RMISSINGOPTPARAM,"ESME_RMISSINGOPTPARAM","Expected Optional Parameter missing" },
     { ESME_RINVOPTPARAMVAL,"ESME_RINVOPTPARAMVAL","Invalid Optional Parameter Value" },
     { ESME_RDELIVERYFAILURE,"ESME_RDELIVERYFAILURE","Delivery Failure" },
     { ESME_RUNKNOWNERR,"ESME_RUNKNOWNERR","Unknown Error" },
 }
 */
