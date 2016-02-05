//
//  SSOAuthorizationManager.swift
//  HelloTodoWithSSO
//
//  Created by Anton Aleksandrov on 2/4/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import BMSCore

protocol SSOAuthenticationDelegate{
	func onAuthenticationChallengeReceived(ssoAuthenticationManager:SSOAuthenticationManager)
}

class SSOAuthorizationManager: AuthorizationManager {
	
	static let sharedInstace = SSOAuthorizationManager()
	
	private static let WWW_AUTHENTICATE_HEADER_NAME = "Www-Authenticate";
	private static let SSO_AUTH_HEADER_SCOPE_BEARER = "Bearer scope=\"ssoAuthentication\"";
	private static let AUTHORIZATION_URL_HEADER_NAME = "X-Sso-Authorization-Url";
	private static let AUTHENTICATION_URL_HEADER_NAME = "X-Sso-Authentication-Url";

	private let logger = Logger.getLoggerForName("SSOAuthorizationManager")
	private var authDelegate:SSOAuthenticationDelegate? = nil
	private var authorizationUrl:String = ""
	private var authenticationUrl:String = ""
	
	func initialize(ssoAuthenticationDelegate: SSOAuthenticationDelegate){
		authDelegate = ssoAuthenticationDelegate
	}
	
	func isAuthorizationRequired(statusCode: Int, responseAuthorizationHeader: String) -> Bool{
		logger.error("NOT IMPLEMENTED")
		return false
	}
	
	func isAuthorizationRequired(httpResponse: Response?) -> Bool{
		let response = httpResponse!
		let responseCode = response.statusCode
		let responseHeaders = response.headers
		
		if (responseHeaders?.keys.contains(SSOAuthorizationManager.WWW_AUTHENTICATE_HEADER_NAME) == false ||
			responseHeaders?.keys.contains(SSOAuthorizationManager.AUTHENTICATION_URL_HEADER_NAME) == false ||
			responseHeaders?.keys.contains(SSOAuthorizationManager.AUTHORIZATION_URL_HEADER_NAME) == false){
				logger.debug("isAuthorizationRequired1 == false");
				return false
		}
		
		let authHeader = responseHeaders?[SSOAuthorizationManager.WWW_AUTHENTICATE_HEADER_NAME] as! String
		if (responseCode == 401 && authHeader == SSOAuthorizationManager.SSO_AUTH_HEADER_SCOPE_BEARER){
			authorizationUrl = responseHeaders?[SSOAuthorizationManager.AUTHORIZATION_URL_HEADER_NAME] as! String
			authenticationUrl = responseHeaders?[SSOAuthorizationManager.AUTHENTICATION_URL_HEADER_NAME] as! String
			logger.debug("isAuthorizationRequired == true");
			return true
		} else {
			logger.debug("isAuthorizationRequired2 == false");
			return false
		}
	}
	
	func obtainAuthorization(completionHandler: MfpCompletionHandler?){
		logger.debug("obtainAuthorization")
		
		if let authDelegateUnwrapped = authDelegate,
		   let completionHandlerUnwrapped = completionHandler {

			SSOAuthenticationManager(authenticationDelegate: authDelegateUnwrapped,
				completionHandler: completionHandlerUnwrapped,
				authenticationUrl: authenticationUrl,
				authorizationUrl: authorizationUrl).startAuthentication()
		}

	}
	
	func getCachedAuthorizationHeader() -> String?{
		return nil;
	}
	
	func clearAuthorizationData(){
		NSHTTPCookieStorage.sharedHTTPCookieStorage().removeCookiesSinceDate(NSDate(timeIntervalSince1970: 0))

	}

}
