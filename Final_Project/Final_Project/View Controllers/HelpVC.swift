//
//  HelpVC.swift
//  Final_Project
//
//  Created by Robert Terry on 11/4/18.
//  Copyright © 2018 Robert Terry. All rights reserved.
//
//Sources - Webview Code - https://developer.apple.com/documentation/webkit/wkwebview
//Sources - Webview - Local file access - https://stackoverflow.com/questions/49638653/load-local-web-files-resources-in-wkwebview
//Sources - Activity view - https://www.ioscreator.com/tutorials/activity-indicator-ios-tutorial-ios12
// http://www.thomashanning.com/uiactivityindicatorview/
// Sources - Code from class also used and modified for this.

import WebKit  // WKWebView

class HelpVC: UIViewController, WKUIDelegate, WKNavigationDelegate  {
    
    // Create the Activity Indicator
    let activityIndicator = UIActivityIndicatorView(style: .whiteLarge)
    
    let myURL = URL(string:"https://storage.googleapis.com/rterry126_helpfiles/help.html")
    
    private lazy var webView: WKWebView = {
        let wv = WKWebView()
        return wv
    }()
    
    
    override func loadView() {
        
        let webConfiguration = WKWebViewConfiguration()
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self // Needed to determine when page has loaded
        view = webView
        
        
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        activityIndicator.color = UIColor.gray
        
        view.addSubview(activityIndicator)
        
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutConstraint.Attribute.centerX, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerX, multiplier: 1, constant: 0)
        view.addConstraint(horizontalConstraint)
        
        let verticalConstraint = NSLayoutConstraint(item: activityIndicator, attribute: NSLayoutConstraint.Attribute.centerY, relatedBy: NSLayoutConstraint.Relation.equal, toItem: view, attribute: NSLayoutConstraint.Attribute.centerY, multiplier: 1, constant: 0)
        view.addConstraint(verticalConstraint)
        
        activityIndicator.startAnimating()  // Start animation as soon as view loads
        
        if let myURL = myURL {
            let myRequest = URLRequest(url: myURL)
            webView.load(myRequest)
        }
        else {
            print("Unable to retrieve help page.")
        }
    }
    
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        activityIndicator.stopAnimating()
    }
}

