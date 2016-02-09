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
		becomeFirstResponder()
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
					self.dispatchOnMainQueueAfterDelay(0) {
						self.tableView.reloadData()
					}
				}
			}
		})
	}
	
	@IBAction
	func onAddNewItemClicked(){
		logger.debug("onAddNewItemClicked")
		let alert = UIAlertController(title: "Add new todo", message: "Enter todo text", preferredStyle: UIAlertControllerStyle.Alert)
		alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
			textField.placeholder = "Todo text"
			textField.secureTextEntry = false
			textField.text = ""
		})

		alert.addAction(UIAlertAction(title: "Add", style: UIAlertActionStyle.Default, handler:{ (action:UIAlertAction) -> Void in
			let itemText = alert.textFields![0].text! as String
			let todoItem = TodoItem(id: 0, text: itemText, isDone: false)
			SwiftSpinner.show("Loading items...", animated: true)
			TodoFacade.addNewItem(todoItem, completionHandler: {(error:NSError?) in
				if let err = error{
					SwiftSpinner.hide(){
						self.showError(err.localizedDescription)
					}
				} else {
					self.loadItems()
				}
			})
		}))
			
		alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler:{ (action:UIAlertAction) -> Void in
		}))

		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	// onEditItemClicked
	func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
		logger.debug("onEditItemClicked " + indexPath.row.description)
		tableView.deselectRowAtIndexPath(indexPath, animated: true)
		let clickedTodoItem = todoItems[indexPath.row]
		
		let alert = UIAlertController(title: "Edit todo item", message: "Enter todo text", preferredStyle: UIAlertControllerStyle.Alert)
		alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
			textField.placeholder = "Todo text"
			textField.secureTextEntry = false
			textField.text = clickedTodoItem.text
		})
		
		alert.addAction(UIAlertAction(title: "Save", style: UIAlertActionStyle.Default, handler:{ (action:UIAlertAction) -> Void in
			let itemText = alert.textFields![0].text! as String
			let todoItem = TodoItem(id: clickedTodoItem.id, text: itemText, isDone: clickedTodoItem.isDone)
			SwiftSpinner.show("Loading items...", animated: true)
			TodoFacade.updateItem(todoItem, completionHandler: {(error:NSError?) in
				if let err = error{
					SwiftSpinner.hide(){
						self.showError(err.localizedDescription)
					}
				} else {
					self.loadItems()
				}
			})
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler:{ (action:UIAlertAction) -> Void in
		}))
		
		self.presentViewController(alert, animated: true, completion: nil)
	}
	
	@IBAction
	func onTodoItemLongPressed(sender:UILongPressGestureRecognizer){
		if (sender.state == UIGestureRecognizerState.Began){
			let todoCell = sender.view as! TodoCell
			onDeleteClicked(rowIndex: todoCell.rowIndex)
		}
		
	}
	
	func onDeleteClicked(rowIndex rowIndex:NSInteger){
		print("onDeleteClicked :: " + rowIndex.description)
		let clickedTodoItem = todoItems[rowIndex]
		
		let alert = UIAlertController(title: "Delete todo item", message: "Would you like to delete this todo?", preferredStyle: UIAlertControllerStyle.Alert)

		alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler:{ (action:UIAlertAction) -> Void in
			SwiftSpinner.show("Loading items...", animated: true)
			TodoFacade.deleteItem(clickedTodoItem.id, completionHandler: {(error:NSError?) in
				if let err = error{
					SwiftSpinner.hide(){
						self.showError(err.localizedDescription)
					}
				} else {
					self.loadItems()
				}
			})
		}))
		
		alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler:{ (action:UIAlertAction) -> Void in
		}))
		self.presentViewController(alert, animated: true, completion: nil)

		
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
			textField.placeholder = "username"
			textField.secureTextEntry = false
//			textField.text = "demo"
		})
		alert.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
			textField.placeholder = "password"
			textField.secureTextEntry = true
//			textField.text = "demo"
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
		dispatchOnMainQueueAfterDelay(0) {
			SwiftSpinner.show(errText, animated: false)
		}
		
		dispatchOnMainQueueAfterDelay(3) {
			SwiftSpinner.hide()
		}
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
		let longPressGestureRecognizer = UILongPressGestureRecognizer(target: self, action: Selector("onTodoItemLongPressed:"));
		cell.addGestureRecognizer(longPressGestureRecognizer)
		
		return cell
	}
	
	override func canBecomeFirstResponder() -> Bool {
		return true
	}
	
	override func motionEnded(motion: UIEventSubtype, withEvent event: UIEvent?) {
		logger.debug("cleaning authorization data")
		BMSClient.sharedInstance.sharedAuthorizationManager.clearAuthorizationData()
		showError("Authorization data cleared")
	}
	
}

