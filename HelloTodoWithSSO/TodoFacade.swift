//
//  TodoFacade.swift
//  HelloTodoWithSSO
//
//  Created by Anton Aleksandrov on 2/5/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import BMSCore
import SwiftyJSON

class TodoFacade{
	private static let logger = Logger.getLoggerForName("TodoFacade")
	
	static func getItems(completionHandler:([TodoItem]?, error:NSError?) -> Void){
		logger.debug("getItems");

		let req = Request(url: "/api/items", method: HttpMethod.GET)
		
		req.sendWithCompletionHandler { (response, error) -> Void in
			if let err = error{
				logger.error(err.description)
				completionHandler(nil, error:err)
			} else {
				let json:JSON = JSON.parse(response!.responseText!)
				var todoItemArray:[TodoItem] = []
				for itemJson:JSON in json.array!{
					let todoItem:TodoItem = TodoItem.fromJson(itemJson)
					todoItemArray.append(todoItem)
				}
				completionHandler(todoItemArray, error:nil)
			}
		}
	}
	
	static func addNewItem(todoItem:TodoItem, completionHandler:(NSError?) -> Void){
		TodoFacade.logger.debug("addNewItem");
		let req = Request(url: "/api/items", method: HttpMethod.POST)
		req.headers = ["Content-Type":"application/json", "Accept":"application/json"];
		
		req.sendString(todoItem.toJson()!.rawString()!) { (response, error) -> Void in
			if let err = error {
				logger.error(err.description)
				completionHandler(err);
			} else {
				completionHandler(nil)
			}
		}
	}

	static func updateItem(todoItem:TodoItem, completionHandler:(NSError?) -> Void){
		TodoFacade.logger.debug("updateItem");

		let req = Request(url: "/api/items", method: HttpMethod.PUT)
		req.headers = ["Content-Type":"application/json", "Accept":"application/json"];
		
		req.sendString(todoItem.toJson()!.rawString()!) { (response, error) -> Void in
			if let err = error {
				logger.error(err.description)
				completionHandler(err);
			} else {
				completionHandler(nil)
			}
		}
	}

	
	
	static func deleteItem(itemId:NSInteger, completionHandler:(NSError?) -> Void){
		TodoFacade.logger.debug("deleteItem");
		let req = Request(url: "/api/items/" + itemId.description, method: HttpMethod.DELETE)
		req.headers = ["Content-Type":"application/json", "Accept":"application/json"];
		
		req.sendWithCompletionHandler() { (response, error) -> Void in
			if let err = error {
				logger.error(err.description)
				completionHandler(err);
			} else {
				completionHandler(nil)
			}
		}
	}

}