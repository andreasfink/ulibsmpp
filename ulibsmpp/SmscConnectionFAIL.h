//
//  SmscConnectionFAIL.h
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC implementation which always return a failed delivery report

#import "SmscConnection.h"
#import "SmscConnectionMessagePassingProtocol.h"


@interface SmscConnectionFAIL : SmscConnection
{
    SmscRouterError *errorToReturn;
}

@property(readwrite,strong)     SmscRouterError *errorToReturn;

@end
