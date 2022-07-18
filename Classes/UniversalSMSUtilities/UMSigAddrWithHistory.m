//
//  UMSigAddrWithHistory.m
//  ulibsmpp
//
//  Created by Andreas Fink on 18.07.22.
//

#import "UMSigAddrWithHistory.h"

@implementation UMSigAddrWithHistory

-(void)setSigAddr:(UMSigAddr *)newString
{
    _oldValue = _currentValue;
    _currentValue = newString;
    UMSigAddr *old = (UMSigAddr *)_oldValue;
    UMSigAddr *current = (UMSigAddr *)_currentValue;

    _isModified = YES;
    if(old.ton == current.ton)
    {
        if(old.npi == current.npi)
        {
            if(old.pointcode == current.pointcode)
            {
                if(old.addr == current.addr)
                {
                    _isModified = NO;
                }
            }
        }
    }
}

- (UMSigAddr *)currentSigAddr
{
    return (UMSigAddr *)_currentValue;
}

- (UMSigAddr *)oldSigAddr
{
    return (UMSigAddr *)_oldValue;
}

- (UMSigAddr *)sigAddr
{
    return (UMSigAddr *)_currentValue;
}

- (NSString *)description
{
    if(_isModified)
    {
        return [NSString stringWithFormat:@"String '%@' (unmodified)",_currentValue.description];
    }
    else
    {
        return [NSString stringWithFormat:@"String '%@' (changed from '%@')",_currentValue.description,_oldValue.description];
    }
}

- (void)loadFromSigAddr:(UMSigAddr *)sigaddr
{
    
}
@end
