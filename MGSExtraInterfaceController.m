/*
 
 MGSFragaria
 Written by Jonathan Mitchell, jonathan@mugginsoft.com
 Find the latest version at https://github.com/mugginsoft/Fragaria
 
Smultron version 3.6b1, 2009-09-12
Written by Peter Borg, pgw3@mac.com
Find the latest version at http://smultron.sourceforge.net

Copyright 2004-2009 Peter Borg
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
 
http://www.apache.org/licenses/LICENSE-2.0
 
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
*/

#import "MGSFragaria.h"
#import "MGSFragariaFramework.h"
#import "SMLTextView+MGSTextActions.h"

// class extension
@interface MGSExtraInterfaceController()
@end

@implementation MGSExtraInterfaceController

@synthesize openPanelAccessoryView, openPanelEncodingsPopUp, commandResultWindow, commandResultTextView;

#pragma mark -
#pragma mark Instance methods

/*
 
 - init
 
 */
- (id)init 
{
	self = [super init];
	return self;
}

#pragma mark -
#pragma mark Tabbing
/*
 
 - displayEntab
 
 */

- (void)displayEntab
{
    NSWindow *wnd;
    
	if (entabWindow == nil) {
		[NSBundle loadNibNamed:@"SMLEntab.nib" owner:self];
	}
	
    wnd = [_completionTarget window];
	[NSApp beginSheet:entabWindow modalForWindow:wnd modalDelegate:self didEndSelector:nil contextInfo:nil];
}

/*
 
 - displayDetab
 
 */
- (void)displayDetab
{
    NSWindow *wnd;
    
	if (detabWindow == nil) {
		[NSBundle loadNibNamed:@"SMLDetab.nib" owner:self];
	}
	
    wnd = [_completionTarget window];
	[NSApp beginSheet:detabWindow modalForWindow:wnd modalDelegate:self didEndSelector:nil contextInfo:nil];
}


/*
 
 - entabButtonEntabWindowAction:
 
 */
- (IBAction)entabButtonEntabWindowAction:(id)sender
{
	NSWindow *wnd = [_completionTarget window];
	
	[NSApp endSheet:[wnd attachedSheet]];
	[[wnd attachedSheet] close];
	
    [_completionTarget performEntab];
}

/*
 
 - detabButtonDetabWindowAction
 
 */
- (IBAction)detabButtonDetabWindowAction:(id)sender
{
    NSWindow *wnd = [_completionTarget window];
    
    [NSApp endSheet:[wnd attachedSheet]];
    [[wnd attachedSheet] close];
	
	[_completionTarget performDetab];
}

#pragma mark -
#pragma mark Goto 

/*
 
 - cancelButtonEntabDetabGoToLineWindowsAction:
 
 */
- (IBAction)cancelButtonEntabDetabGoToLineWindowsAction:(id)sender
{
    NSWindow *wnd = [_completionTarget window];
    
    [NSApp endSheet:[wnd attachedSheet]];
    [[wnd attachedSheet] close];
}


/*
 
 - displayGoToLine
 
 */
- (void)displayGoToLine
{
    NSWindow *wnd = [_completionTarget window];
    
	if (goToLineWindow == nil) {
		[NSBundle loadNibNamed:@"SMLGoToLine.nib" owner:self];
	}
	
	[NSApp beginSheet:goToLineWindow modalForWindow:wnd modalDelegate:self didEndSelector:nil contextInfo:nil];
}

/*
 
 - goButtonGoToLineWindowAction
 
 */
- (IBAction)goButtonGoToLineWindowAction:(id)sender
{
    NSWindow *wnd = [_completionTarget window];
    
    [NSApp endSheet:[wnd attachedSheet]];
    [[wnd attachedSheet] close];
	
	[_completionTarget performGoToLine:[lineTextFieldGoToLineWindow integerValue]];
}

#pragma mark -
#pragma mark Panels
/*
 
 - openPanelEncodingsPopUp
 
 */
- (NSPopUpButton *)openPanelEncodingsPopUp
{
	if (openPanelEncodingsPopUp == nil) {
		[NSBundle loadNibNamed:@"SMLOpenPanelAccessoryView.nib" owner:self];
	}
	
	return openPanelEncodingsPopUp;
}

/*
 
 - openPanelAccessoryView
 
 */
- (NSView *)openPanelAccessoryView
{
	if (openPanelAccessoryView == nil) {
		[NSBundle loadNibNamed:@"SMLOpenPanelAccessoryView.nib" owner:self];
	}
	
	return openPanelAccessoryView;
}

/*
 
 - showRegularExpressionsHelpPanel
 
 */
- (void)showRegularExpressionsHelpPanel
{
	if (regularExpressionsHelpPanel == nil) {
		[NSBundle loadNibNamed:@"SMLRegularExpressionHelp.nib" owner:self];
	}
	
	[regularExpressionsHelpPanel makeKeyAndOrderFront:nil];
}

#pragma mark -
#pragma mark Command handling

/*
 
 - commandResultWindow
 
 */
- (NSWindow *)commandResultWindow
{
    if (commandResultWindow == nil) {
		[NSBundle loadNibNamed:@"SMLCommandResult.nib" owner:self];
		[commandResultWindow setTitle:COMMAND_RESULT_WINDOW_TITLE];
	}
	
	return commandResultWindow;
}

/*
 
 - commandResultTextView
 
 */
- (NSTextView *)commandResultTextView
{
    if (commandResultTextView == nil) {
		[NSBundle loadNibNamed:@"SMLCommandResult.nib" owner:self];
		[commandResultWindow setTitle:COMMAND_RESULT_WINDOW_TITLE];		
	}
	
	return commandResultTextView; 
}

/*
 
 - showCommandResultWindow
 
 */
- (void)showCommandResultWindow
{
	[[self commandResultWindow] makeKeyAndOrderFront:nil];
}

@end
