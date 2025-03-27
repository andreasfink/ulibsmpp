//
//  SmscStandardReport.h
//  ulibsmpp
//
//  Created by Andreas Fink on 14.11.14.
//
//
#if 0
#import <ulib/ulib.h>
#import <ulibsmpp/SmscConnectionReportProtocol.h>

@interface SmscStandardReport : UMObject <SmscConnectionReportProtocol>
{
    NSString    *_userReference;
    NSString    *_routerReference;
    NSString    *_providerReference;
    NSString    *_fromNumber;
    NSString    *_toNumber;
    NSString    *_reportText;
    SmscRouterError *_error;
    int         _priority;
    id          _originalSendingObject;
    NSString    *_imsi;
    NSString    *_msc;
    NSString    *_mcc;
    NSString    *_mnc;
    int         _responseCode;
    UMMessageReport *   _reportToMsg;
    NSString    *_reportTypeAsString;
    UMDeliveryReportType _reportType;
    id          _currentTransaction;
}

@property(readwrite,strong)  NSString    *userReference;
@property(readwrite,strong)  NSString    *routerReference;
@property(readwrite,strong)  NSString    *providerReference;
@property(readwrite,strong) NSString   *fromNumber;
@property(readwrite,strong) NSString   *toNumber;
@property(readwrite,strong)  NSString    *reportText;
@property(readwrite,strong)  SmscRouterError *error;
@property(readwrite,assign)  int         priority;
@property(readwrite,strong)  id          originalSendingObject;
@property(readwrite,strong)  NSString    *imsi;
@property(readwrite,strong)  NSString    *msc;
@property(readwrite,strong)  NSString    *mcc;
@property(readwrite,strong)  NSString    *mnc;
@property(readwrite,assign)  int         responseCode;
@property(readwrite,strong)  UMMessageReport *   reportToMsg;
@property(readwrite,strong)  NSString    *reportTypeAsString;
@property(readwrite,assign) DeliveryReportType reportType;
@property(readwrite,strong) id          currentTransaction;


@end
#endif

