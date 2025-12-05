//
//  UMDeliveryReportType.h
//  ulibsmpp
//
//  Created by Andreas Fink on 27.03.2025.
//


typedef enum UMDeliveryReportType
{
    SMS_REPORT_UNSET            = -1,
    SMS_REPORT_SUBMITTED        = 0,
    SMS_REPORT_ENROUTE          = 1,
    SMS_REPORT_DELIVERED        = 2,
    SMS_REPORT_EXPIRED          = 3,
    SMS_REPORT_DELETED          = 4,
    SMS_REPORT_UNDELIVERABLE    = 5,
    SMS_REPORT_ACCEPTED         = 6,
    SMS_REPORT_UNKNOWN          = 7,
    SMS_REPORT_REJECTED         = 8,
} UMDeliveryReportType;
