//
//  SmscMessageWellProtocol.h
//  ulibsmpp
//
//  Created by Andreas Fink on 26/03/15.
//
//



@protocol SmscConnectionMessageProtocol;

@protocol SmscMessageWellProtocol<NSObject>
- (id<SmscConnectionMessageProtocol>)createMessage;
@end
