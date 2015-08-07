#import <UIKit/UIKit.h>
#import <substrate.h>

@interface Cydia
- (void) syncData;
- (BOOL) addTrivialSource:(NSString *)href;
@end


static NSMutableArray *arrayOfURLs;
static bool simpleMode = false;

%hook SourcesController
- (void) showAddSourcePrompt {

    if (!simpleMode) {
        NSString *urllist = [[UIPasteboard generalPasteboard] string];
        if (urllist.length) {

            NSError *error = NULL;

            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"https?://([-\\w\\.]+)+(:\\d+)?(/([\\w/_\\.]*(\\?\\S+)?)?)?" options:NSRegularExpressionCaseInsensitive error:&error];

            NSArray *arrayOfAllMatches = [regex matchesInString:urllist options:0 range:NSMakeRange(0, [urllist length])];

            arrayOfURLs = [[NSMutableArray alloc] init];

            for (NSTextCheckingResult *match in arrayOfAllMatches) {    
                NSString* substringForMatch = [urllist substringWithRange:match.range];

                NSURL *candidateURL = [NSURL URLWithString:substringForMatch];
                if (candidateURL && candidateURL.scheme && candidateURL.host) {
                    [arrayOfURLs addObject:substringForMatch];
                }
            }

            if ([arrayOfURLs count] > 1) {

                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"⚠️ Multiple Sources Found" message:[NSString stringWithFormat:@"Do you want to add them all?\n\n%@", [arrayOfURLs componentsJoinedByString:@"\n"]] preferredStyle:UIAlertControllerStyleAlert];

                [alertController addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil]];
                [alertController addAction:[UIAlertAction actionWithTitle:@"Add Matched Sources" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    Cydia *cyAppDelegate = (Cydia *)[UIApplication sharedApplication];

                    for (id url in arrayOfURLs)
                        [cyAppDelegate addTrivialSource:url];

                    [cyAppDelegate syncData];
                }]];
                [alertController addAction:[UIAlertAction actionWithTitle:@"Simple Mode" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    simpleMode = true;

                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 30 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                        simpleMode = false;
                    });

                }]];

                [[self navigationController] presentViewController:alertController animated:YES completion:nil];
            }
            else %orig;

        }
        else %orig;
    }
    else %orig;

}

%end

%hook UIAlertView
- (void) show {

    if ([self.context isEqualToString:@"source"] && ([arrayOfURLs count] == 1)) {

        %orig;

        UITextField *textField = [self textFieldAtIndex:0];
        self.title = @"⚠️ URL Detected\nIs that a valid repository?";
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.text = [arrayOfURLs objectAtIndex:0];

    }
    
    %orig;
}

%end
