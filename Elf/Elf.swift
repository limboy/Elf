//
//  Elf.swift
//  Elf
//
//  Created by limboy on 2019/2/2.
//  Copyright © 2019 limboy. All rights reserved.
//

import Foundation

// handler instance will be called when url matches pattern
protocol Handler: class {
    // use this function to convert params and queryParams into instance properties.
    // then you can use these properties in `handle` method
    func convert(params:Dictionary<String, String>, queryParams: Dictionary<String, String>)
    
    // since params and queryParams has been converted, no additional params needed here.
    // do all navigation related stuff here like init and push/present viewcontroller.
    // or you can just do some magic stuff like switch something on / off.
    func handle()
}

typealias NotFoundHandler = (_ url: String) -> Void

class Elf {
    
    static let instance = Elf()
    
    private init() {}
    
    // routing table is breaked down into `_routingItem`s
    // they are stored like an radix tree to improve efficiency.
    private class _RoutingItem: CustomStringConvertible {
        var isVariable: Bool = false
        var name: String = "/"
        var handler: Handler?
        var next: [_RoutingItem] = []
        var pattern: String?
        
        var description: String {
            return "{isVariable: \(isVariable), name: \(name), pattern: \(pattern ?? ""), handler: \(String(describing: handler)), next:\n\t\(next)}"
        }
    }
    
    private var _routingTable: _RoutingItem = _RoutingItem()
    
    // default not found handler if not provided
    private var _notFoundHandler: NotFoundHandler = { url in
        print("⚠️ \(url) doesn't match any pattern")
    }
    
    // if ur wondering what patterns are stored within, just call this method
    public func dump() {
        print(_routingTable)
    }
    
    // everytime this method is called, it reset to factory mode first to avoid multi thread problem.
    public func registerRoutingTable(_ table: Dictionary<String, Handler>, notFoundHandler:NotFoundHandler?) {
        flushTable()
        if let handler = notFoundHandler {
            _notFoundHandler = handler
        }
        
        for (pattern, handler) in table {
            var selectedItem = _routingTable
            let items = pattern.components(separatedBy: "://")
            if items.count > 1 {
                // handle it in a universal way
                // there should not be more than 2 items
                let url = items[0] + "/" + items[1]
                
                // insert url path components into next
                // the first is scheme
                let pathComponents = url.components(separatedBy: "/")
                
                for (index, pathComponent) in pathComponents.enumerated() {
                    var exists = false
                    let isLastPath = index == pathComponents.count - 1
                    
                    for item in selectedItem.next {
                        // so {test} and test won't conflict
                        if item.name == pathComponent && !(item.isVariable && !item.name.hasPrefix("{")) {
                            exists = true
                            selectedItem = item
                            
                            if isLastPath {
                                item.handler = handler
                                item.pattern = pattern
                            }
                            
                            break
                        }
                    }
                    
                    if !exists {
                        var isVariable = false
                        var name = pathComponent
                        
                        if pathComponent.hasPrefix("{") {
                            isVariable = true
                            name = name.replacingOccurrences(of: "{", with: "")
                            name = name.replacingOccurrences(of: "}", with: "")
                        }
                        
                        let item = _RoutingItem()
                        item.isVariable = isVariable
                        item.handler = isLastPath ? handler : nil
                        item.name = name
                        item.pattern = isLastPath ? pattern : nil
                        // make sure variable items are always below exact items
                        if isVariable {
                            selectedItem.next.append(item)
                        } else {
                            selectedItem.next.insert(item, at: 0)
                        }
                        selectedItem = item
                    }
                }
            }
        }
    }
    
    // there will only be most 1 pattern match this url.
    // if no matched pattern, `notFoundHandler` will be called.
    public func handleURL(url: String) {
        if let pathComponents = URL.init(string: url) {
            var path = [String]()
            if let scheme = pathComponents.scheme {
                path.append(scheme)
            }
            if let host = pathComponents.host {
                path.append(host)
            }
            path += pathComponents.pathComponents.filter({ (item) -> Bool in
                item != "/"
            })
            
            // pre fix
            var routingItems: [[_RoutingItem]] = Array.init(repeating: [], count: path.count)
            
            let initItem = _routingTable.next.first { (item) -> Bool in
                return item.name == path[0]
            }
            
            guard let firstItem = initItem else {
                _notFoundHandler(url)
                return
            }
            
            routingItems[0].append(firstItem)
            
            for (index, _) in routingItems.enumerated() {
                let items = routingItems[index]
                let isLast = index == routingItems.count - 1
                var exists = false
                
                // print(items)
                
                for item in items {
                    if item.name == path[index] {
                        exists = true
                        if !isLast {
                            routingItems[index+1] = item.next + routingItems[index+1]
                        }
                    } else if item.isVariable {
                        exists = true
                        if !isLast {
                            routingItems[index+1] += item.next
                        }
                    }
                    
                    if exists && isLast {
                        if let handler = item.handler {
                            let (params, queryParams) = parseParams(url: url, pattern: item.pattern!)
                            handler.convert(params: params, queryParams: queryParams)
                            handler.handle()
                        }
                        return
                    }
                }
            }
        }
        
        _notFoundHandler(url)
    }
    
    // all stored _routingItems will be gone!
    // like factory reset.
    func flushTable() {
        _routingTable = _RoutingItem()
    }
    
    func parseParams(url: String, pattern: String) -> (params: Dictionary<String, String> , queryParams: Dictionary<String, String>) {
        var params = [String:String]()
        var queryParams = [String:String]()
        
        let items = url.components(separatedBy: "?")
        
        // urlPath and patternPath's length should be equal
        let urlPath = items[0].split(separator: "/")
        let patternPath = pattern.split(separator: "/")
        
        for (index, item) in patternPath.enumerated() {
            if item.hasPrefix("{") {
                var name = item.replacingOccurrences(of: "{", with: "")
                name = name.replacingOccurrences(of: "}", with: "")
                params[name] = String(urlPath[index])
            }
        }
        
        if items.count > 1 {
            if let urlComponents = URLComponents.init(string: url) {
                if let queryItems = urlComponents.queryItems {
                    for item in queryItems {
                        queryParams[item.name] = item.value
                    }
                }
            }
        }
        
        return (params, queryParams)
    }
}

