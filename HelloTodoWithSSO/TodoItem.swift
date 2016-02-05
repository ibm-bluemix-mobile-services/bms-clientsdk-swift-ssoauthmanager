//
//  TodoItem.swift
//  HelloTodoWithSSO
//
//  Created by Anton Aleksandrov on 2/5/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import Foundation
import SwiftyJSON

class TodoItem{
	var id:NSInteger
	var text:String
	var isDone:Bool
	
	init(id:NSInteger, text:String, isDone:Bool){
		self.id = id
		self.text = text
		self.isDone = isDone
	}
	
	static func fromJson(json:JSON)-> TodoItem{
		let itemId = json["id"].intValue
		let itemText = json["text"].stringValue
		let itemIsDone = json["isDone"].boolValue
		return TodoItem(id:itemId, text:itemText, isDone:itemIsDone)
	}
	
	func toJson() -> JSON!{
		let dict = ["id":id, "text":text, "isDone":isDone]
		let json = JSON(dict)
		return json
	}
	

}
