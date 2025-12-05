//
//  SmscConnectionReadyProtocol.h
//  ulibsmpp
//
//  Created by Andreas Fink on 27.08.21.
//

#import <ulib/ulib.h>

@protocol SmscConnectionReadyProtocol<NSObject>
- (void)readyForMessages:(BOOL)isReady connection:(id)con;
@end

