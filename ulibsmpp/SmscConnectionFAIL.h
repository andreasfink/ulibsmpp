//
//  SmscConnectionFAIL.h
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC implementation which always return a failed delivery report

#import <ulibsmpp/SmscConnection.h>
#import <ulibsmpp/SmscConnectionMessagePassingProtocol.h>


@interface SmscConnectionFAIL : SmscConnection
{
    SmscRouterError *errorToReturn;
}

@property(readwrite,strong)     SmscRouterError *errorToReturn;

@end
