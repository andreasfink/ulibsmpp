//
//  SmscConnectionNACK.h
//  ulibsmpp
//
//  Created by Andreas Fink on 17.11.14.
//
// An SMSC which always return NACK on submit or deliver

#import "SmscConnection.h"
#import "SmscConnectionMessagePassingProtocol.h"

@interface SmscConnectionNACK : SmscConnection

@end
