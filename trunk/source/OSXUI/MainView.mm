//
//  MainView.mm
//  fHashMacUI
//
//  Created by Sun Junwen on 7/15/15.
//  Copyright © 2015 Sun Junwen. All rights reserved.
//

#import "MainView.h"
#import "fHash-Swift.h"
#import "MacUtils.h"

using namespace std;

@implementation MainView

- (void)awakeFromNib {
    [self registerForDraggedTypes:
     [NSArray arrayWithObjects:NSPasteboardTypeFileURL, nil]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
    if ([self.mainViewController ableToCalcFiles])
        return NSDragOperationCopy;
    else
        return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    [self.mainViewController performViewDragOperation:sender];
    
    return YES;
}

@end
