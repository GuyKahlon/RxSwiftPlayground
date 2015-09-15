//
//  ViewController.swift
//  RxSwiftPlayground
//
//  Created by Guy Kahlon on 9/4/15.
//  Copyright © 2015 GuyKahlon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class LoginViewController: UIViewController {
    
    @IBOutlet weak var usernameTextFiled: UITextField!
    @IBOutlet weak var passwordTextFiled: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let validUsernameObservable: Observable<Bool> = usernameTextFiled.rx_text
            .map({ (username: String) -> Bool in
                return username.isValidEmail()
            })
        
        validUsernameObservable
            .map { valid in valid ? UIColor.greenColor().CGColor : UIColor.redColor().CGColor }
            .subscribeNext ({ (textFieldBorderColor) -> Void in
           self.usernameTextFiled.layer.borderColor = textFieldBorderColor
        })
     
    
        let validPasswordObservable = passwordTextFiled.rx_text.map {$0.characters.count > 3 }
        
        validPasswordObservable
            .map { $0 ? UIColor.greenColor().CGColor : UIColor.redColor().CGColor }
            .subscribeNext ({ (textFieldBorderColor) -> Void in
                self.passwordTextFiled.layer.borderColor = textFieldBorderColor
            })
        
        
        let validFormObservable = combineLatest(validUsernameObservable, validPasswordObservable) { (isValidEmail: Bool, isValidPassword: Bool) -> Bool in
            return isValidEmail && isValidPassword
        }
        
        validFormObservable.bindTo(self.logInButton.rx_enabled)
        
        logInButton.rx_tap
            .doOn({ _ in
                self.logInButton.enabled = false
            })
            .flatMap { DummyLoginInService.login(self.usernameTextFiled.text!, password: self.passwordTextFiled.text!) }
            .subscribeNext({ (response) -> Void in
                self.logInButton.enabled = true
                if response{
                    self.performSegueWithIdentifier("loginSuccess", sender: self)
                } else {
                    let alertController = UIAlertController(title: "RxSwiftPlayground", message: "Wrong username or password, Please try again", preferredStyle: .Alert)
                    alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                    self.presentViewController(alertController, animated: true, completion: nil)
                }
            })
 
    }
    
    func loginObservable(){
        DummyLoginInService.login(usernameTextFiled.text!, password: passwordTextFiled.text!)
    }
}

extension String {
    
    func isValidEmail() -> Bool {
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(self)
    }
}