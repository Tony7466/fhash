//
//  MainViewController.swift
//  fHash
//
//  Created by Sun Junwen on 2023/12/6.
//  Copyright © 2023 Sun Junwen. All rights reserved.
//

import Cocoa

let UPPERCASE_DEFAULT_KEY = "upperCaseKey"

private struct MainViewControllerState : OptionSet {
    let rawValue: Int

    static let NONE = MainViewControllerState(rawValue: 1 << 0) // clear state
    static let CALC_ING = MainViewControllerState(rawValue: 1 << 1) // calculating
    static let CALC_FINISH = MainViewControllerState(rawValue: 1 << 2) // calculating finished/stopped
    static let VERIFY = MainViewControllerState(rawValue: 1 << 3) // verfing
    static let WAITING_EXIT = MainViewControllerState(rawValue: 1 << 4) // waiting thread stop and exit
}

class MainViewControllerX: NSViewController, NSTextViewDelegate {
    @IBOutlet var mainScrollView: NSScrollView!
    @IBOutlet var mainTextView: NSTextView!

    @IBOutlet var mainProgressIndicator: ESSProgressIndicator!

    @IBOutlet weak var openButton: NSButton!
    @IBOutlet weak var clearButton: NSButton!
    @IBOutlet weak var verifyButton: NSButton!

    @IBOutlet weak var upperCaseButton: NSButton!

    @IBOutlet weak var speedTextField: NSTextField!

    //@property (assign) sunjwbase::OsMutex *mainMtx;

    var mainText: NSMutableAttributedString?

    var tag = 0

    // private
    private var state: MainViewControllerState?

    private var mainFont: NSFont?

    private var selectedLink: String = ""

    private var calcStartTime: UInt64 = 0
    private var calcEndTime: UInt64 = 0

    private var upperCaseState = false

    //@property (assign) UIBridgeMacUI *uiBridgeMac;
    //@property (assign) ThreadData *thrdData;
    //@property (assign) pthread_t ptHash;

    //@synthesize mainMtx = _mainMtx;
    //@synthesize uiBridgeMac = _uiBridgeMac;

    //@synthesize thrdData = _thrdData;
    //@synthesize ptHash = _ptHash;

    // Not be called on exit.
    // Just for sure.
    deinit {
        // delete _mainMtx;
        // delete _uiBridgeMac;
        // delete _thrdData;
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let fHashDelegate = NSApp.delegate as? fHashMacAppDelegate

        // Initiate.
        fHashDelegate?.mainViewController = self

        let mainView = view as? MainView
        mainView?.mainViewController = self

        // Register NSUserDefaults.
        let defaultsDictionary = [
            UPPERCASE_DEFAULT_KEY : Bool(false)
        ]
        UserDefaults.standard.register(defaults: defaultsDictionary)

        // Load NSUserDefaults.
        let defaultUpperCase = UserDefaults.standard.bool(forKey: UPPERCASE_DEFAULT_KEY)

        // Alloc c++ member.
        //_mainMtx = new OsMutex();
        //_uiBridgeMac = new UIBridgeMacUI(self);
        //_thrdData = new ThreadData();

        let fileMenu = getFileMenu()
        fileMenu?.autoenablesItems = false

        // Set buttons title.
        verifyButton.title = MacSwiftUtils.GetStringFromRes("MAINDLG_VERIFY")
        upperCaseButton.title = MacSwiftUtils.GetStringFromRes("MAINDLG_UPPER_HASH")

        // Set open button as default.
        openButton.keyEquivalent = "\r"

        // Set scroll view border type.
        mainScrollView.borderType = .noBorder

        // Set some text in text field.
        mainTextView.delegate = self
        mainTextView.textContainerInset = NSMakeSize(3.0, 2.0)

        if MacSwiftUtils.IsSystemEarlierThan(10, 15) {
            mainFont = NSFont(name: "Monaco", size: 12)
        } else {
            mainFont = .monospacedSystemFont(ofSize: 12, weight: .regular)
        }
        if mainFont == nil {
            mainFont = mainTextView.font
        }

        mainTextView.font = mainFont

        mainTextView.usesFindBar = true

        // Set TextView nowrap.
        mainTextView.enclosingScrollView?.hasHorizontalScroller = true
        mainTextView.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        mainTextView.isHorizontallyResizable = true
        mainTextView.autoresizingMask = [.width, .height]
        mainTextView.textContainer?.containerSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        mainTextView.textContainer?.widthTracksTextView = false

        // Set TextView word wrap.
        // let contentSize = mainScrollView.contentSize
        // mainTextView.enclosingScrollView?.hasHorizontalScroller = false
        // mainTextView.minSize = NSMakeSize(0.0, contentSize.height)
        // mainTextView.maxSize = NSMakeSize(CGFloat.greatestFiniteMagnitude, CGFloat.greatestFiniteMagnitude)
        // mainTextView.isVerticallyResizable = true
        // mainTextView.isHorizontallyResizable = false
        // mainTextView.autoresizingMask = .width
        // mainTextView.textContainer?.containerSize = NSMakeSize(contentSize.width, CGFloat.greatestFiniteMagnitude)
        // mainTextView.textContainer?.widthTracksTextView = true

        // Set progressbar.
        let mainProgIndiFrame = mainProgressIndicator.frame
        mainProgressIndicator.setFrameSize(NSMakeSize(mainProgIndiFrame.size.width, 2))
        //mainProgressIndicator.maxValue = uiBridgeMac.getProgMax()

        // Set checkbox.
        if defaultUpperCase {
            upperCaseButton.state = .on
        } else {
            upperCaseButton.state = .off
        }
        self.updateUpperCaseState()

        // Update main text.
        self.updateMainTextView()
    }

    override func viewWillDisappear() {
        // Save NSUserDefaults.
        let defaultUpperCase = (upperCaseButton.state == .on)
        UserDefaults.standard.set(
            defaultUpperCase,
            forKey: UPPERCASE_DEFAULT_KEY)

        // Close other windows.
        let windows = NSApplication.shared.windows
        let windowCount = windows.count
        for i in 0..<windowCount {
            let window = windows[i]
            let windowController = window.windowController
            if windowController == nil || !(windowController is MainWindowController) {
                // It looks like about panel or finder overlay window.
                // They will stop us exit, let's close them.
                window.close()
            }
        }
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    private func getFileMenu() -> NSMenu? {
        let mainMenu = NSApp.mainMenu
        let fileMenuItem = mainMenu?.item(at: 1)
        return fileMenuItem?.submenu
    }

    private func getOpenMenuItem() -> NSMenuItem? {
        let mainMenu = NSApp.mainMenu
        let fileMenuItem = mainMenu?.item(at: 1)
        let openMenuItem = fileMenuItem?.submenu?.item(at: 0)
        return openMenuItem
    }

    private func ableToCalcFiles() -> Bool {
        return !isCalculating()
    }

    private func isCalculating() -> Bool {
        return (state == .CALC_ING || state == .WAITING_EXIT)
    }

    private func updateUpperCaseState() {
        upperCaseState = (upperCaseButton.state == .on)
    }

    private func updateMainTextView(_ keepScrollPosition: Bool) {
        // _mainMtx->lock();

        // Apply style to all text.
        mainText?.beginEditing()

        mainText?.addAttribute(
            .font,
            value: mainFont as Any,
            range: NSRange(location: 0, length: mainText!.length))

        mainText?.addAttribute(
            .foregroundColor,
            value: NSColor.textColor,
            range: NSRange(location: 0, length: mainText!.length))

        // word wrap
        // var paraStyle = NSParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        // paraStyle.lineBreakMode = .byCharWrapping
        // mainText?.addAttribute(
        //     .paragraphStyle,
        //     value: paraStyle,
        //     range: NSRange(location: 0, length: mainText!.length))

        mainText?.endEditing()

        mainTextView.textStorage?.setAttributedString(mainText!)

        if (MacSwiftUtils.GetSystemMajorVersion() == 14) {
            // Sonoma insets fix.
            let mainTextSize = mainText!.size()
            let mainScrollViewSize = mainScrollView.frame.size
            var scrollViewContentInsets = mainScrollView.contentInsets
            if mainTextSize.width > mainScrollViewSize.width {
                scrollViewContentInsets.left = 5.0
                scrollViewContentInsets.right = 5.0
            } else {
                scrollViewContentInsets.left = 0
                scrollViewContentInsets.right = 0
            }
            mainScrollView.contentInsets = scrollViewContentInsets
        }

        // _mainMtx->unlock();

        if !keepScrollPosition {
            // Scroll to end.
            mainTextView.scrollRangeToVisible(NSRange(location: mainTextView.string.count,
                                                      length: 0))
        }
    }

    private func updateMainTextView() {
        self.updateMainTextView(false)
    }

    private func refreshResultText() {
        self.updateUpperCaseState()

        // _mainMtx->lock();
        mainText = NSMutableAttributedString()

        // ResultList::iterator itr = _thrdData->resultList.begin();
        // for(; itr != _thrdData->resultList.end(); ++itr)
        // {
        //     UIBridgeMacUI::AppendResultToNSMutableAttributedString(*itr, _upperCaseState, _mainText);
        // }
        // _mainMtx->unlock();

        self.updateMainTextView(true)
    }

    func textView(
        _ aTextView: NSTextView,
        clickedOnLink link: Any,
        at charIndex: Int) -> Bool {
        if aTextView == mainTextView {
            selectedLink = link as! String

            var nsptMouseLoc: NSPoint
            nsptMouseLoc = NSEvent.mouseLocation
            let nsrtMouseInView = view.window?.convertFromScreen(NSRect(x: nsptMouseLoc.x, y: nsptMouseLoc.y, width: 0, height: 0))
            let nsptMouseInView = nsrtMouseInView?.origin as? NSPoint

            let nsmenuHash = NSMenu(title: "HashMenu")
            nsmenuHash.insertItem(
                withTitle: MacSwiftUtils.GetStringFromRes("MAINDLG_HYPEREDIT_MENU_COPY"),
                action: #selector(self.menuCopyHash),
                keyEquivalent: "",
                at: 0)
            nsmenuHash.insertItem(NSMenuItem.separator(), at: 1)
            nsmenuHash.insertItem(
                withTitle: MacSwiftUtils.GetStringFromRes("MAINDLG_HYPEREDIT_MENU_SERACHGOOGLE"),
                action: #selector(self.menuSearchGoogle),
                keyEquivalent: "",
                at: 2)
            nsmenuHash.insertItem(
                withTitle: MacSwiftUtils.GetStringFromRes("MAINDLG_HYPEREDIT_MENU_SERACHVIRUSTOTAL"),
                action: #selector(self.menuSearchVirusTotal),
                keyEquivalent: "",
                at: 3)

            nsmenuHash.popUp(positioning: nil, at: nsptMouseInView ?? NSPoint.zero, in: view)

            return true
        }

        return false
    }

    @objc func menuCopyHash() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(selectedLink, forType: .string)
    }

    @objc func menuSearchGoogle() {
        let nstrUrl = "https://www.google.com/search?q=\(selectedLink)&ie=utf-8&oe=utf-8"
        let url = URL(string: nstrUrl)!
        NSWorkspace.shared.open(url)
    }

    @objc func menuSearchVirusTotal() {
        let nstrUrl = "https://www.virustotal.com/#/search/\(selectedLink)"
        let url = URL(string: nstrUrl)!
        NSWorkspace.shared.open(url)
    }
}
