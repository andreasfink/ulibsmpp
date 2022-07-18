//
//  UMSigAddrWithHistory.h
//  ulibsmpp
//
//  Created by Andreas Fink on 18.07.22.
//

#import <ulib/ulib.h>
#import "UMSigAddr.h"

@interface UMSigAddrWithHistory : UMObjectWithHistory
{
    
}

- (void)setSigAddr:(UMSigAddr *)newAddr;
- (UMSigAddr *)sigAddr;
- (UMSigAddr *)currentSigAddr;
- (UMSigAddr *)oldSigAddr;
- (void) loadFromSigAddr:(UMSigAddr *)str;

@end
