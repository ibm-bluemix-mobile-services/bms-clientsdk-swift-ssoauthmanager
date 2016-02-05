//
//  TodoCell.swift
//  HelloTodoWithSSO
//
//  Created by Anton Aleksandrov on 2/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit

class TodoCell : UITableViewCell {
	@IBOutlet var itemText: UILabel!
	@IBOutlet var isDoneButton: UIButton!
	var rowIndex:NSInteger!;
	var viewController:ViewController!
	var isDone:Bool!
		
	func loadItem(text text:String, isDone:Bool, rowIndex:NSInteger){
		self.itemText.text = text;
		self.rowIndex = rowIndex;
		self.isDone = isDone
		updateIsDoneImage()
	}
	
	@IBAction
	func onIsDoneClicked(){
		viewController.onIsDoneClicked(rowIndex: rowIndex)
	}
	
	private func updateIsDoneImage(){
		if (self.isDone == true){
			self.isDoneButton.setImage(UIImage(named: "checkbox1.png"), forState: UIControlState.Normal)
		} else{
			self.isDoneButton.setImage(UIImage(named: "checkbox2.png"), forState: UIControlState.Normal)
		}

	}

}