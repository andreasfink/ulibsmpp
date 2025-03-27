//
//  SmscConnectionMessagePassingProtocol.h
//  ulibsmpp
//
//  Created by Andreas Fink on 26/03/15.
//
//

/*  the message passing protocol specifies the minimum
    methods to send/receive messages
    between SMSC layers
    messages in one directions are "submit"
    messages in the other direction are "deliver"
    they also exist for reports
    and all methods are being confirmed as Sent or Failed.
 
    the sender of a message might send it synchronously and locks 
    a current transaction. This means if a SMSC layer returns with an error immediately
    it would lock itself before returning from the sending action.
 
    thats why we use the synchronous method. If we get called synchronously, an
    immediate error returned will be send back asynchronoulsy (which means the
    other entity should queue it for later processing.
 
    If we get called asynchronously, we can however call back synchronously as we are
    already detached from the transaction.
 
    This is especially necessary for dummy SMSCs which return success/failure
    but also  in the case of SMPP where a SubmitMessageAck with a message id needs
    to be processed immediately before any delivery reports come in which might process
    the same message as those requests might get processed in parallel so you could end
    up in a race condition.
 
 */
 
//#import <ulibsmpp/SmscConnectionMessageProtocol.h>
#import <ulibsmpp/SmscConnectionReportProtocol.h>
#import <um/um.h>

@protocol SmscConnectionMessagePassingProtocol<NSObject>

- (void) submitMessage:(UMMessage *)msg
             forObject:(id)sendingObject
           synchronous:(BOOL)sync;

- (void) submitMessageSent:(UMMessage *)msg
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync;

- (void) submitMessageFailed:(UMMessage *)msg
                   withError:(SmscRouterError *)err
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync;


- (void) submitReport:(UMMessageReport *)r
            forObject:(id)sendingObject
          synchronous:(BOOL)sync;

- (void) submitReportSent:(UMMessageReport *)r
                forObject:(id)reportingObject
              synchronous:(BOOL)sync;

- (void) submitReportFailed:(UMMessageReport *)r
                  withError:(SmscRouterError *)err
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync;

- (void) deliverMessage:(UMMessage *)msg
              forObject:(id)sendingObject
            synchronous:(BOOL)sync;

- (void) deliverMessageSent:(UMMessage *)msg
                  forObject:(id)reportingObject
                synchronous:(BOOL)sync;

- (void) deliverMessageFailed:(UMMessage *)msg
                    withError:(SmscRouterError *)err
                    forObject:(id)reportingObject
                  synchronous:(BOOL)sync;


- (void) deliverReport:(UMMessageReport *)report
             forObject:(id)sendingObject
           synchronous:(BOOL)sync;

- (void) deliverReportSent:(UMMessageReport *)report
                 forObject:(id)reportingObject
               synchronous:(BOOL)sync;

- (void) deliverReportFailed:(UMMessageReport *)report
                   withError:(SmscRouterError *)err
                   forObject:(id)reportingObject
                 synchronous:(BOOL)sync;

@end
