# Elf

![Swift](https://img.shields.io/badge/Swift-4.2-orange.svg)
![Cocoapods](https://img.shields.io/cocoapods/v/Elf.svg?style=flat)

Elf is a lightweight, pure-swift router for url handling. Make incoming url find the right handler. that's all Elf do.

![Elf Workflow](https://user-images.githubusercontent.com/35974/52165604-eb8ebf80-273d-11e9-8786-d344f605ff9b.png)

So what is a handler?

```swift
protocol Handler: class {
    func convert(params:Dictionary<String, String>, queryParams: Dictionary<String, String>)
    func handle()
}
```

if Elf find the right handler, it will first call `convert` method with `params` and `queryParams`. Within this method, these params can be converted to internal properties.

`handle()` will be called next. you can do all stuff here. like build a View Controller, push it or present it, or just make a switch on based on incoming params, or popup an alert window, etc. 

## Getting Started

First Let's create some handlers.

```swift
class ProfileHandler:Handler {
	var profileID: String?

	func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
		profileID = queryParams["id"]
	}
	
	func handle() {
		if let id = profileID {
			let vc = ProfileViewController()
			vc.profileID = id
			navigationController.push(vc)
		} else {
			// present error page
		}
	}
}

class UserHandler:Handler {
	var username: String?

	func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
		username = params["username"]
	}
	
	func handle() {
		if let id = username {
			let vc = UserFollowingViewController()
			navigationController.push(vc)
		}
	}
}
```

Then connect these handlers with appropriate url patterns.

```swift
let routeTable:[String:Handler] = [
	"app://profile": ProfileHandler(),
	"app://user/{username}/following": UserHandler(),
]

Elf.instance.registerRoutingTable(routeTable, notFoundHandler: {url in print("\(url) not found")})
```

Now let's handle urls!

```swift
// for test case
Elf.instance.handleURL(url: "app://profile?id=1024")
Elf.instance.handleURL(url: "app://user/limboy/following")

// usually it should be put in `AppDelegate's` method
func application(_ application: UIApplication,
                   open url: URL,
                   sourceApplication: String?,
                   annotation: Any) -> Bool {

	// ...
	Elf.instance.handleURL(url: url.absoluteString)
  }
```

if Elf found url's pattern in registered table, target handler will be triggered, else `notFoundHandler` will be called, in there a custom ViewController can be presented.

## Installation

### Podfile

```
pod 'Elf'
```

## Scenarios

### Push a viewcontroller

for example, tap an item in `ShopItemListViewController`, a `DetailViewController` should be pushed. it can be done like this:

```swift
let handler = DetailHandler()
handler.id = 1024
handler.handle()
```

`DetailHandler` is used as an entry/wrapper for `DetailViewController`, no matter it's came from url or called internally. both handled in a universal way.

So you don't have to open target View Controller, trying to find out what's needed to init. It's also flexible for `DetailViewController` if some properties should be changed as long as `DetailHandler` is not affected.

### Pinterest Style

When a Pinterest's waterfall list item is tapped, its model will be passed to detail page, so it won't be blank at first. but when opened by url, no model will be passed in. These two scenarios are all handled by `DetailHandler`.

```swift
class DetailHandler:Handler {
	var itemModel: ItemModel?
	var itemID: String?

	func convert(params: Dictionary<String, String>, queryParams: Dictionary<String, String>) {
		itemID = params["id"]
	}
	
	func handle() {
		// opened internal
		if let model = itemModel {
			let vc = DetailViewController()
			vc.model = itemModel
			navigationController.push(vc)
			return
		}

		// opened by url
		if let id = itemID {
			let vc = DetailViewController()
			vc.id = itemID
			navigationController.push(vc)
		}
	}
}
```

When the basic model is filled or user has made some change, previous View Controller should know, and update accordingly. just add a property like `onModelUpdate()`, when model is updated just call this function (if it not nil).

## Router Design
URL patterns are stored in a radix like tree, it will first split incoming url into sections, then match them one by one through the tree. 

## Tips
* to keep things simple, url pattern only match to `String`. `app://profile/{id}` will get `params["id"]` as `String` in `convert` method.
* a navigator can be injected into `Handler`'s child protocol, to make it easier to navigate.
* `SomeHandler` can be used to act as a config handler, when opened by url like `?debugcode=xxx`, debug mode is on.

## Contact

Follow and contact me on [Twitter](https://twitter.com/lzyy). If you find an issue, just open a ticket. Pull requests are warmly welcome as well.

## License

Elf is released under the MIT license. See LICENSE for details.



