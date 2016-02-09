//
//  SSOAuthenticationManager.swift
//  HelloTodoWithSSO
//
//  Created by Anton Aleksandrov on 2/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import BMSCore

class SSOAuthenticationManager{
	
	private let logger = Logger.getLoggerForName("SSOAuthenticationManager")
	
	private let authenticationDelegate:SSOAuthenticationDelegate
	private let completionHandler:MfpCompletionHandler
	private let authenticationUrl:String
	private let authorizationUrl:String
	
	
	init(authenticationDelegate:SSOAuthenticationDelegate, completionHandler:MfpCompletionHandler, authenticationUrl:String, authorizationUrl:String ){
		self.authenticationDelegate = authenticationDelegate
		self.completionHandler = completionHandler
		self.authenticationUrl = authenticationUrl
		self.authorizationUrl = authorizationUrl
	}
	
	func startAuthentication(){
		logger.debug("startAuthentication");
		authenticationDelegate.onAuthenticationChallengeReceived(self)
	}
	
	func submitCredentials(credentials:[String:String]){
		logger.debug("submitCredentials :: " + credentials.description)
		
		let requestUrl:String = authenticationUrl + "?PolicyId=urn:ibm:security:authentication:asf:basicldapuser"
		let initAuthFlowRequest = Request(url:requestUrl, method: HttpMethod.POST)
		initAuthFlowRequest.headers = ["Content-Type":"application/json", "Accept":"application/json"];
		initAuthFlowRequest.sendWithCompletionHandler { (response, error) -> Void in
			if (error != nil){
				self.logger.error(error!.description)
				self.completionHandler(nil, error)
			} else {
				let responseText = response?.responseText
				let data = responseText?.dataUsingEncoding(NSUTF8StringEncoding)
				let dict = try? NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions())
				let stateId = dict!["state"] as! String
				self.loginWithStateId(stateId, credentials:credentials)
			}
		}
	}
	
	private func loginWithStateId(stateId:String, credentials:[String:String]){
		logger.debug("login :: " + stateId)
		let requestUrl:String = authenticationUrl + "?StateId=" + stateId
		let loginRequest = Request(url: requestUrl, method: HttpMethod.PUT)
		loginRequest.headers = ["Content-Type":"application/json", "Accept":"application/json"];
		let data = try? NSJSONSerialization.dataWithJSONObject(credentials, options: NSJSONWritingOptions())
		loginRequest.sendData(data!) { (response, error) -> Void in
			if (error != nil){
				self.logger.error(error!.description)
				self.completionHandler(nil, error)
			} else if (response?.statusCode == 204){
				self.authorize()
			} else {
				let error = NSError(domain: "com.ibm.bluemix.sso", code: 1, userInfo: [NSLocalizedDescriptionKey:"Failed to authenticate with supplied credentials"])
				self.logger.error(error.description)
				self.completionHandler(nil, error)
			}
		}
	}
	
	private func authorize(){
		logger.debug("authorize")
		let azRequest = Request(url: authorizationUrl, method: HttpMethod.GET)
		azRequest.sendWithCompletionHandler { (response, error) -> Void in
			if (error != nil && error?.userInfo["NSErrorFailingURLStringKey"]?.containsString("sso-callback-success") == true){
				self.logger.debug("Authorization+authentication success")
				self.completionHandler(nil,nil)
			} else if (error != nil){
				self.logger.error(error!.description)
				self.completionHandler(nil, error)
			} else {
				let error = NSError(domain: "com.ibm.bluemix.sso", code: 2, userInfo: ["NSLocalizedDescriptionKey":"Unexpected result from authorization endpoint/callback"])
				self.completionHandler(nil, error)
			}

		}
		
		
	}
}
