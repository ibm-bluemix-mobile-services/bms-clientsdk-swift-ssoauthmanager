//
//  ViewController.swift
//  HelloTodoWithSSO
//
//  Created by Anton Aleksandrov on 2/1/16.
//  Copyright © 2016 IBM. All rights reserved.
//

import UIKit
import BMSCore
import SwiftSpinner
import SwiftyJSON

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, SSOAuthenticationDelegate {

	let logger = Logger.getLoggerForName("ViewController")
	
	@IBOutlet
	var tableView: UITableView!

	var todoItems:[TodoItem] = []

	override func viewDidLoad() {
		super.viewDidLoad()
		SSOAuthorizationManager.sharedInstace.initialize(self)
		
		let cellNib = UINib(nibName: "TodoCell", bundle: nil);
		tableView.registerNib(cellNib, forCellReuseIdentifier: "TodoCell")
		
		let refreshControl = UIRefreshControl()
		refreshControl.tintColor = UIColor.clearColor()
		refreshControl.addTarget(self, action: "handleRefresh:", forControlEvents: UIControlEvents.ValueChanged)
		self.tableView.addSubview(refreshControl)
	}
	
	override func viewDidAppear(animated: Bool) {
		loadItems()
	}
	
	func loadItems(){
		logger.debug("loadingItems")
		SwiftSpinner.show("Loading items...", animated: true)
		TodoFacade.getItems({ (items:[TodoItem]?, error:NSError?) in
			SwiftSpinner.hide(){
				if let err = error{
					self.showError(err.localizedDescription)
				} else {
					self.todoItems = items!;
					self.dispatchOnMainQueueAfterDelay(0, closure: {
						self.tableView.reloadData()
					})
				}
			}
		})
	}
	
	func onIsDoneClicked(rowIndex rowIndex:NSInteger){
		logger.debug("isDoneClicked :: " + rowIndex.description)
		SwiftSpinner.show("Loading items...", animated: true)
		let todoItem:TodoItem = todoItems[rowIndex]
		todoItem.isDone = !todoItem.isDone
		TodoFacade.updateItem(todoItem, completionHandler: { (error:NSError?) in
			if let err = error{
				SwiftSpinner.hide(){
					self.showError(err.localizedDescription)
				}
			} else {
				self.loadItems()
			}
		})
	}

	
	func onAuthenticationChallengeReceived(ssoAuthenticationManager: SSOAuthenticationManager) {
		logger.debug("onAuthenticationChallengeReceived")
		let alert = UIAlertController(title: "Login", message: "Please provide your credentials to login", preferredStyle: UIAlertControllerStyle.Alert)
		
		alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
			textField.placeholder = "Enter username:"
			textField.secureTextEntry = false
			textField.text = "demo"
		})
		alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
			textField.placeholder = "Enter password:"
			textField.secureTextEntry = true
			textField.text = "demo1"
		})
		
		alert.addAction(UIAlertAction(title: "Login", style: UIAlertActionStyle.Default, handler:{ (action:UIAlertAction) -> Void in
			let username = alert.textFields![0].text! as String
			let password = alert.textFields![1].text! as String
			SwiftSpinner.show("Loading items...", animated: true)
			ssoAuthenticationManager.submitCredentials(["username":username,"password":password])
		}))
		
		dispatchOnMainQueueAfterDelay(0){
			SwiftSpinner.hide()
			self.presentViewController(alert, animated: true, completion: nil)
		}

	}
	

	func handleRefresh(refreshControl:UIRefreshControl){
		self.logger.debug("handleRefresh")
		self.loadItems()
		refreshControl.endRefreshing()
	}
	
	func showError(errText:String){
		dispatchOnMainQueueAfterDelay(0){
			SwiftSpinner.show(errText, animated: false)
		}
		
		dispatchOnMainQueueAfterDelay(3, closure: {
			SwiftSpinner.hide()
		})
	}
	
	func dispatchOnMainQueueAfterDelay(delay:Double, closure:()->()) {
		dispatch_after(
			dispatch_time(
				DISPATCH_TIME_NOW,
				Int64(delay * Double(NSEC_PER_SEC))+100
			),
			dispatch_get_main_queue(), closure)
	}

	func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return self.todoItems.count;
	}
	
	func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
		var cell: TodoCell;
		cell = self.tableView.dequeueReusableCellWithIdentifier("TodoCell") as! TodoCell
		cell.viewController = self;
		let todoItem = todoItems[indexPath.row]
		cell.loadItem(text: todoItem.text, isDone: todoItem.isDone, rowIndex: indexPath.row)
		
		return cell
	}
	
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		logger.debug("selected " + indexPath.row.description)
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
	}

}

