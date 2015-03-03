//
//  MGSSyntaxErrorController.m
//  Fragaria
//
//  Created by Jim Derry on 2/15/15.
//
//

#import "MGSSyntaxErrorController.h"


#define kSMLErrorPopOverMargin        6.0
#define kSMLErrorPopOverErrorSpacing  2.0

/* Set this to 1 to disable suppression of badge icons in the syntax error
 * balloons when there is only a single error to display. */
#define kSMLAlwaysShowBadgesInBalloon 0


static NSInteger CharacterIndexFromRowAndColumn(NSUInteger line, NSUInteger character, NSString* str)
{
    NSScanner* scanner = [NSScanner scannerWithString:str];
    [scanner setCharactersToBeSkipped:[NSCharacterSet characterSetWithCharactersInString:@""]];
    
    character -= character ? 1 : 0;
    
    NSUInteger currentLine = 1;
    while (![scanner isAtEnd])
    {
        if (currentLine == line)
        {
            // Found the right line
            NSInteger location = [scanner scanLocation] + character;
            if (location >= (NSInteger)str.length) location = str.length - 1;
            return location;
        }
        
        // Scan to a new line
        [scanner scanUpToString:@"\n" intoString:NULL];
        
        if (![scanner isAtEnd])
        {
            scanner.scanLocation += 1;
        }
        currentLine++;
    }
    
    return -1;
}


@interface MGSErrorBadgeAttachmentCell : NSTextAttachmentCell

/* This class exists only because NSTextAttachmentCell does not have a setter
 * for cellBaselineOffset. cellBaselineOffset is used to center the badge on
 * the line of the syntax error it is associated with. */

@end

@implementation MGSErrorBadgeAttachmentCell

- (NSPoint)cellBaselineOffset { return NSMakePoint(0,-2); }

@end



@implementation MGSSyntaxErrorController


#pragma mark - Property Accessors


- (void)setSyntaxErrors:(NSArray *)syntaxErrors
{
    NSPredicate *filter = [NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *bindings) {
        return [evaluatedObject isKindOfClass:[SMLSyntaxError class]];
    }];
    _syntaxErrors = [syntaxErrors filteredArrayUsingPredicate:filter];;
    [self updateSyntaxErrorsDisplay];
}


- (void)setShowSyntaxErrors:(BOOL)showSyntaxErrors
{
    _showSyntaxErrors = showSyntaxErrors;
    [self updateSyntaxErrorsDisplay];
}


- (void)setLineNumberView:(MGSLineNumberView *)lineNumberView
{
    [_lineNumberView setDecorationActionTarget:nil];
    _lineNumberView = lineNumberView;
    [_lineNumberView setDecorationActionTarget:self];
    [_lineNumberView setDecorationActionSelector:@selector(clickedError:)];
    [self updateSyntaxErrorsDisplay];
}


- (void)setTextView:(SMLTextView *)textView
{
    if (_textView) {
        [[NSNotificationCenter defaultCenter] removeObserver:self forKeyPath:NSTextDidChangeNotification];
    }
    _textView = textView;
    if (_textView) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(highlightErrors) name:NSTextDidChangeNotification object:_textView];
    }
    [self updateSyntaxErrorsDisplay];
}


#pragma mark - Syntax error display


- (void)updateSyntaxErrorsDisplay
{
    if (_textView) [self highlightErrors];
    if (!_showSyntaxErrors) {
        [self.lineNumberView setDecorations:[NSDictionary dictionary]];
        return;
    }
    [self.lineNumberView setDecorations:[self errorDecorations]];
}


- (void)highlightErrors
{
    SMLTextView* textView = self.textView;
    NSString* text = [textView string];
    NSLayoutManager *layoutManager = [textView layoutManager];
    
    // Clear all highlights
    [layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, text.length)];
    [layoutManager removeTemporaryAttribute:NSToolTipAttributeName forCharacterRange:NSMakeRange(0, text.length)];
    
    if (!self.showSyntaxErrors) return;
    
    // Highlight all errors and add buttons
    NSMutableSet* highlightedRows = [NSMutableSet set];
    
    for (SMLSyntaxError* err in self.syntaxErrors)
    {
        // Highlight an erroneous line
        NSInteger location = CharacterIndexFromRowAndColumn(err.line, err.character, text);
        
        // Skip lines we cannot identify in the text
        if (location == -1) continue;
        
        NSRange lineRange = [text lineRangeForRange:NSMakeRange(location, 0)];
        
        // Highlight row if it is not already highlighted
        if (![highlightedRows containsObject:[NSNumber numberWithUnsignedInteger:err.line]])
        {
            // Remember that we are highlighting this row
            [highlightedRows addObject:[NSNumber numberWithUnsignedInteger:err.line]];
            
            // Add highlight for background
            [layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:err.errorLineHighlightColor forCharacterRange:lineRange];
            
            if ([err.errorDescription length] > 0)
                [layoutManager addTemporaryAttribute:NSToolTipAttributeName value:err.description forCharacterRange:lineRange];
        }
    }
}


#pragma mark - Instance Methods


- (NSArray *)linesWithErrors
{
    return [[self.syntaxErrors filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden == %@", @(NO)]] valueForKeyPath:@"@distinctUnionOfObjects.line"];
}


- (NSUInteger)errorCountForLine:(NSInteger)line
{
    return [[[self.syntaxErrors filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(line == %@) AND (hidden == %@)", @(line), @(NO)]] valueForKeyPath:@"@count"] integerValue];
}


- (SMLSyntaxError *)errorForLine:(NSInteger)line
{
    float highestErrorLevel = [[[self errorsForLine:line] valueForKeyPath:@"@max.warningStyle"] floatValue];
    NSArray* errors = [[self errorsForLine:line] filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"warningStyle = %@", @(highestErrorLevel)]];

    return errors.firstObject;
}


- (NSArray*)errorsForLine:(NSInteger)line
{
    return [self.syntaxErrors filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(line == %@) AND (hidden == %@)", @(line), @(NO)]];
}


- (NSArray *)nonHiddenErrors
{
    return [self.syntaxErrors filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"hidden == %@", @(NO)]];
}


- (NSDictionary *)errorDecorations
{
    return [self errorDecorationsHavingSize:NSMakeSize(0.0, 0.0)];
}


- (NSDictionary *)errorDecorationsHavingSize:(NSSize)size
{
    NSMutableDictionary *result = [[NSMutableDictionary alloc] init];

    for (NSNumber *line in [self linesWithErrors])
    {
        NSImage *image = [[self errorForLine:[line integerValue]] warningImage];
        if (size.height > 0.0 && size.width > 0)
        {
            [image setSize:size];
        }
        [result setObject:image forKey:line];
    }

    return result;
}


#pragma mark - Action methods


- (void)clickedError:(MGSLineNumberView *)sender
{
    NSRect rect;
    NSUInteger selLine;
    
    selLine = [sender selectedLineNumber];
    rect = [sender decorationRectOfLine:selLine];
    [self showErrorsForLine:selLine+1 relativeToRect:rect ofView:sender];
}


- (void)showErrorsForLine:(NSUInteger)line relativeToRect:(NSRect)rect ofView:(NSView*)view
{
    NSArray *errors, *images;
    NSFont* font;
    NSMutableAttributedString *errorsString;
    NSMutableParagraphStyle *parStyle;
    NSTextField *textField;
    NSSize balloonSize;
    NSInteger i, c;
    
    errors = [[self errorsForLine:line] valueForKey:@"errorDescription"];
    images = [[self errorsForLine:line] valueForKey:@"warningImage"];
    if (!(c = [errors count])) return;

    // Create view controller
    NSViewController *vc = [[NSViewController alloc] init];
    [vc setView:[[NSView alloc] init]];

    errorsString = [[NSMutableAttributedString alloc] init];
    i = 0;
    for (NSString* err in errors) {
        NSMutableString *muts;
        NSImage *warnImg;
        NSTextAttachment *attachment;
        MGSErrorBadgeAttachmentCell *attachmentCell;
        NSAttributedString *attachmStr;

        muts = [err mutableCopy];
        [muts replaceOccurrencesOfString:@"\n" withString:@"\u2028" options:0 range:NSMakeRange(0, [muts length])];
        if (i != 0)
            [[errorsString mutableString] appendString:@"\n"];
        
        if (kSMLAlwaysShowBadgesInBalloon || c > 1) {
            warnImg = [[images objectAtIndex:i] copy];
            [warnImg setSize:NSMakeSize(11,11)];
            
            attachment = [[NSTextAttachment alloc] init];
            attachmentCell = [[MGSErrorBadgeAttachmentCell alloc] initImageCell:warnImg];
            [attachment setAttachmentCell:attachmentCell];
            attachmStr = [NSAttributedString attributedStringWithAttachment:attachment];
            [errorsString appendAttributedString:attachmStr];
            [[errorsString mutableString] appendString:@" "];
        }
        
        [[errorsString mutableString] appendString:muts];
        i++;
    }

    font = [NSFont systemFontOfSize:10];
    parStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
    [parStyle setParagraphSpacing:kSMLErrorPopOverErrorSpacing];
    [errorsString addAttributes: @{NSParagraphStyleAttributeName: parStyle,
      NSFontAttributeName: font} range:NSMakeRange(0, [errorsString length])];

    textField = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [textField setAllowsEditingTextAttributes:YES];
    [textField setAttributedStringValue:errorsString];
    [textField setBezeled:NO];
    [textField setDrawsBackground:NO];
    [textField setEditable:NO];
    [textField setSelectable:NO];
    [textField sizeToFit];
    [textField setFrameOrigin:NSMakePoint(kSMLErrorPopOverMargin, kSMLErrorPopOverMargin)];

    [vc.view addSubview:textField];
    balloonSize = [textField frame].size;
    balloonSize.width += 2 * kSMLErrorPopOverMargin;
    balloonSize.height += 2 * kSMLErrorPopOverMargin;
    [vc.view setFrameSize:balloonSize];

    // Open the popover
    NSPopover* popover = [[NSPopover alloc] init];
    popover.behavior = NSPopoverBehaviorTransient;
    popover.contentSize = vc.view.bounds.size;
    popover.contentViewController = vc;
    popover.animates = YES;

    [popover showRelativeToRect:rect ofView:view preferredEdge:NSMinYEdge];
}


@end



