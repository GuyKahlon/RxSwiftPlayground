# RxSwiftPlayground

There’s been a lot of buzz about Reactive / Functional / Functional Reactive programing (FRP) lately. 
You may have heard about it from another developer or seen several frameworks for iOS such as: ReactiveCocoa, ReactKit and RxSwift\RxCocoa  (a part of [Reactive-Extensions](https://github.com/Reactive-Extensions) ).


As an iOS developer, a vast majority of the code we write is in reaction to some event: a button tap, select text field, a received network message, observe some events and so on.
All these events are encoded in different ways: as actions, delegates, KVO, callbacks and others. Wouldn’t it be better if there was one consistent system that handles all the call and response code? Rx is such a system.

**This tutorial inspired by the great tutorial of ReactiveCocoa introduction 
by Colin Eberhardt at http://www.raywenderlich.com/.**

RxSwiftPlayground is a very simple app that presents a login screen to the user. 
The user enters their credentials, such as their email and password, to login.
In order to upgrade the user experience, we are going to indicate to the user when the email and the password are in an invalid format* and disable the login button until both the username and password are in the valid format.

**This tutorial uses Xcode 7.0 GM seed / Swift 2.0, and requires basic knowledge of Swift.**

Please download the RxSwift branch.

Now let’s take a look at the code in the start project. The main screen is the Login which looks something like this.

<img src="https://github.com/GuyKahlon/RxSwiftPlayground/blob/RxSwift/Screenshots/Login%20Start%20Project.png" width="250" height="444.66"> 

Open LoginViewController.swift file which represents the login screen, you will see three IBOutlets that represent the UI elements on the view:

* usernameTextFiled.
* passwordTextFiled. 
* logInButton. 

The traditional way to achieve our goal is by using delegate and target action design patterns, but we will show you how to achieve this result using RxSwift. 

RxCocoa provides a standard interface for handling sequences of events that occur within your application. 
In RxSwift\RxCocoa terminology these sequences are called **Sequence** or **Observable**.
We will receive inputs from the user, but instead of using UITextFieldDelegate, we will use Rx.
A great way to intuitively understand Rx, is to imagine that all our information/data is a sequence of events.
There are three types of events that are emitted from **Observable** for its **Subscription**: 
**Next**, **Completed** and **Error**.

**Adding RxSwift/RxCocoa Framworks via Cocoapods**

This Project already contains RxSwift\Rx Coca frameworks via cocoapods for more details how to use cocoapods please take a look at [cocoapods site] (https://guides.cocoapods.org/using/getting-started.html).

# Play with Rx
Let’s see an example: the user input text that came from the UITextField is a **Sequence\Observable** of Strings.
add the following code to your viewDidLoad function:

```swift
usernameTextFiled.rx_text.subscribeNext { (text: String) -> Void in
            print(text)
        }
```

Now build and run.
You we will see, all the text inputs printed on the console, you can see that each time you change the text, the closure is executed and prints the current text.

An **Observable** may send any number of **Next** events before it is terminated with a **Completed** or **Error** events. Note that after a **Completed** or **Error** event is sent the **Observable** will not send any more **Next** events.

The RxCocoa framework uses extension to add **Observable** to many of the standard UIKit controls, so you can add **Subscription** to their events, here we used the **rx_text** computed property on the UITextField.
Rx has tons of operators you can use to manipulate sequence of events. for example, let’s say we want to validate the username, we can use the filter operator on the sequence, like following:

```swift
usernameTextFiled.rx_text.filter { (text: String) -> Bool in
            return text.isValidEmail()
        }
```

For each text string that is sent by the **Observable** the block on filter is executed.
Because each operator on Rx also returns an **Observable** we can create an **Observable** of valid usernames and **Subscribe** to this **Observable**. 

```swift
 let validUserNameSubscription = usernameTextFiled.rx_text.filter { (text: String) -> Bool in
            return text.isValidEmail()
        }
        
        validUserNameSubscription.subscribeNext { (validUsername: String) -> Void in
            print(validUsername)
        }
```

Now username passed on to subscibeNext if and only if filter will return true for it.  

Build and run, then type some text into usernameTextField, you should find that it would only start printing when the text is valid according to the regular expression we provided by extension of String.

Let׳s see another example: this time we will define a valid password as one that has more than 3 characters. For that we will use the map operator. One would ask why not use filter operator again and the reason is filter filters out ‘false’ conditions and we want to have both the ‘valid’ and ‘invalid’ events so we can handle both. 
Map oprator transforms one value into another, as you can see below:

```swift
let validLengthPasswordObservable = passwordTextFiled.rx_text.map { text in
            return text.characters.count
        }
```
Now we can **Subscribe** to this **Observable**:

```swift
validLengthPasswordObservable.subscribeNext { (length) -> Void in
            print("Password charactersl count = \(length)")
        }
```

Build and run, You can see that each time you change the text on the password text field, the closure is executed and prints the number of characters.

# Let's start RxSwiftPlayground
Now we are more familiar with Rx, so let’s start to create our app.
Our first goal is to indicate to the user when his input is in valid format, so we will change the text field border color from green if the input is valid and red if it isn’t.

On the first step we will transfer any String value to Bool that present whether the input is valid or not, with the same way we did before, And then transfer valid input to green color and invalid to red, and then set the color to the UITextField border color.

```swift
let validUsernameObservable: Observable<Bool> = usernameTextFiled.rx_text
            .map({ (username: String) -> Bool in
                return username.isValidEmail()
            })
        
validUsernameObservable.map { valid in valid ? UIColor.greenColor().CGColor : UIColor.redColor().CGColor }
                       .subscribeNext ({ (textFieldBorderColor) -> Void in
                          self.usernameTextFiled.layer.borderColor = textFieldBorderColor
                        })
```

Diagram of the observable data:


<img src="https://github.com/GuyKahlon/RxSwiftPlayground/blob/FinalProject/Screenshots/ValidUsernameDiagram.png"> 


Note: Actually we composite our observables. Think of the possibilities :)  

Now we’ll do something similar on the password text field but this time we will use shorter syntax:

```swift
let validPasswordObservable = passwordTextFiled.rx_text.map {$0.characters.count > 3 }
validPasswordObservable.map { $0 ? UIColor.greenColor().CGColor : UIColor.redColor().CGColor }
                       .subscribeNext ({ (textFieldBorderColor) -> Void in
                           self.passwordTextFiled.layer.borderColor = textFieldBorderColor
                        })
```

So, now we have two **Observables**, one for valid user name and the other for valid password. 
In order to achieve our main goal which is to change the state of the login button from disable to enable and vice versa,  depending on valid username and password, we want to combine our two observables.

**Combine Observable**

combineLatest operator - Takes several source **Observables** and a closure as parameters, returns an **Observable** which emits the latest items of each source **Observable**, processed through the closure. Once any of the **observables** emits an event, combine latest emits the latest of the all the observablesble emit.


<img src="https://github.com/GuyKahlon/RxSwiftPlayground/blob/FinalProject/Screenshots/combinelatest.png">

Add this code to the end of viewDidLoad:

```swift
let validFormObservable = combineLatest(validUsernameObservable, validPasswordObservable) { (isValidEmail: Bool, isValidPassword: Bool) -> Bool in
  return isValidEmail && isValidPassword
}
        
validFormObservable.subscribeNext { (validForm) -> Void in
  self.logInButton.enabled = validForm
}
```

The above code uses the combineLatest operator to combine the latest values emitted by validUsernameObservable and validPasswordObservable into validFormObservable, each time either of two source emits a new value, the closure executed, and return if the form is valid, the validFormObservable change the state of the login button depending on the combine result.
If you build and run, check the login button. it’s should be enabled only if the both username and password have valid format.

Here we can use something called bindings, Rx can help you to connect between data and the UI.

Replace your code with:

```swift
validFormObservable.bindTo(self.logInButton.rx_enabled)
```

You’ve probably noticed that the Bool Observable that indicates username and password validity has more than one subscriber.
Observable can have multiple subscribers.

# Reactive Login

We’ve seen how RxCocoa framework adds properties to the standard UIKit controls. So far we’ve used **rx_text** which emits events when the text changes. In order to handle the button we will subscribe to UIButton’s **rx_tap** property (you can guess it emits events on tap).

```swift
logInButton.rx_tap.subscribeNext { _ -> Void in
            print("button clicked")
        }
```
The above code subscribes to **rx_tap** and prints to console each time a tap occurs.
Our next step is sending the user credentials to the server and complete the login process.

Our server API takes a username, password and completion block as parameters. The completion block is run either if login is successful or not. 

```swift
class func login(email: String, password: String, completion: DummyCompletionBlock){
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let success = email == "email@test.com" && password == "1234"
            completion(success);
        }
    }
```

You can use this interface directly within the subscribeNext closure that currently logs “button clicked”, but there’s a better, more RX-Style way of handling this, and it would be creating our own **Observable** (until now we only used RX existing observables e.g. rx_tap, rx_text).

**Create an Observable.**

There are many ways to create an **Observable**, we will use the **create** method.
Go to DummyLoginInService.swift and add the following code:

```swift
class func login(email: String, password: String) -> Observable<DummyResponse>{
  return create { observer in
    self.login(email, password: password, completion: { (success: DummyResponse) -> Void in
        observer.on(.Next(success))
        observer.on(.Completed)
    })
            
    return AnonymousDisposable {
    }
  }
}
```

The above method creates an **Observable** of DummyResponse type that signs in with the current email and password. 
The code within this block is executed only on subscription to it (only once per subscriber). 
This Observable sends a *Next* event that indicates whether login was successful, followed by a ‘completed’ event.
As you can see, it’s straightforward to warp an asynchronous API in **Observable**.
Now let's make use of this new Observable. 

replace your code with the following code:

```swift
logInButton.rx_tap.subscribeNext({ (response) -> Void in
  let username = self.usernameTextFiled.text!
  let password = self.passwordTextFiled.text!
  DummyLoginInService.login(username, password: password).subscribeNext({ response -> Void in
                      if response{
                        self.performSegueWithIdentifier("loginSuccess", sender: self)
                      } else {
                        let alertController = UIAlertController(title: "RxSwiftPlayground", message: "Wrong username or password, Please try again", preferredStyle: .Alert)
                        alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                        self.presentViewController(alertController, animated: true, completion: nil)
                      }
                    })
                  })
```

The above code uses the new **Observable** to login to the server.

Lets build and run, then try to enter valid username and password:

**email:** email@test.com 

**password:** 1234

😄

Maybe you've noticed that we call an **Observable** inside another **Observable’s** block, this incident is very common and RX offers an operator just for that.

**flatMap**

Transforms the items emitted by an **Observable** into **Observables**, then flatten the emissions from those into a single Observable.

<img src="https://github.com/GuyKahlon/RxSwiftPlayground/blob/FinalProject/Screenshots/flatmap.png"> 

Update your code with the following code:

```swift
logInButton.rx_tap.flatMap { DummyLoginInService.login(self.usernameTextFiled.text!, password: self.passwordTextFiled.text!) }
                  .subscribeNext({ (response) -> Void in
                    if response{
                      self.performSegueWithIdentifier("loginSuccess", sender: self)
                    } else {
                      let alertController = UIAlertController(title: "RxSwiftPlayground", message: "Wrong username or password, Please try again", preferredStyle: .Alert)
                      alertController.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
                      self.presentViewController(alertController, animated: true, completion: nil)
                    }
                  })
```

😄

There is one small user experience issue with the current application behaviour. While the login service validates the supplied credentials, it should disable the login button, this prevents the user from repeating the same login. But how should you add this logic? Changing the button’s enabled state isn’t a transformation, filter or any of the other concepts you’ve encountered so far. Instead, it’s what is known as a side-effect, or logic you want to execute within a **Observable** when a next event occurs, but it does not actually change the nature of the event itself.


**Adding side-effects**

**doOn**
Returns the exact same source **Observable** but executes some logic between receiving and returning it.
The gived closure obtain the event produced by the source observable.

<img src="https://github.com/GuyKahlon/RxSwiftPlayground/blob/FinalProject/Screenshots/do.png"> 

Update your code with the following code:

```swift
logInButton.rx_tap .doOn({ _ in
                     self.logInButton.enabled = false
                 }).flatMap { DummyLoginInService.login(self.usernameTextFiled.text!, password: self.passwordTextFiled.text!) }                  
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
```

You can see how the above adds a **doOn** step to the **Observable** immediately after button touch event creation.

The **doOn** closure above sets the button enabled property to false whilst the subscribeNext closure re-enables the button.
Build and run the application to confirm the login button is enabled and disabled as expected.


**Conclusions**

Hopefully this this tutorial has given you a good introduction to Functional Reactive Programing and basic knowledge how to start with RxSwift\RxCocoa, and that will help you to integrate this framework in your own application.
The main goal of Rx is to make your code cleaner and easier to understand, If you want to learn more about RxSwift, your first stop should be the [RxSwift README and the documentation on GitHub] (https://github.com/ReactiveX/RxSwift).

Good luck






