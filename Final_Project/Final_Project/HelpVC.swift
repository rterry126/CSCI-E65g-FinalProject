//
//  HelpVC.swift
//  Final_Project
//
//  Created by Robert Terry on 11/4/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
//Sources - Webview Code - https://developer.apple.com/documentation/webkit/wkwebview
//Sources - Webview - Local file access - https://stackoverflow.com/questions/49638653/load-local-web-files-resources-in-wkwebview


import UIKit
import WebKit  // WKWebView

class HelpVC: UIViewController, WKUIDelegate {
    
    let myURL = URL(string:"https://storage.googleapis.com/rterry126_helpfiles/help.html")
//    private static let myLocalURL = Bundle.main.url(forResource: "Help_file_backup", withExtension: "html")
    
    
    private lazy var webView: WKWebView = {
        let wv = WKWebView()
        return wv
    }()
    
    
    override func loadView() {
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        view = webView
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let myRequest = URLRequest(url: myURL!)
        webView.load(myRequest)
    }
}

/* Want fallback to local file OR local HTML string if network or website is unreachable.
 
 Two links below should help determine status of original request
 
 https://iosdevcenters.blogspot.com/2016/05/creating-simple-browser-with-wkwebview.html
 
 https://developer.apple.com/documentation/webkit/wknavigationdelegate
 
 */
