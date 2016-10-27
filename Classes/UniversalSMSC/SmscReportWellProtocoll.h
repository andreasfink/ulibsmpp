//
//  SmscReportWellProtocoll.h
//  ulibsmpp
//
//  Created by Andreas Fink on 26/03/15.
//
//

@protocol SmscConnectionMessageProtocol;

@protocol SmscReportWellProtocoll<NSObject>
- (id<SmscConnectionReportProtocol>)createReport;
@end
